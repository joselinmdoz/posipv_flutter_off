import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_service.dart';
import '../../../core/utils/app_result.dart';
import '../domain/sale_models.dart';

class SaleService {
  SaleService(
    this._db, {
    required OfflineLicenseService licenseService,
    Uuid? uuid,
  })  : _licenseService = licenseService,
        _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final OfflineLicenseService _licenseService;
  final Uuid _uuid;

  Future<AppResult<CreateSaleResult>> createSale(CreateSaleInput input) async {
    await _licenseService.requireSalesAccess();
    if (input.items.isEmpty) {
      return const AppFailure<CreateSaleResult>(
        'La venta debe tener al menos un producto.',
      );
    }

    if (input.payments.isEmpty) {
      return const AppFailure<CreateSaleResult>(
        'La venta debe tener al menos un pago.',
      );
    }
    if (input.discountCents < 0) {
      return const AppFailure<CreateSaleResult>(
        'El descuento no puede ser negativo.',
      );
    }

    try {
      final CreateSaleResult result = await _db.transaction(() async {
        final String saleOrigin = input.saleOrigin.trim().toLowerCase();
        final bool isDirectSale = saleOrigin == 'direct';
        final String movementSource = isDirectSale ? 'direct_sale' : 'pos';
        final String movementRefType =
            isDirectSale ? 'sale_direct' : 'sale_pos';
        final String movementNotePrefix =
            isDirectSale ? 'Venta directa' : 'Venta POS';
        String? terminalCurrencyCode;
        String? saleTerminalId = input.terminalId?.trim();
        String? saleTerminalSessionId = input.terminalSessionId?.trim();
        if (saleTerminalId != null && saleTerminalId.isEmpty) {
          saleTerminalId = null;
        }
        if (saleTerminalSessionId != null && saleTerminalSessionId.isEmpty) {
          saleTerminalSessionId = null;
        }

        if (!isDirectSale) {
          if (saleTerminalId == null || saleTerminalSessionId == null) {
            throw const _SaleException(
              'Debe existir un TPV con turno abierto para vender en POS.',
            );
          }
          final PosTerminal? terminal = await (_db.select(_db.posTerminals)
                ..where((PosTerminals tbl) => tbl.id.equals(saleTerminalId!)))
              .getSingleOrNull();
          if (terminal == null || !terminal.isActive) {
            throw const _SaleException('El TPV seleccionado no es valido.');
          }
          await _assertDemoPosTerminalAllowed(terminal.id);
          terminalCurrencyCode = _normalizeCurrencyCode(terminal.currencyCode);
          if (terminal.warehouseId != input.warehouseId) {
            throw const _SaleException(
              'El TPV no corresponde al almacen seleccionado.',
            );
          }

          final PosSession? tpvSession = await (_db.select(_db.posSessions)
                ..where((PosSessions tbl) =>
                    tbl.id.equals(saleTerminalSessionId!) &
                    tbl.terminalId.equals(saleTerminalId!)))
              .getSingleOrNull();
          if (tpvSession == null || tpvSession.status != 'open') {
            throw const _SaleException(
              'No hay un turno abierto valido en este TPV.',
            );
          }
          if (tpvSession.userId != input.cashierId) {
            throw const _SaleException(
              'El turno abierto pertenece a otro usuario.',
            );
          }
        } else {
          saleTerminalId = null;
          saleTerminalSessionId = null;
        }

        final Warehouse? warehouse = await (_db.select(_db.warehouses)
              ..where((Warehouses tbl) => tbl.id.equals(input.warehouseId)))
            .getSingleOrNull();
        if (warehouse == null || !warehouse.isActive) {
          throw const _SaleException('El almacen seleccionado no es valido.');
        }

        final String? cleanCustomerId = input.customerId?.trim().isEmpty ?? true
            ? null
            : input.customerId!.trim();
        if (cleanCustomerId != null) {
          final Customer? customer = await (_db.select(_db.customers)
                ..where((Customers tbl) => tbl.id.equals(cleanCustomerId)))
              .getSingleOrNull();
          if (customer == null || !customer.isActive) {
            throw const _SaleException('El cliente seleccionado no es valido.');
          }
        }

        final DateTime now = DateTime.now();
        await _enforceDailySalesLimit(now);
        final String saleId = _uuid.v4();
        final String folio = _buildFolio(now);

        int subtotalCents = 0;
        int taxCents = 0;

        final List<_ProcessedLine> processed = <_ProcessedLine>[];
        for (final SaleItemInput item in input.items) {
          if (item.qty <= 0) {
            throw const _SaleException(
              'Todas las cantidades deben ser mayores que 0.',
            );
          }

          final Product? product = await (_db.select(_db.products)
                ..where((Products tbl) => tbl.id.equals(item.productId)))
              .getSingleOrNull();
          if (product == null || !product.isActive) {
            throw _SaleException('Producto invalido: ${item.productId}.');
          }
          if (!isDirectSale &&
              terminalCurrencyCode != null &&
              terminalCurrencyCode.isNotEmpty) {
            final String productCurrencyCode =
                _normalizeCurrencyCode(product.currencyCode);
            if (productCurrencyCode != terminalCurrencyCode) {
              throw _SaleException(
                'El producto ${product.name} esta en $productCurrencyCode y este TPV opera en $terminalCurrencyCode.',
              );
            }
          }

          final StockBalance? balance = await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(item.productId) &
                      tbl.warehouseId.equals(input.warehouseId),
                ))
              .getSingleOrNull();

          final double currentQty = balance?.qty ?? 0;
          final double nextQty = currentQty - item.qty;
          if (!input.allowNegativeStock && nextQty < 0) {
            throw _SaleException(
              'Stock insuficiente para ${product.name}. Disponible: $currentQty, solicitado: ${item.qty}.',
            );
          }

          final int lineSubtotal = (item.unitPriceCents * item.qty).round();
          final int lineTax = (lineSubtotal * item.taxRateBps / 10000).round();
          final int lineTotal = lineSubtotal + lineTax;

          subtotalCents += lineSubtotal;
          taxCents += lineTax;

          processed.add(
            _ProcessedLine(
              item: item,
              productName: product.name,
              currentQty: currentQty,
              nextQty: nextQty,
              lineSubtotalCents: lineSubtotal,
              lineTaxCents: lineTax,
              lineTotalCents: lineTotal,
            ),
          );
        }

        final int grossTotalCents = subtotalCents + taxCents;
        if (input.discountCents > grossTotalCents) {
          throw const _SaleException(
            'El descuento no puede superar el total de la venta.',
          );
        }
        final int totalCents = grossTotalCents - input.discountCents;
        final int totalPayments = input.payments.fold<int>(
          0,
          (int sum, PaymentInput payment) => sum + payment.amountCents,
        );
        if (totalPayments != totalCents) {
          throw _SaleException(
            'El total de pagos ($totalPayments) no coincide con el total de la venta ($totalCents).',
          );
        }

        await _db.into(_db.sales).insert(
              SalesCompanion.insert(
                id: saleId,
                folio: folio,
                warehouseId: input.warehouseId,
                cashierId: input.cashierId,
                customerId: Value(cleanCustomerId),
                terminalId: Value(saleTerminalId),
                terminalSessionId: Value(saleTerminalSessionId),
                subtotalCents: subtotalCents,
                taxCents: taxCents,
                totalCents: totalCents,
              ),
            );

        for (final _ProcessedLine line in processed) {
          final String saleItemId = _uuid.v4();
          await _db.into(_db.saleItems).insert(
                SaleItemsCompanion.insert(
                  id: saleItemId,
                  saleId: saleId,
                  productId: line.item.productId,
                  qty: line.item.qty,
                  unitPriceCents: line.item.unitPriceCents,
                  taxRateBps: line.item.taxRateBps,
                  lineSubtotalCents: line.lineSubtotalCents,
                  lineTaxCents: line.lineTaxCents,
                  lineTotalCents: line.lineTotalCents,
                ),
              );

          await _upsertStock(
            productId: line.item.productId,
            warehouseId: input.warehouseId,
            qty: line.nextQty,
            now: now,
          );

          await _db.into(_db.stockMovements).insert(
                StockMovementsCompanion.insert(
                  id: _uuid.v4(),
                  productId: line.item.productId,
                  warehouseId: input.warehouseId,
                  type: 'out',
                  qty: line.item.qty,
                  reasonCode: const Value('sale'),
                  movementSource: Value(movementSource),
                  refType: Value(movementRefType),
                  refId: Value(saleId),
                  note: Value('$movementNotePrefix $folio'),
                  createdBy: input.cashierId,
                ),
              );
        }

        for (final PaymentInput payment in input.payments) {
          await _db.into(_db.payments).insert(
                PaymentsCompanion.insert(
                  id: _uuid.v4(),
                  saleId: saleId,
                  method: payment.method,
                  amountCents: payment.amountCents,
                  sourceCurrencyCode: Value(payment.sourceCurrencyCode),
                  sourceAmountCents: Value(payment.sourceAmountCents),
                ),
              );
        }

        await _db.into(_db.auditLogs).insert(
              AuditLogsCompanion.insert(
                id: _uuid.v4(),
                userId: Value(input.cashierId),
                action: 'SALE_POSTED',
                entity: 'sale',
                entityId: saleId,
                payloadJson: jsonEncode(<String, Object>{
                  'folio': folio,
                  'subtotalCents': subtotalCents,
                  'taxCents': taxCents,
                  'discountCents': input.discountCents,
                  'totalCents': totalCents,
                  'items': processed.length,
                }),
              ),
            );

        return CreateSaleResult(
          saleId: saleId,
          folio: folio,
          totalCents: totalCents,
        );
      });

      return AppSuccess<CreateSaleResult>(result);
    } on _SaleException catch (e) {
      return AppFailure<CreateSaleResult>(e.message);
    } catch (e) {
      return AppFailure<CreateSaleResult>(
        'No se pudo registrar la venta: $e',
      );
    }
  }

  String _normalizeCurrencyCode(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  String _buildFolio(DateTime now) {
    final String y = now.year.toString().padLeft(4, '0');
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    return 'POS-$y$m$d-$hh$mm$ss';
  }

  Future<void> _enforceDailySalesLimit(DateTime now) async {
    final LicenseStatus status = await _licenseService.current();
    if (status.isFull) {
      return;
    }

    final DateTime dayStart = DateTime(now.year, now.month, now.day);
    final DateTime dayEnd = dayStart.add(const Duration(days: 1));
    final Expression<int> countExp = _db.sales.id.count();
    final TypedResult row = await (_db.selectOnly(_db.sales)
          ..addColumns(<Expression<Object>>[countExp])
          ..where(
            _db.sales.createdAt.isBiggerOrEqualValue(dayStart) &
                _db.sales.createdAt.isSmallerThanValue(dayEnd),
          ))
        .getSingle();
    final int countToday = row.read(countExp) ?? 0;
    if (countToday >= DemoLicenseLimits.maxSalesPerDay) {
      throw const _SaleException(
        'Modo demo: alcanzaste el limite de 5 ventas por dia.',
      );
    }
  }

  Future<void> _assertDemoPosTerminalAllowed(String terminalId) async {
    final LicenseStatus status = await _licenseService.current();
    if (status.isFull) {
      return;
    }

    final PosTerminal? firstTerminal = await (_db.select(_db.posTerminals)
          ..where(
            (PosTerminals tbl) =>
                tbl.isActive.equals(true) &
                tbl.id.isNotNull() &
                tbl.createdAt.isNotNull(),
          )
          ..orderBy(<OrderingTerm Function(PosTerminals)>[
            (PosTerminals tbl) => OrderingTerm.asc(tbl.createdAt),
            (PosTerminals tbl) => OrderingTerm.asc(tbl.name),
          ])
          ..limit(1))
        .getSingleOrNull();

    if (firstTerminal == null || firstTerminal.id == terminalId) {
      return;
    }
    throw const _SaleException(
      'Modo demo: las ventas POS solo estan disponibles en el primer TPV registrado.',
    );
  }

  Future<void> _upsertStock({
    required String productId,
    required String warehouseId,
    required double qty,
    required DateTime now,
  }) async {
    final StockBalance? existing = await (_db.select(_db.stockBalances)
          ..where(
            (StockBalances tbl) =>
                tbl.productId.equals(productId) &
                tbl.warehouseId.equals(warehouseId),
          ))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.stockBalances).insert(
            StockBalancesCompanion.insert(
              productId: productId,
              warehouseId: warehouseId,
              qty: Value(qty),
              updatedAt: Value(now),
            ),
          );
      return;
    }

    await (_db.update(_db.stockBalances)
          ..where(
            (StockBalances tbl) =>
                tbl.productId.equals(productId) &
                tbl.warehouseId.equals(warehouseId),
          ))
        .write(
      StockBalancesCompanion(
        qty: Value(qty),
        updatedAt: Value(now),
      ),
    );
  }
}

class _ProcessedLine {
  const _ProcessedLine({
    required this.item,
    required this.productName,
    required this.currentQty,
    required this.nextQty,
    required this.lineSubtotalCents,
    required this.lineTaxCents,
    required this.lineTotalCents,
  });

  final SaleItemInput item;
  final String productName;
  final double currentQty;
  final double nextQty;
  final int lineSubtotalCents;
  final int lineTaxCents;
  final int lineTotalCents;
}

class _SaleException implements Exception {
  const _SaleException(this.message);
  final String message;
}
