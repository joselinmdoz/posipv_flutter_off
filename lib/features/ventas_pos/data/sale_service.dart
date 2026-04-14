import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_service.dart';
import '../../../core/security/app_permissions.dart';
import '../../../core/utils/app_result.dart';
import '../domain/sale_models.dart';

class ArchivedSaleView {
  const ArchivedSaleView({
    required this.id,
    required this.folio,
    required this.createdAt,
    required this.archivedAt,
    required this.totalCents,
    required this.warehouseName,
    required this.cashierName,
    required this.channel,
    this.customerName,
  });

  final String id;
  final String folio;
  final DateTime createdAt;
  final DateTime archivedAt;
  final int totalCents;
  final String warehouseName;
  final String cashierName;
  final String channel;
  final String? customerName;
}

class SaleStockIntegrityRepairResult {
  const SaleStockIntegrityRepairResult({
    required this.postedSalesCount,
    required this.affectedSalesCount,
    required this.affectedLinesCount,
    required this.missingQtyTotal,
    required this.salesWithPurgeEvidence,
    required this.salesWithVoidedMovements,
    required this.movementsRebuilt,
    required this.stockAdjustments,
    required this.skippedForNegativeStock,
    required this.sampleFolios,
    required this.dryRun,
  });

  final int postedSalesCount;
  final int affectedSalesCount;
  final int affectedLinesCount;
  final double missingQtyTotal;
  final int salesWithPurgeEvidence;
  final int salesWithVoidedMovements;
  final int movementsRebuilt;
  final int stockAdjustments;
  final int skippedForNegativeStock;
  final List<String> sampleFolios;
  final bool dryRun;
}

class SaleStockIntegrityIssueLine {
  const SaleStockIntegrityIssueLine({
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.expectedQty,
    required this.coveredQty,
    required this.missingQty,
    required this.voidedQty,
  });

  final String productId;
  final String productName;
  final String productSku;
  final double expectedQty;
  final double coveredQty;
  final double missingQty;
  final double voidedQty;
}

class SaleStockIntegrityIssue {
  const SaleStockIntegrityIssue({
    required this.saleId,
    required this.folio,
    required this.createdAt,
    required this.warehouseId,
    required this.warehouseName,
    required this.cashierId,
    required this.terminalId,
    required this.hasPurgeEvidence,
    required this.hasVoidedMovements,
    required this.totalMissingQty,
    required this.lines,
  });

  final String saleId;
  final String folio;
  final DateTime createdAt;
  final String warehouseId;
  final String warehouseName;
  final String cashierId;
  final String terminalId;
  final bool hasPurgeEvidence;
  final bool hasVoidedMovements;
  final double totalMissingQty;
  final List<SaleStockIntegrityIssueLine> lines;
}

class SaleStockIntegrityRepairTarget {
  const SaleStockIntegrityRepairTarget({
    required this.saleId,
    required this.productId,
  });

  final String saleId;
  final String productId;
}

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

    final bool isConsignmentSale = input.isConsignmentSale ||
        input.payments.any((PaymentInput p) => _isConsignmentMethod(p.method));
    if (isConsignmentSale) {
      final bool canSellConsignment = await _userHasPermission(
        userId: input.cashierId,
        permissionKey: AppPermissionKeys.salesConsignment,
      );
      if (!canSellConsignment) {
        return const AppFailure<CreateSaleResult>(
          'No tienes permisos para registrar ventas en consignación.',
        );
      }
    }
    if (input.payments.isEmpty && !isConsignmentSale) {
      return const AppFailure<CreateSaleResult>(
        'La venta debe tener al menos un pago.',
      );
    }
    if (input.payments.any((PaymentInput p) => p.amountCents < 0)) {
      return const AppFailure<CreateSaleResult>(
        'Los montos de pago no pueden ser negativos.',
      );
    }
    if (isConsignmentSale && input.payments.isNotEmpty) {
      return const AppFailure<CreateSaleResult>(
        'La venta en consignacion se registra sin pagos iniciales.',
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
        final String movementSource = isConsignmentSale
            ? (isDirectSale ? 'direct_consignment' : 'pos_consignment')
            : (isDirectSale ? 'direct_sale' : 'pos');
        final String movementRefType = isConsignmentSale
            ? (isDirectSale
                ? 'consignment_sale_direct'
                : 'consignment_sale_pos')
            : (isDirectSale ? 'sale_direct' : 'sale_pos');
        final String movementReasonCode =
            isConsignmentSale ? 'consignment_sale' : 'sale';
        final String movementNotePrefix = isConsignmentSale
            ? (isDirectSale ? 'Consignacion directa' : 'Consignacion POS')
            : (isDirectSale ? 'Venta directa' : 'Venta POS');
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
            final bool cashierIsAdmin =
                await _userHasAdminRole(input.cashierId);
            if (!cashierIsAdmin) {
              throw const _SaleException(
                'El turno abierto pertenece a otro usuario.',
              );
            }
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
        if (isConsignmentSale && cleanCustomerId == null) {
          throw const _SaleException(
            'La venta en consignacion requiere un cliente seleccionado.',
          );
        }
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
          final List<_FifoAllocation> fifoAllocations =
              await _reserveFifoAllocations(
            productId: item.productId,
            warehouseId: input.warehouseId,
            qty: item.qty,
            fallbackUnitCostCents: product.costPriceCents,
          );
          final int lineCostCents = fifoAllocations.fold<int>(
            0,
            (int sum, _FifoAllocation row) => sum + row.lineCostCents,
          );
          final int unitCostCents = item.qty.abs() <= 0.000001
              ? product.costPriceCents
              : (lineCostCents / item.qty).round();
          final int lineTotal = lineSubtotal + lineTax;

          subtotalCents += lineSubtotal;
          taxCents += lineTax;

          processed.add(
            _ProcessedLine(
              item: item,
              productName: product.name,
              currentQty: currentQty,
              nextQty: nextQty,
              unitCostCents: unitCostCents,
              lineCostCents: lineCostCents,
              lineSubtotalCents: lineSubtotal,
              lineTaxCents: lineTax,
              lineTotalCents: lineTotal,
              allocations: fifoAllocations,
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
        if (!isConsignmentSale && totalPayments < totalCents) {
          throw _SaleException(
            'El total de pagos ($totalPayments) debe cubrir al menos el total de la venta ($totalCents).',
          );
        }
        if (isConsignmentSale && totalPayments != 0) {
          throw const _SaleException(
            'La venta en consignacion se registra sin pagos iniciales.',
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
                  unitCostCents: Value(line.unitCostCents),
                  taxRateBps: line.item.taxRateBps,
                  lineSubtotalCents: line.lineSubtotalCents,
                  lineTaxCents: line.lineTaxCents,
                  lineCostCents: Value(line.lineCostCents),
                  lineTotalCents: line.lineTotalCents,
                ),
              );
          await _insertSaleItemAllocations(
            saleId: saleId,
            saleItemId: saleItemId,
            productId: line.item.productId,
            warehouseId: input.warehouseId,
            allocations: line.allocations,
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
                  reasonCode: Value(movementReasonCode),
                  movementSource: Value(movementSource),
                  refType: Value(movementRefType),
                  refId: Value(saleId),
                  note: Value('$movementNotePrefix $folio'),
                  createdBy: input.cashierId,
                ),
              );
        }

        await _syncProductsCostFromActiveLots(
          productIds:
              processed.map((_ProcessedLine row) => row.item.productId).toSet(),
          now: now,
        );

        for (final PaymentInput payment in input.payments) {
          await _db.into(_db.payments).insert(
                PaymentsCompanion.insert(
                  id: _uuid.v4(),
                  saleId: saleId,
                  method: payment.method,
                  amountCents: payment.amountCents,
                  transactionId: Value(
                    _normalizeOptional(payment.transactionId),
                  ),
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

  Future<void> updateSale(UpdateSaleInput input) async {
    await _licenseService.requireWriteAccess();
    final String safeSaleId = input.saleId.trim();
    final String safeUserId = input.userId.trim();
    if (safeSaleId.isEmpty) {
      throw const _SaleException('Venta inválida.');
    }
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }
    if (input.items.isEmpty) {
      throw const _SaleException(
        'La venta debe tener al menos un producto.',
      );
    }
    if (input.payments.any((PaymentInput p) => p.amountCents < 0)) {
      throw const _SaleException(
        'Los montos de pago no pueden ser negativos.',
      );
    }

    final bool isConsignmentSale = input.isConsignmentSale ||
        input.payments.any((PaymentInput p) => _isConsignmentMethod(p.method));
    if (isConsignmentSale) {
      final bool canSellConsignment = await _userHasPermission(
        userId: safeUserId,
        permissionKey: AppPermissionKeys.salesConsignment,
      );
      if (!canSellConsignment) {
        throw const _SaleException(
          'No tienes permisos para registrar ventas en consignación.',
        );
      }
    }
    if (!isConsignmentSale && input.payments.isEmpty) {
      throw const _SaleException(
        'La venta debe tener al menos un pago.',
      );
    }
    if (isConsignmentSale && input.payments.isNotEmpty) {
      throw const _SaleException(
        'La venta en consignacion se registra sin pagos iniciales.',
      );
    }

    await _db.transaction(() async {
      final Sale? sale = await (_db.select(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .getSingleOrNull();
      if (sale == null) {
        throw const _SaleException('La venta no existe.');
      }
      final String status = sale.status.trim().toLowerCase();
      if (status != 'posted') {
        throw const _SaleException(
          'Solo se pueden editar ventas publicadas.',
        );
      }

      final String? cleanCustomerId = input.customerId == null
          ? sale.customerId
          : _normalizeOptional(input.customerId);
      if (isConsignmentSale && cleanCustomerId == null) {
        throw const _SaleException(
          'La venta en consignacion requiere un cliente seleccionado.',
        );
      }
      if (cleanCustomerId != null) {
        final Customer? customer = await (_db.select(_db.customers)
              ..where((Customers tbl) => tbl.id.equals(cleanCustomerId)))
            .getSingleOrNull();
        if (customer == null || !customer.isActive) {
          throw const _SaleException('El cliente seleccionado no es valido.');
        }
      }

      String? terminalCurrencyCode;
      final bool isDirectSale = (sale.terminalId ?? '').trim().isEmpty;
      if (!isDirectSale) {
        final PosTerminal? terminal = await (_db.select(_db.posTerminals)
              ..where((PosTerminals tbl) => tbl.id.equals(sale.terminalId!)))
            .getSingleOrNull();
        if (terminal == null) {
          throw const _SaleException('El TPV asociado no existe.');
        }
        terminalCurrencyCode = _normalizeCurrencyCode(terminal.currencyCode);
        if (terminal.warehouseId != sale.warehouseId) {
          throw const _SaleException(
            'La venta tiene un TPV que no corresponde a su almacén.',
          );
        }
      }

      final List<SaleItem> previousLines = await (_db.select(_db.saleItems)
            ..where((SaleItems tbl) => tbl.saleId.equals(safeSaleId)))
          .get();
      final Map<String, double> previousQtyByProduct = <String, double>{};
      for (final SaleItem line in previousLines) {
        previousQtyByProduct[line.productId] =
            (previousQtyByProduct[line.productId] ?? 0) + line.qty;
      }
      await _releaseSaleAllocations(
        saleId: safeSaleId,
        markVoided: false,
      );

      final List<_SaleEditProcessedLine> processedLines =
          <_SaleEditProcessedLine>[];
      final Map<String, double> nextQtyByProduct = <String, double>{};
      int subtotalCents = 0;
      int taxCents = 0;
      for (final SaleItemInput item in input.items) {
        if (item.qty <= 0) {
          throw const _SaleException(
            'Todas las cantidades deben ser mayores que 0.',
          );
        }
        if (item.unitPriceCents < 0) {
          throw const _SaleException(
            'El precio unitario no puede ser negativo.',
          );
        }

        final Product? product = await (_db.select(_db.products)
              ..where((Products tbl) => tbl.id.equals(item.productId)))
            .getSingleOrNull();
        if (product == null) {
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

        final int lineSubtotal = (item.unitPriceCents * item.qty).round();
        final int lineTax = (lineSubtotal * item.taxRateBps / 10000).round();
        final List<_FifoAllocation> fifoAllocations =
            await _reserveFifoAllocations(
          productId: item.productId,
          warehouseId: sale.warehouseId,
          qty: item.qty,
          fallbackUnitCostCents: product.costPriceCents,
        );
        final int lineCostCents = fifoAllocations.fold<int>(
          0,
          (int sum, _FifoAllocation row) => sum + row.lineCostCents,
        );
        final int unitCostCents = item.qty.abs() <= 0.000001
            ? product.costPriceCents
            : (lineCostCents / item.qty).round();
        final int lineTotal = lineSubtotal + lineTax;
        subtotalCents += lineSubtotal;
        taxCents += lineTax;
        nextQtyByProduct[item.productId] =
            (nextQtyByProduct[item.productId] ?? 0) + item.qty;
        processedLines.add(
          _SaleEditProcessedLine(
            item: item,
            unitCostCents: unitCostCents,
            lineCostCents: lineCostCents,
            lineSubtotalCents: lineSubtotal,
            lineTaxCents: lineTax,
            lineTotalCents: lineTotal,
            allocations: fifoAllocations,
          ),
        );
      }

      final int existingDiscountCents =
          ((sale.subtotalCents + sale.taxCents - sale.totalCents)
                  .clamp(0, 1 << 30) as num)
              .toInt();
      final int grossTotalCents = subtotalCents + taxCents;
      if (existingDiscountCents > grossTotalCents) {
        throw const _SaleException(
          'El descuento existente supera el nuevo total bruto. Ajusta la venta.',
        );
      }
      final int totalCents = grossTotalCents - existingDiscountCents;
      final int totalPayments = input.payments.fold<int>(
        0,
        (int sum, PaymentInput payment) => sum + payment.amountCents,
      );
      if (!isConsignmentSale && totalPayments < totalCents) {
        throw _SaleException(
          'El total de pagos ($totalPayments) debe cubrir al menos el total de la venta ($totalCents).',
        );
      }
      if (isConsignmentSale && totalPayments != 0) {
        throw const _SaleException(
          'La venta en consignacion se registra sin pagos iniciales.',
        );
      }

      final Set<String> stockProductIds = <String>{
        ...previousQtyByProduct.keys,
        ...nextQtyByProduct.keys,
      };
      final DateTime now = DateTime.now();
      for (final String productId in stockProductIds) {
        final double oldQtyInSale = previousQtyByProduct[productId] ?? 0;
        final double nextQtyInSale = nextQtyByProduct[productId] ?? 0;
        final double delta = oldQtyInSale - nextQtyInSale;
        if (delta.abs() <= 0.000001) {
          continue;
        }
        final StockBalance? balance = await (_db.select(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(productId) &
                    tbl.warehouseId.equals(sale.warehouseId),
              ))
            .getSingleOrNull();
        final double currentStock = balance?.qty ?? 0;
        final double nextStock = currentStock + delta;
        if (!input.allowNegativeStock && nextStock < 0) {
          throw _SaleException(
            'Stock insuficiente para actualizar la venta. Producto: $productId.',
          );
        }
        await _upsertStock(
          productId: productId,
          warehouseId: sale.warehouseId,
          qty: nextStock,
          now: now,
        );
      }

      final String movementSource = isConsignmentSale
          ? (isDirectSale ? 'direct_consignment' : 'pos_consignment')
          : (isDirectSale ? 'direct_sale' : 'pos');
      final String movementRefType = isConsignmentSale
          ? (isDirectSale ? 'consignment_sale_direct' : 'consignment_sale_pos')
          : (isDirectSale ? 'sale_direct' : 'sale_pos');
      final String movementReasonCode =
          isConsignmentSale ? 'consignment_sale' : 'sale';
      final String movementNotePrefix = isConsignmentSale
          ? (isDirectSale ? 'Consignacion directa' : 'Consignacion POS')
          : (isDirectSale ? 'Venta directa' : 'Venta POS');

      await _db.customStatement(
        '''
        DELETE FROM stock_movements
        WHERE ref_id = ?
          AND LOWER(COALESCE(ref_type, '')) IN (
            'sale',
            'sale_pos',
            'sale_direct',
            'consignment_sale',
            'consignment_sale_pos',
            'consignment_sale_direct'
          )
        ''',
        <Object?>[safeSaleId],
      );

      await (_db.delete(_db.saleItems)
            ..where((SaleItems tbl) => tbl.saleId.equals(safeSaleId)))
          .go();
      await (_db.delete(_db.payments)
            ..where((Payments tbl) => tbl.saleId.equals(safeSaleId)))
          .go();

      for (final _SaleEditProcessedLine line in processedLines) {
        final String saleItemId = _uuid.v4();
        await _db.into(_db.saleItems).insert(
              SaleItemsCompanion.insert(
                id: saleItemId,
                saleId: safeSaleId,
                productId: line.item.productId,
                qty: line.item.qty,
                unitPriceCents: line.item.unitPriceCents,
                unitCostCents: Value(line.unitCostCents),
                taxRateBps: line.item.taxRateBps,
                lineSubtotalCents: line.lineSubtotalCents,
                lineTaxCents: line.lineTaxCents,
                lineCostCents: Value(line.lineCostCents),
                lineTotalCents: line.lineTotalCents,
              ),
            );
        await _insertSaleItemAllocations(
          saleId: safeSaleId,
          saleItemId: saleItemId,
          productId: line.item.productId,
          warehouseId: sale.warehouseId,
          allocations: line.allocations,
        );
        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: _uuid.v4(),
                productId: line.item.productId,
                warehouseId: sale.warehouseId,
                type: 'out',
                qty: line.item.qty,
                reasonCode: Value(movementReasonCode),
                movementSource: Value(movementSource),
                refType: Value(movementRefType),
                refId: Value(safeSaleId),
                note: Value('$movementNotePrefix ${sale.folio}'),
                createdBy: safeUserId,
              ),
            );
      }

      for (final PaymentInput payment in input.payments) {
        await _db.into(_db.payments).insert(
              PaymentsCompanion.insert(
                id: _uuid.v4(),
                saleId: safeSaleId,
                method: payment.method,
                amountCents: payment.amountCents,
                transactionId: Value(_normalizeOptional(payment.transactionId)),
                sourceCurrencyCode: Value(payment.sourceCurrencyCode),
                sourceAmountCents: Value(payment.sourceAmountCents),
              ),
            );
      }

      await (_db.update(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .write(
        SalesCompanion(
          customerId: Value(cleanCustomerId),
          subtotalCents: Value(subtotalCents),
          taxCents: Value(taxCents),
          totalCents: Value(totalCents),
          status: const Value('posted'),
        ),
      );

      await _syncProductsCostFromActiveLots(
        productIds: stockProductIds,
        now: now,
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'SALE_EDITED',
              entity: 'sale',
              entityId: safeSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'folio': sale.folio,
                'isConsignmentSale': isConsignmentSale,
                'oldSubtotalCents': sale.subtotalCents,
                'oldTaxCents': sale.taxCents,
                'oldTotalCents': sale.totalCents,
                'newSubtotalCents': subtotalCents,
                'newTaxCents': taxCents,
                'newTotalCents': totalCents,
                'oldItemsCount': previousLines.length,
                'newItemsCount': processedLines.length,
                'newPaymentsCount': input.payments.length,
              }),
            ),
          );
    });
  }

  Future<List<ArchivedSaleView>> listArchivedSales({
    String? search,
    int limit = 250,
  }) async {
    final String cleanedSearch = (search ?? '').trim().toLowerCase();
    final int safeLimit = limit < 1 ? 1 : limit;
    final StringBuffer sql = StringBuffer(
      '''
      SELECT
        s.id AS sale_id,
        s.folio AS folio,
        s.created_at AS created_at,
        s.total_cents AS total_cents,
        s.terminal_id AS terminal_id,
        COALESCE(w.name, 'Sin almacén') AS warehouse_name,
        COALESCE(
          NULLIF(TRIM(MIN(e.name)), ''),
          COALESCE(u.username, 'Sin usuario')
        ) AS cashier_name,
        c.full_name AS customer_name,
        COALESCE(MAX(sm.voided_at), s.created_at) AS archived_at
      FROM sales s
      LEFT JOIN warehouses w ON w.id = s.warehouse_id
      LEFT JOIN users u ON u.id = s.cashier_id
      LEFT JOIN customers c ON c.id = s.customer_id
      LEFT JOIN pos_session_employees se ON se.session_id = s.terminal_session_id
      LEFT JOIN employees e ON e.id = se.employee_id
      LEFT JOIN stock_movements sm
        ON sm.ref_id = s.id
       AND LOWER(COALESCE(sm.ref_type, '')) IN (
         'sale',
         'sale_pos',
         'sale_direct',
         'consignment_sale',
         'consignment_sale_pos',
         'consignment_sale_direct'
       )
      WHERE LOWER(COALESCE(s.status, '')) = 'archived'
      ''',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    if (cleanedSearch.isNotEmpty) {
      final String pattern = '%$cleanedSearch%';
      sql.write(
        '''
        AND (
          LOWER(COALESCE(s.folio, '')) LIKE ?
          OR LOWER(COALESCE(c.full_name, '')) LIKE ?
          OR LOWER(COALESCE(u.username, '')) LIKE ?
        )
        ''',
      );
      variables.addAll(<Variable<Object>>[
        Variable<String>(pattern),
        Variable<String>(pattern),
        Variable<String>(pattern),
      ]);
    }
    sql.write(
      '''
      GROUP BY
        s.id,
        s.folio,
        s.created_at,
        s.total_cents,
        s.terminal_id,
        s.cashier_id,
        w.name,
        u.username,
        c.full_name
      ORDER BY archived_at DESC, s.created_at DESC
      LIMIT ?
      ''',
    );
    variables.add(Variable<int>(safeLimit));

    final List<QueryRow> rows = await _db
        .customSelect(
          sql.toString(),
          variables: variables,
        )
        .get();

    return rows.map((QueryRow row) {
      final String terminalId =
          (row.readNullable<String>('terminal_id') ?? '').trim();
      return ArchivedSaleView(
        id: (row.readNullable<String>('sale_id') ?? '').trim(),
        folio: (row.readNullable<String>('folio') ?? '-').trim(),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        archivedAt: row.readNullable<DateTime>('archived_at') ?? DateTime.now(),
        totalCents: (row.data['total_cents'] as num?)?.toInt() ?? 0,
        warehouseName:
            (row.readNullable<String>('warehouse_name') ?? 'Sin almacén')
                .trim(),
        cashierName:
            (row.readNullable<String>('cashier_name') ?? 'Sin usuario').trim(),
        customerName:
            _normalizeOptional(row.readNullable<String>('customer_name')),
        channel: terminalId.isEmpty ? 'directa' : 'pos',
      );
    }).toList(growable: false);
  }

  Future<void> archiveSale({
    required String saleId,
    required String userId,
    String? note,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeSaleId = saleId.trim();
    final String safeUserId = userId.trim();
    if (safeSaleId.isEmpty) {
      throw const _SaleException('Venta inválida.');
    }
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }

    await _db.transaction(() async {
      final Sale? sale = await (_db.select(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .getSingleOrNull();
      if (sale == null) {
        throw const _SaleException('La venta no existe.');
      }
      final String status = sale.status.trim().toLowerCase();
      if (status == 'archived') {
        return;
      }
      if (status != 'posted') {
        throw _SaleException(
          'Solo se pueden archivar ventas publicadas. Estado actual: ${sale.status}.',
        );
      }

      final DateTime now = DateTime.now();
      final Set<String> affectedProductIds = <String>{};
      await _releaseSaleAllocations(
        saleId: safeSaleId,
        markVoided: true,
        voidedAt: now,
      );
      final List<_SaleMovementDelta> activeMovementDeltas =
          await _loadSaleMovementDeltas(
        saleId: safeSaleId,
        isVoided: false,
      );
      if (activeMovementDeltas.isNotEmpty) {
        for (final _SaleMovementDelta delta in activeMovementDeltas) {
          affectedProductIds.add(delta.productId);
          final StockBalance? balance = await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(delta.productId) &
                      tbl.warehouseId.equals(delta.warehouseId),
                ))
              .getSingleOrNull();
          final double currentQty = balance?.qty ?? 0;
          final double nextQty = currentQty - delta.signedDelta;
          await _upsertStock(
            productId: delta.productId,
            warehouseId: delta.warehouseId,
            qty: nextQty,
            now: now,
          );
        }
      } else {
        final List<SaleItem> lines = await (_db.select(_db.saleItems)
              ..where((SaleItems tbl) => tbl.saleId.equals(safeSaleId)))
            .get();
        for (final SaleItem line in lines) {
          affectedProductIds.add(line.productId);
          final StockBalance? balance = await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(line.productId) &
                      tbl.warehouseId.equals(sale.warehouseId),
                ))
              .getSingleOrNull();
          final double currentQty = balance?.qty ?? 0;
          final double nextQty = currentQty + line.qty;
          await _upsertStock(
            productId: line.productId,
            warehouseId: sale.warehouseId,
            qty: nextQty,
            now: now,
          );
        }
      }

      final String? safeNote = _normalizeOptional(note);
      await _db.customStatement(
        '''
        UPDATE stock_movements
        SET
          is_voided = 1,
          voided_at = ?,
          voided_by = ?,
          void_note = COALESCE(?, void_note)
        WHERE ref_id = ?
          AND LOWER(COALESCE(ref_type, '')) IN (
            'sale',
            'sale_pos',
            'sale_direct',
            'consignment_sale',
            'consignment_sale_pos',
            'consignment_sale_direct'
          )
          AND COALESCE(is_voided, 0) = 0
        ''',
        <Object?>[
          now.millisecondsSinceEpoch,
          safeUserId,
          safeNote,
          safeSaleId,
        ],
      );

      await (_db.update(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(sale.id)))
          .write(
        const SalesCompanion(
          status: Value('archived'),
        ),
      );

      await _syncProductsCostFromActiveLots(
        productIds: affectedProductIds,
        now: now,
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'SALE_ARCHIVED',
              entity: 'sale',
              entityId: safeSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'folio': sale.folio,
                'note': safeNote,
              }),
            ),
          );
    });
  }

  Future<void> restoreArchivedSale({
    required String saleId,
    required String userId,
    bool allowNegativeResult = false,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeSaleId = saleId.trim();
    final String safeUserId = userId.trim();
    if (safeSaleId.isEmpty) {
      throw const _SaleException('Venta inválida.');
    }
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }

    await _db.transaction(() async {
      final Sale? sale = await (_db.select(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .getSingleOrNull();
      if (sale == null) {
        throw const _SaleException('La venta no existe.');
      }
      final String status = sale.status.trim().toLowerCase();
      if (status == 'posted') {
        return;
      }
      if (status != 'archived') {
        throw _SaleException(
          'Solo se pueden restaurar ventas archivadas. Estado actual: ${sale.status}.',
        );
      }

      final DateTime now = DateTime.now();
      final Set<String> affectedProductIds = <String>{};
      final List<_SaleMovementDelta> voidedMovementDeltas =
          await _loadSaleMovementDeltas(
        saleId: safeSaleId,
        isVoided: true,
      );
      if (voidedMovementDeltas.isNotEmpty) {
        for (final _SaleMovementDelta delta in voidedMovementDeltas) {
          affectedProductIds.add(delta.productId);
          final StockBalance? balance = await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(delta.productId) &
                      tbl.warehouseId.equals(delta.warehouseId),
                ))
              .getSingleOrNull();
          final double currentQty = balance?.qty ?? 0;
          final double nextQty = currentQty + delta.signedDelta;
          if (!allowNegativeResult && nextQty < 0) {
            throw _SaleException(
              'No hay stock suficiente para restaurar la venta "${sale.folio}".',
            );
          }
          await _upsertStock(
            productId: delta.productId,
            warehouseId: delta.warehouseId,
            qty: nextQty,
            now: now,
          );
        }
      } else {
        final List<SaleItem> lines = await (_db.select(_db.saleItems)
              ..where((SaleItems tbl) => tbl.saleId.equals(safeSaleId)))
            .get();
        for (final SaleItem line in lines) {
          affectedProductIds.add(line.productId);
          final StockBalance? balance = await (_db.select(_db.stockBalances)
                ..where(
                  (StockBalances tbl) =>
                      tbl.productId.equals(line.productId) &
                      tbl.warehouseId.equals(sale.warehouseId),
                ))
              .getSingleOrNull();
          final double currentQty = balance?.qty ?? 0;
          final double nextQty = currentQty - line.qty;
          if (!allowNegativeResult && nextQty < 0) {
            throw _SaleException(
              'No hay stock suficiente para restaurar la venta "${sale.folio}".',
            );
          }
          await _upsertStock(
            productId: line.productId,
            warehouseId: sale.warehouseId,
            qty: nextQty,
            now: now,
          );
        }
      }
      await _reapplyVoidedSaleAllocations(
        saleId: safeSaleId,
        allowNegativeResult: allowNegativeResult,
      );

      await _db.customStatement(
        '''
        UPDATE stock_movements
        SET
          is_voided = 0,
          voided_at = NULL,
          voided_by = NULL,
          void_note = NULL
        WHERE ref_id = ?
          AND LOWER(COALESCE(ref_type, '')) IN (
            'sale',
            'sale_pos',
            'sale_direct',
            'consignment_sale',
            'consignment_sale_pos',
            'consignment_sale_direct'
          )
          AND COALESCE(is_voided, 0) = 1
        ''',
        <Object?>[safeSaleId],
      );

      await (_db.update(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(sale.id)))
          .write(
        const SalesCompanion(
          status: Value('posted'),
        ),
      );

      await _syncProductsCostFromActiveLots(
        productIds: affectedProductIds,
        now: now,
      );

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'SALE_RESTORED',
              entity: 'sale',
              entityId: safeSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'folio': sale.folio,
                'allowNegativeResult': allowNegativeResult,
              }),
            ),
          );
    });
  }

  Future<void> permanentlyDeleteArchivedSale({
    required String saleId,
    required String userId,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeSaleId = saleId.trim();
    final String safeUserId = userId.trim();
    if (safeSaleId.isEmpty) {
      throw const _SaleException('Venta inválida.');
    }
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }

    await _db.transaction(() async {
      final Sale? sale = await (_db.select(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .getSingleOrNull();
      if (sale == null) {
        return;
      }
      final String status = sale.status.trim().toLowerCase();
      if (status != 'archived') {
        throw const _SaleException(
          'Solo se puede eliminar definitivamente una venta archivada.',
        );
      }

      final QueryRow? movementCheck = await _db.customSelect(
        '''
        SELECT
          CAST(COUNT(*) AS INTEGER) AS total
        FROM stock_movements sm
        WHERE sm.ref_id = ?
          AND LOWER(COALESCE(sm.ref_type, '')) IN (
            'sale',
            'sale_pos',
            'sale_direct',
            'consignment_sale',
            'consignment_sale_pos',
            'consignment_sale_direct'
          )
          AND COALESCE(sm.is_voided, 0) = 0
        LIMIT 1
        ''',
        variables: <Variable<Object>>[
          Variable<String>(safeSaleId),
        ],
      ).getSingleOrNull();
      final int activeMovements =
          (movementCheck?.data['total'] as num?)?.toInt() ?? 0;
      if (activeMovements > 0) {
        throw const _SaleException(
          'La venta aún tiene movimientos activos. Archívala primero.',
        );
      }

      final String archivedFolio = sale.folio;
      await _db.customStatement(
        '''
        DELETE FROM sale_item_lot_allocations
        WHERE sale_id = ?
        ''',
        <Object?>[safeSaleId],
      );
      await _db.customStatement(
        '''
        DELETE FROM stock_movements
        WHERE ref_id = ?
          AND LOWER(COALESCE(ref_type, '')) IN (
            'sale',
            'sale_pos',
            'sale_direct',
            'consignment_sale',
            'consignment_sale_pos',
            'consignment_sale_direct'
          )
        ''',
        <Object?>[safeSaleId],
      );
      await (_db.delete(_db.payments)
            ..where((Payments tbl) => tbl.saleId.equals(safeSaleId)))
          .go();
      await (_db.delete(_db.saleItems)
            ..where((SaleItems tbl) => tbl.saleId.equals(safeSaleId)))
          .go();
      await (_db.delete(_db.sales)
            ..where((Sales tbl) => tbl.id.equals(safeSaleId)))
          .go();

      await _db.into(_db.auditLogs).insert(
            AuditLogsCompanion.insert(
              id: _uuid.v4(),
              userId: Value(safeUserId),
              action: 'SALE_PURGED',
              entity: 'sale',
              entityId: safeSaleId,
              payloadJson: jsonEncode(<String, Object?>{
                'folio': archivedFolio,
              }),
            ),
          );
    });
  }

  Future<List<SaleStockIntegrityIssue>> listSalesStockIntegrityIssues({
    required String userId,
    int maxSales = 250,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }
    final bool isAdmin = await _userHasAdminRole(safeUserId);
    if (!isAdmin) {
      throw const _SaleException(
        'Solo un administrador puede consultar integridad ventas/stock.',
      );
    }
    final int safeLimit = maxSales < 1 ? 1 : maxSales;
    final List<_SalesStockMismatchRow> mismatchRows =
        await _loadSalesStockMismatchRows();
    if (mismatchRows.isEmpty) {
      return const <SaleStockIntegrityIssue>[];
    }

    final Map<String, _SaleStockIssueBuilder> issueBySaleId =
        <String, _SaleStockIssueBuilder>{};
    for (final _SalesStockMismatchRow row in mismatchRows) {
      final _SaleStockIssueBuilder issue = issueBySaleId.putIfAbsent(
        row.saleId,
        () => _SaleStockIssueBuilder(
          saleId: row.saleId,
          folio: row.folio,
          createdAt: row.createdAt,
          warehouseId: row.warehouseId,
          warehouseName: row.warehouseName,
          cashierId: row.cashierId,
          terminalId: row.terminalId,
        ),
      );
      issue.totalMissingQty += row.missingQty;
      if (row.voidedQty > 0.000001) {
        issue.hasVoidedMovements = true;
      }
      issue.lines.add(
        SaleStockIntegrityIssueLine(
          productId: row.productId,
          productName: row.productName,
          productSku: row.productSku,
          expectedQty: row.expectedQty,
          coveredQty: row.coveredQty,
          missingQty: row.missingQty,
          voidedQty: row.voidedQty,
        ),
      );
    }

    final List<String> saleIds = issueBySaleId.keys.toList(growable: false);
    for (final String saleId in saleIds) {
      issueBySaleId[saleId]!.hasPurgeEvidence =
          await _hasPurgedSaleMovementEvidence(saleId);
    }

    final List<SaleStockIntegrityIssue> issues = issueBySaleId.values
        .map((issue) => issue.build())
        .toList(growable: false)
      ..sort(
        (SaleStockIntegrityIssue a, SaleStockIntegrityIssue b) =>
            b.createdAt.compareTo(a.createdAt),
      );
    if (issues.length <= safeLimit) {
      return issues;
    }
    return issues.take(safeLimit).toList(growable: false);
  }

  Future<SaleStockIntegrityRepairResult> repairSalesStockIntegrity({
    required String userId,
    bool dryRun = false,
    bool allowNegativeStock = true,
    int sampleLimit = 12,
    Iterable<String>? saleIds,
    Iterable<SaleStockIntegrityRepairTarget>? targets,
  }) async {
    await _licenseService.requireWriteAccess();
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      throw const _SaleException('Usuario inválido.');
    }
    final bool isAdmin = await _userHasAdminRole(safeUserId);
    if (!isAdmin) {
      throw const _SaleException(
        'Solo un administrador puede reparar integridad ventas/stock.',
      );
    }

    return _db.transaction(() async {
      final Map<String, Set<String>> selectedProductsBySaleId =
          <String, Set<String>>{};
      for (final SaleStockIntegrityRepairTarget target
          in (targets ?? const <SaleStockIntegrityRepairTarget>[])) {
        final String safeSaleId = target.saleId.trim();
        final String safeProductId = target.productId.trim();
        if (safeSaleId.isEmpty || safeProductId.isEmpty) {
          continue;
        }
        selectedProductsBySaleId
            .putIfAbsent(safeSaleId, () => <String>{})
            .add(safeProductId);
      }
      final Set<String> selectedSaleIds = (saleIds ?? const <String>[])
          .map((String value) => value.trim())
          .where((String value) => value.isNotEmpty)
          .toSet();
      selectedSaleIds.addAll(selectedProductsBySaleId.keys);
      final Expression<int> postedCountExp = _db.sales.id.count();
      final TypedResult postedCountRow = await (_db.selectOnly(_db.sales)
            ..addColumns(<Expression<Object>>[postedCountExp])
            ..where(_db.sales.status.equals('posted')))
          .getSingle();
      final int postedSalesCount = postedCountRow.read(postedCountExp) ?? 0;

      final List<_SalesStockMismatchRow> mismatchRows =
          await _loadSalesStockMismatchRows(
        saleIds: selectedSaleIds.isEmpty ? null : selectedSaleIds,
      );

      final Set<String> affectedSales = <String>{};
      final Set<String> purgeEvidenceSales = <String>{};
      final Set<String> voidedEvidenceSales = <String>{};
      final Set<String> sampleFolios = <String>{};
      final Set<String> affectedProductIds = <String>{};
      double missingQtyTotal = 0;
      int movementsRebuilt = 0;
      int stockAdjustments = 0;
      int skippedForNegativeStock = 0;
      int affectedLinesCount = 0;

      final Set<String> mismatchSaleIds =
          mismatchRows.map((_SalesStockMismatchRow row) => row.saleId).toSet();

      final Map<String, _SalePaymentSummary> paymentSummaryBySaleId =
          <String, _SalePaymentSummary>{};
      for (final String saleId in mismatchSaleIds) {
        final QueryRow? row = await _db.customSelect(
          '''
          SELECT
            CAST(COALESCE(COUNT(*), 0) AS INTEGER) AS payments_count,
            CAST(
              COALESCE(
                SUM(
                  CASE
                    WHEN LOWER(COALESCE(NULLIF(TRIM(method), ''), '')) = 'consignment'
                      THEN 1
                    ELSE 0
                  END
                ),
                0
              ) AS INTEGER
            ) AS consignment_count
          FROM payments
          WHERE sale_id = ?
          LIMIT 1
          ''',
          variables: <Variable<Object>>[
            Variable<String>(saleId),
          ],
        ).getSingleOrNull();
        paymentSummaryBySaleId[saleId] = _SalePaymentSummary(
          paymentsCount: (row?.data['payments_count'] as num?)?.toInt() ?? 0,
          consignmentCount:
              (row?.data['consignment_count'] as num?)?.toInt() ?? 0,
        );
      }

      for (final _SalesStockMismatchRow row in mismatchRows) {
        final String saleId = row.saleId;
        final String folio = row.folio;
        final String warehouseId = row.warehouseId;
        final String productId = row.productId;
        final String terminalId = row.terminalId;
        final double missingQty = row.missingQty;
        final double voidedQty = row.voidedQty;
        if (saleId.isEmpty ||
            warehouseId.isEmpty ||
            productId.isEmpty ||
            missingQty <= 0.000001) {
          continue;
        }
        final Set<String>? selectedProductIds =
            selectedProductsBySaleId[saleId];
        if (selectedProductIds != null &&
            selectedProductIds.isNotEmpty &&
            !selectedProductIds.contains(productId)) {
          continue;
        }

        affectedSales.add(saleId);
        affectedLinesCount += 1;
        missingQtyTotal += missingQty;
        if (sampleFolios.length < (sampleLimit < 1 ? 1 : sampleLimit) &&
            folio.isNotEmpty) {
          sampleFolios.add(folio);
        }
        if (voidedQty > 0.000001) {
          voidedEvidenceSales.add(saleId);
        }
        if (await _hasPurgedSaleMovementEvidence(saleId)) {
          purgeEvidenceSales.add(saleId);
        }

        if (dryRun) {
          continue;
        }

        final StockBalance? balance = await (_db.select(_db.stockBalances)
              ..where(
                (StockBalances tbl) =>
                    tbl.productId.equals(productId) &
                    tbl.warehouseId.equals(warehouseId),
              ))
            .getSingleOrNull();
        final double currentQty = balance?.qty ?? 0;
        final double nextQty = currentQty - missingQty;
        if (!allowNegativeStock && nextQty < 0) {
          skippedForNegativeStock += 1;
          continue;
        }

        final _SalePaymentSummary paymentSummary =
            paymentSummaryBySaleId[saleId] ??
                const _SalePaymentSummary(
                  paymentsCount: 0,
                  consignmentCount: 0,
                );
        final bool isConsignmentSale = paymentSummary.consignmentCount > 0 ||
            paymentSummary.paymentsCount == 0;
        final bool isDirectSale = terminalId.isEmpty;
        final String movementSource = isConsignmentSale
            ? (isDirectSale ? 'direct_consignment' : 'pos_consignment')
            : (isDirectSale ? 'direct_sale' : 'pos');
        final String movementRefType = isConsignmentSale
            ? (isDirectSale
                ? 'consignment_sale_direct'
                : 'consignment_sale_pos')
            : (isDirectSale ? 'sale_direct' : 'sale_pos');
        final String movementReasonCode =
            isConsignmentSale ? 'consignment_sale' : 'sale';
        final String notePrefix = isConsignmentSale
            ? (isDirectSale ? 'Consignacion directa' : 'Consignacion POS')
            : (isDirectSale ? 'Venta directa' : 'Venta POS');

        final DateTime movementAt = row.createdAt;
        final DateTime repairAppliedAt = DateTime.now();
        await _upsertStock(
          productId: productId,
          warehouseId: warehouseId,
          qty: nextQty,
          now: repairAppliedAt,
        );
        stockAdjustments += 1;

        await _db.into(_db.stockMovements).insert(
              StockMovementsCompanion.insert(
                id: _uuid.v4(),
                productId: productId,
                warehouseId: warehouseId,
                type: 'out',
                qty: missingQty,
                reasonCode: Value(movementReasonCode),
                movementSource: Value(movementSource),
                refType: Value(movementRefType),
                refId: Value(saleId),
                note: Value('$notePrefix $folio (reparacion integridad)'),
                createdBy: safeUserId,
                createdAt: Value(movementAt),
              ),
            );
        movementsRebuilt += 1;
        affectedProductIds.add(productId);
      }

      if (!dryRun) {
        await _syncProductsCostFromActiveLots(
          productIds: affectedProductIds,
          now: DateTime.now(),
        );
        await _db.into(_db.auditLogs).insert(
              AuditLogsCompanion.insert(
                id: _uuid.v4(),
                userId: Value(safeUserId),
                action: 'SALES_STOCK_INTEGRITY_REPAIRED',
                entity: 'sales_stock_integrity',
                entityId: _uuid.v4(),
                payloadJson: jsonEncode(<String, Object?>{
                  'dryRun': false,
                  'affectedSales': affectedSales.length,
                  'affectedLines': affectedLinesCount,
                  'missingQtyTotal': missingQtyTotal,
                  'salesWithPurgeEvidence': purgeEvidenceSales.length,
                  'salesWithVoidedMovements': voidedEvidenceSales.length,
                  'movementsRebuilt': movementsRebuilt,
                  'stockAdjustments': stockAdjustments,
                  'skippedForNegativeStock': skippedForNegativeStock,
                  'selectedSalesCount': selectedSaleIds.length,
                  'selectedProductTargets':
                      selectedProductsBySaleId.values.fold<int>(
                    0,
                    (int sum, Set<String> items) => sum + items.length,
                  ),
                  'sampleFolios': sampleFolios.toList(growable: false),
                }),
              ),
            );
      }

      return SaleStockIntegrityRepairResult(
        postedSalesCount: postedSalesCount,
        affectedSalesCount: affectedSales.length,
        affectedLinesCount: affectedLinesCount,
        missingQtyTotal: missingQtyTotal,
        salesWithPurgeEvidence: purgeEvidenceSales.length,
        salesWithVoidedMovements: voidedEvidenceSales.length,
        movementsRebuilt: movementsRebuilt,
        stockAdjustments: stockAdjustments,
        skippedForNegativeStock: skippedForNegativeStock,
        sampleFolios: sampleFolios.toList(growable: false),
        dryRun: dryRun,
      );
    });
  }

  String _normalizeCurrencyCode(String? value) {
    return (value ?? '').trim().toUpperCase();
  }

  String? _normalizeOptional(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
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

  bool _isConsignmentMethod(String method) {
    return method.trim().toLowerCase() == 'consignment';
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

  Future<bool> _userHasAdminRole(String userId) async {
    final String safeUserId = userId.trim();
    if (safeUserId.isEmpty) {
      return false;
    }
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(safeUserId)))
        .getSingleOrNull();
    if (user != null && user.role.trim().toLowerCase() == 'admin') {
      return true;
    }
    final UserRole? role = await (_db.select(_db.userRoles)
          ..where(
            (UserRoles tbl) =>
                tbl.userId.equals(safeUserId) &
                tbl.roleId.equals(AppRoleIds.admin),
          ))
        .getSingleOrNull();
    return role != null;
  }

  Future<bool> _userHasPermission({
    required String userId,
    required String permissionKey,
  }) async {
    final String safeUserId = userId.trim();
    final String safePermissionKey = permissionKey.trim();
    if (safeUserId.isEmpty || safePermissionKey.isEmpty) {
      return false;
    }
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(safeUserId)))
        .getSingleOrNull();
    if (user != null && user.role.trim().toLowerCase() == 'admin') {
      return true;
    }
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT 1 AS ok
      FROM user_roles ur
      INNER JOIN role_permissions rp
        ON rp.role_id = ur.role_id
      WHERE ur.user_id = ?
        AND rp.permission_key = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeUserId),
        Variable<String>(safePermissionKey),
      ],
    ).getSingleOrNull();
    if (row != null) {
      return true;
    }
    if (user != null &&
        user.role.trim().toLowerCase() == 'cajero' &&
        AppPermissionsCatalog.defaultCashierPermissions
            .contains(safePermissionKey)) {
      return true;
    }
    return false;
  }

  Future<List<_SalesStockMismatchRow>> _loadSalesStockMismatchRows({
    Set<String>? saleIds,
  }) async {
    final Set<String> selectedSaleIds = (saleIds ?? const <String>{})
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
    final List<Variable<Object>> variables = <Variable<Object>>[];
    String saleFilter = '';
    if (selectedSaleIds.isNotEmpty) {
      final String placeholders =
          List<String>.filled(selectedSaleIds.length, '?').join(', ');
      saleFilter = 'AND s.id IN ($placeholders)';
      variables.addAll(
        selectedSaleIds.map((String saleId) => Variable<String>(saleId)),
      );
    }

    final List<QueryRow> rows = await _db.customSelect(
      '''
      WITH sale_lines AS (
        SELECT
          s.id AS sale_id,
          s.folio AS folio,
          s.warehouse_id AS warehouse_id,
          s.cashier_id AS cashier_id,
          COALESCE(s.terminal_id, '') AS terminal_id,
          s.created_at AS created_at,
          si.product_id AS product_id,
          COALESCE(SUM(ABS(COALESCE(si.qty, 0))), 0) AS expected_qty
        FROM sales s
        INNER JOIN sale_items si
          ON si.sale_id = s.id
        WHERE LOWER(COALESCE(s.status, '')) = 'posted'
          $saleFilter
        GROUP BY
          s.id,
          s.folio,
          s.warehouse_id,
          s.cashier_id,
          s.terminal_id,
          s.created_at,
          si.product_id
      ),
      active_movements AS (
        SELECT
          sm.ref_id AS sale_id,
          sm.product_id AS product_id,
          COALESCE(
            SUM(
              CASE
                WHEN LOWER(COALESCE(sm.type, '')) = 'out'
                  THEN ABS(COALESCE(sm.qty, 0))
                WHEN LOWER(COALESCE(sm.type, '')) = 'in'
                  THEN -ABS(COALESCE(sm.qty, 0))
                WHEN LOWER(COALESCE(sm.type, '')) = 'adjust'
                  THEN -COALESCE(sm.qty, 0)
                ELSE 0
              END
            ),
            0
          ) AS covered_qty
        FROM stock_movements sm
        WHERE LOWER(COALESCE(sm.ref_type, '')) IN (
          'sale',
          'sale_pos',
          'sale_direct',
          'consignment_sale',
          'consignment_sale_pos',
          'consignment_sale_direct'
        )
          AND COALESCE(sm.is_voided, 0) = 0
        GROUP BY sm.ref_id, sm.product_id
      ),
      voided_movements AS (
        SELECT
          sm.ref_id AS sale_id,
          sm.product_id AS product_id,
          COALESCE(
            SUM(
              CASE
                WHEN LOWER(COALESCE(sm.type, '')) = 'out'
                  THEN ABS(COALESCE(sm.qty, 0))
                WHEN LOWER(COALESCE(sm.type, '')) = 'in'
                  THEN -ABS(COALESCE(sm.qty, 0))
                WHEN LOWER(COALESCE(sm.type, '')) = 'adjust'
                  THEN -COALESCE(sm.qty, 0)
                ELSE 0
              END
            ),
            0
          ) AS voided_qty
        FROM stock_movements sm
        WHERE LOWER(COALESCE(sm.ref_type, '')) IN (
          'sale',
          'sale_pos',
          'sale_direct',
          'consignment_sale',
          'consignment_sale_pos',
          'consignment_sale_direct'
        )
          AND COALESCE(sm.is_voided, 0) = 1
        GROUP BY sm.ref_id, sm.product_id
      )
      SELECT
        sl.sale_id AS sale_id,
        COALESCE(NULLIF(TRIM(sl.folio), ''), sl.sale_id) AS folio,
        sl.warehouse_id AS warehouse_id,
        COALESCE(NULLIF(TRIM(w.name), ''), 'Almacen') AS warehouse_name,
        sl.cashier_id AS cashier_id,
        sl.terminal_id AS terminal_id,
        sl.created_at AS created_at,
        sl.product_id AS product_id,
        COALESCE(NULLIF(TRIM(p.name), ''), 'Producto') AS product_name,
        COALESCE(NULLIF(TRIM(p.sku), ''), '-') AS product_sku,
        COALESCE(sl.expected_qty, 0) AS expected_qty,
        COALESCE(am.covered_qty, 0) AS covered_qty,
        COALESCE(vm.voided_qty, 0) AS voided_qty,
        (COALESCE(sl.expected_qty, 0) - COALESCE(am.covered_qty, 0)) AS missing_qty
      FROM sale_lines sl
      LEFT JOIN active_movements am
        ON am.sale_id = sl.sale_id
       AND am.product_id = sl.product_id
      LEFT JOIN voided_movements vm
        ON vm.sale_id = sl.sale_id
       AND vm.product_id = sl.product_id
      LEFT JOIN products p
        ON p.id = sl.product_id
      LEFT JOIN warehouses w
        ON w.id = sl.warehouse_id
      WHERE (COALESCE(sl.expected_qty, 0) - COALESCE(am.covered_qty, 0)) > 0.000001
      ORDER BY sl.created_at DESC, sl.sale_id ASC, sl.product_id ASC
      ''',
      variables: variables,
    ).get();

    return rows.map((QueryRow row) {
      return _SalesStockMismatchRow(
        saleId: (row.readNullable<String>('sale_id') ?? '').trim(),
        folio: (row.readNullable<String>('folio') ?? '').trim(),
        warehouseId: (row.readNullable<String>('warehouse_id') ?? '').trim(),
        warehouseName:
            (row.readNullable<String>('warehouse_name') ?? '').trim(),
        cashierId: (row.readNullable<String>('cashier_id') ?? '').trim(),
        terminalId: (row.readNullable<String>('terminal_id') ?? '').trim(),
        createdAt: row.readNullable<DateTime>('created_at') ?? DateTime.now(),
        productId: (row.readNullable<String>('product_id') ?? '').trim(),
        productName: (row.readNullable<String>('product_name') ?? '').trim(),
        productSku: (row.readNullable<String>('product_sku') ?? '').trim(),
        expectedQty: (row.data['expected_qty'] as num?)?.toDouble() ?? 0,
        coveredQty: (row.data['covered_qty'] as num?)?.toDouble() ?? 0,
        voidedQty: (row.data['voided_qty'] as num?)?.toDouble() ?? 0,
        missingQty: (row.data['missing_qty'] as num?)?.toDouble() ?? 0,
      );
    }).where((_SalesStockMismatchRow row) {
      return row.saleId.isNotEmpty &&
          row.warehouseId.isNotEmpty &&
          row.productId.isNotEmpty &&
          row.missingQty > 0.000001;
    }).toList(growable: false);
  }

  Future<bool> _hasPurgedSaleMovementEvidence(String saleId) async {
    final String safeSaleId = saleId.trim();
    if (safeSaleId.isEmpty) {
      return false;
    }
    final QueryRow? row = await _db.customSelect(
      '''
      SELECT 1 AS ok
      FROM audit_logs
      WHERE action = 'STOCK_MOVEMENT_PURGED'
        AND payload_json LIKE ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[
        Variable<String>('%"refId":"$safeSaleId"%'),
      ],
    ).getSingleOrNull();
    return row != null;
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

  Future<void> _syncProductsCostFromActiveLots({
    required Set<String> productIds,
    required DateTime now,
  }) async {
    if (productIds.isEmpty) {
      return;
    }
    for (final String rawProductId in productIds) {
      final String productId = rawProductId.trim();
      if (productId.isEmpty) {
        continue;
      }
      final QueryRow? lotRow = await _db.customSelect(
        '''
        SELECT
          COALESCE(l.unit_cost_cents, 0) AS unit_cost_cents
        FROM stock_lots l
        WHERE l.product_id = ?
          AND COALESCE(l.qty_remaining, 0) > 0
        ORDER BY l.received_at ASC, l.created_at ASC, l.id ASC
        LIMIT 1
        ''',
        variables: <Variable<Object>>[
          Variable<String>(productId),
        ],
      ).getSingleOrNull();
      if (lotRow == null) {
        continue;
      }
      final int lotCostCents =
          (lotRow.data['unit_cost_cents'] as num?)?.toInt() ?? 0;
      await (_db.update(_db.products)
            ..where((Products tbl) => tbl.id.equals(productId)))
          .write(
        ProductsCompanion(
          costPriceCents: Value(lotCostCents < 0 ? 0 : lotCostCents),
          updatedAt: Value(now),
        ),
      );
    }
  }

  Future<void> _insertSaleItemAllocations({
    required String saleId,
    required String saleItemId,
    required String productId,
    required String warehouseId,
    required List<_FifoAllocation> allocations,
  }) async {
    for (final _FifoAllocation allocation in allocations) {
      await _db.into(_db.saleItemLotAllocations).insert(
            SaleItemLotAllocationsCompanion.insert(
              id: _uuid.v4(),
              saleId: saleId,
              saleItemId: saleItemId,
              productId: productId,
              warehouseId: warehouseId,
              lotId: Value(allocation.lotId),
              qty: Value(allocation.qty),
              unitCostCents: Value(allocation.unitCostCents),
              lineCostCents: Value(allocation.lineCostCents),
            ),
          );
    }
  }

  Future<List<_FifoAllocation>> _reserveFifoAllocations({
    required String productId,
    required String warehouseId,
    required double qty,
    required int fallbackUnitCostCents,
  }) async {
    if (qty <= 0) {
      return const <_FifoAllocation>[];
    }
    const double epsilon = 0.000001;
    final List<_FifoAllocation> out = <_FifoAllocation>[];
    double remaining = qty;

    final double untrackedQty = await _loadUntrackedStockQty(
      productId: productId,
      warehouseId: warehouseId,
      epsilon: epsilon,
    );
    if (untrackedQty > epsilon) {
      final double take = untrackedQty < remaining ? untrackedQty : remaining;
      out.add(
        _FifoAllocation(
          lotId: null,
          qty: take,
          unitCostCents: fallbackUnitCostCents,
          lineCostCents: (take * fallbackUnitCostCents).round(),
        ),
      );
      remaining -= take;
    }

    final List<QueryRow> lotRows = remaining <= epsilon
        ? const <QueryRow>[]
        : await _db.customSelect(
            '''
            SELECT
              l.id AS lot_id,
              COALESCE(l.qty_remaining, 0) AS qty_remaining,
              COALESCE(l.unit_cost_cents, 0) AS unit_cost_cents
            FROM stock_lots l
            WHERE l.product_id = ?
              AND l.warehouse_id = ?
              AND COALESCE(l.qty_remaining, 0) > 0
            ORDER BY l.received_at ASC, l.created_at ASC, l.id ASC
            ''',
            variables: <Variable<Object>>[
              Variable<String>(productId),
              Variable<String>(warehouseId),
            ],
          ).get();

    for (final QueryRow row in lotRows) {
      if (remaining <= epsilon) {
        break;
      }
      final String lotId = (row.readNullable<String>('lot_id') ?? '').trim();
      if (lotId.isEmpty) {
        continue;
      }
      final double lotRemaining =
          (row.data['qty_remaining'] as num?)?.toDouble() ?? 0;
      if (lotRemaining <= epsilon) {
        continue;
      }
      final double take = lotRemaining < remaining ? lotRemaining : remaining;
      final int unitCostCents =
          (row.data['unit_cost_cents'] as num?)?.toInt() ??
              fallbackUnitCostCents;
      final int lineCostCents = (take * unitCostCents).round();

      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(lotRemaining - take),
        ),
      );
      out.add(
        _FifoAllocation(
          lotId: lotId,
          qty: take,
          unitCostCents: unitCostCents,
          lineCostCents: lineCostCents,
        ),
      );
      remaining -= take;
    }

    if (remaining > epsilon) {
      out.add(
        _FifoAllocation(
          lotId: null,
          qty: remaining,
          unitCostCents: fallbackUnitCostCents,
          lineCostCents: (remaining * fallbackUnitCostCents).round(),
        ),
      );
    }
    return out;
  }

  Future<double> _loadUntrackedStockQty({
    required String productId,
    required String warehouseId,
    required double epsilon,
  }) async {
    final QueryRow row = await _db.customSelect(
      '''
      SELECT
        COALESCE(
          (SELECT sb.qty
           FROM stock_balances sb
           WHERE sb.product_id = ?
             AND sb.warehouse_id = ?
           LIMIT 1),
          0
        ) AS stock_qty,
        COALESCE(
          (SELECT SUM(COALESCE(l.qty_remaining, 0))
           FROM stock_lots l
           WHERE l.product_id = ?
             AND l.warehouse_id = ?
             AND COALESCE(l.qty_remaining, 0) > 0),
          0
        ) AS lot_qty
      ''',
      variables: <Variable<Object>>[
        Variable<String>(productId),
        Variable<String>(warehouseId),
        Variable<String>(productId),
        Variable<String>(warehouseId),
      ],
    ).getSingle();
    final double stockQty = (row.data['stock_qty'] as num?)?.toDouble() ?? 0;
    final double lotQty = (row.data['lot_qty'] as num?)?.toDouble() ?? 0;
    final double untrackedQty = stockQty - lotQty;
    return untrackedQty > epsilon ? untrackedQty : 0;
  }

  Future<void> _releaseSaleAllocations({
    required String saleId,
    required bool markVoided,
    DateTime? voidedAt,
  }) async {
    final String safeSaleId = saleId.trim();
    if (safeSaleId.isEmpty) {
      return;
    }

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        a.id AS id,
        a.lot_id AS lot_id,
        COALESCE(a.qty, 0) AS qty
      FROM sale_item_lot_allocations a
      WHERE a.sale_id = ?
        AND COALESCE(a.is_voided, 0) = 0
      ORDER BY a.created_at ASC, a.id ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeSaleId),
      ],
    ).get();

    for (final QueryRow row in rows) {
      final String lotId = (row.readNullable<String>('lot_id') ?? '').trim();
      if (lotId.isEmpty) {
        continue;
      }
      final double qty = (row.data['qty'] as num?)?.toDouble() ?? 0;
      if (qty.abs() <= 0.000001) {
        continue;
      }
      final StockLot? lot = await (_db.select(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .getSingleOrNull();
      if (lot == null) {
        continue;
      }
      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(lot.qtyRemaining + qty),
        ),
      );
    }

    if (markVoided) {
      await (_db.update(_db.saleItemLotAllocations)
            ..where((SaleItemLotAllocations tbl) =>
                tbl.saleId.equals(safeSaleId) & tbl.isVoided.equals(false)))
          .write(
        SaleItemLotAllocationsCompanion(
          isVoided: const Value(true),
          voidedAt: Value(voidedAt ?? DateTime.now()),
        ),
      );
      return;
    }

    await (_db.delete(_db.saleItemLotAllocations)
          ..where(
              (SaleItemLotAllocations tbl) => tbl.saleId.equals(safeSaleId)))
        .go();
  }

  Future<void> _reapplyVoidedSaleAllocations({
    required String saleId,
    required bool allowNegativeResult,
  }) async {
    final String safeSaleId = saleId.trim();
    if (safeSaleId.isEmpty) {
      return;
    }

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        a.id AS id,
        a.lot_id AS lot_id,
        COALESCE(a.qty, 0) AS qty
      FROM sale_item_lot_allocations a
      WHERE a.sale_id = ?
        AND COALESCE(a.is_voided, 0) = 1
      ORDER BY a.created_at ASC, a.id ASC
      ''',
      variables: <Variable<Object>>[
        Variable<String>(safeSaleId),
      ],
    ).get();

    const double epsilon = 0.000001;
    for (final QueryRow row in rows) {
      final String lotId = (row.readNullable<String>('lot_id') ?? '').trim();
      if (lotId.isEmpty) {
        continue;
      }
      final double qty = (row.data['qty'] as num?)?.toDouble() ?? 0;
      if (qty.abs() <= epsilon) {
        continue;
      }
      final StockLot? lot = await (_db.select(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .getSingleOrNull();
      if (lot == null) {
        continue;
      }
      final double nextRemaining = lot.qtyRemaining - qty;
      if (!allowNegativeResult && nextRemaining < -epsilon) {
        throw const _SaleException(
          'No hay stock FIFO suficiente para restaurar la venta con su costo original.',
        );
      }
      await (_db.update(_db.stockLots)
            ..where((StockLots tbl) => tbl.id.equals(lotId)))
          .write(
        StockLotsCompanion(
          qtyRemaining: Value(nextRemaining),
        ),
      );
    }

    await (_db.update(_db.saleItemLotAllocations)
          ..where((SaleItemLotAllocations tbl) =>
              tbl.saleId.equals(safeSaleId) & tbl.isVoided.equals(true)))
        .write(
      const SaleItemLotAllocationsCompanion(
        isVoided: Value(false),
        voidedAt: Value(null),
      ),
    );
  }

  Future<List<_SaleMovementDelta>> _loadSaleMovementDeltas({
    required String saleId,
    required bool isVoided,
  }) async {
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        sm.product_id AS product_id,
        sm.warehouse_id AS warehouse_id,
        COALESCE(
          SUM(
            CASE
              WHEN LOWER(COALESCE(sm.type, '')) = 'in' THEN ABS(COALESCE(sm.qty, 0))
              WHEN LOWER(COALESCE(sm.type, '')) = 'out' THEN -ABS(COALESCE(sm.qty, 0))
              WHEN LOWER(COALESCE(sm.type, '')) = 'adjust' THEN COALESCE(sm.qty, 0)
              ELSE COALESCE(sm.qty, 0)
            END
          ),
          0
        ) AS signed_delta
      FROM stock_movements sm
      WHERE sm.ref_id = ?
        AND LOWER(COALESCE(sm.ref_type, '')) IN (
          'sale',
          'sale_pos',
          'sale_direct',
          'consignment_sale',
          'consignment_sale_pos',
          'consignment_sale_direct'
        )
        AND COALESCE(sm.is_voided, 0) = ?
      GROUP BY sm.product_id, sm.warehouse_id
      ''',
      variables: <Variable<Object>>[
        Variable<String>(saleId),
        Variable<int>(isVoided ? 1 : 0),
      ],
    ).get();

    return rows.map((QueryRow row) {
      return _SaleMovementDelta(
        productId: (row.readNullable<String>('product_id') ?? '').trim(),
        warehouseId: (row.readNullable<String>('warehouse_id') ?? '').trim(),
        signedDelta: (row.data['signed_delta'] as num?)?.toDouble() ?? 0,
      );
    }).where((row) {
      return row.productId.isNotEmpty &&
          row.warehouseId.isNotEmpty &&
          row.signedDelta.abs() > 0.000001;
    }).toList(growable: false);
  }
}

class _ProcessedLine {
  const _ProcessedLine({
    required this.item,
    required this.productName,
    required this.currentQty,
    required this.nextQty,
    required this.unitCostCents,
    required this.lineCostCents,
    required this.lineSubtotalCents,
    required this.lineTaxCents,
    required this.lineTotalCents,
    required this.allocations,
  });

  final SaleItemInput item;
  final String productName;
  final double currentQty;
  final double nextQty;
  final int unitCostCents;
  final int lineCostCents;
  final int lineSubtotalCents;
  final int lineTaxCents;
  final int lineTotalCents;
  final List<_FifoAllocation> allocations;
}

class _SaleStockIssueBuilder {
  _SaleStockIssueBuilder({
    required this.saleId,
    required this.folio,
    required this.createdAt,
    required this.warehouseId,
    required this.warehouseName,
    required this.cashierId,
    required this.terminalId,
  });

  final String saleId;
  final String folio;
  final DateTime createdAt;
  final String warehouseId;
  final String warehouseName;
  final String cashierId;
  final String terminalId;
  final List<SaleStockIntegrityIssueLine> lines =
      <SaleStockIntegrityIssueLine>[];
  bool hasPurgeEvidence = false;
  bool hasVoidedMovements = false;
  double totalMissingQty = 0;

  SaleStockIntegrityIssue build() {
    return SaleStockIntegrityIssue(
      saleId: saleId,
      folio: folio,
      createdAt: createdAt,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
      cashierId: cashierId,
      terminalId: terminalId,
      hasPurgeEvidence: hasPurgeEvidence,
      hasVoidedMovements: hasVoidedMovements,
      totalMissingQty: totalMissingQty,
      lines: lines.toList(growable: false),
    );
  }
}

class _SalesStockMismatchRow {
  const _SalesStockMismatchRow({
    required this.saleId,
    required this.folio,
    required this.warehouseId,
    required this.warehouseName,
    required this.cashierId,
    required this.terminalId,
    required this.createdAt,
    required this.productId,
    required this.productName,
    required this.productSku,
    required this.expectedQty,
    required this.coveredQty,
    required this.voidedQty,
    required this.missingQty,
  });

  final String saleId;
  final String folio;
  final String warehouseId;
  final String warehouseName;
  final String cashierId;
  final String terminalId;
  final DateTime createdAt;
  final String productId;
  final String productName;
  final String productSku;
  final double expectedQty;
  final double coveredQty;
  final double voidedQty;
  final double missingQty;
}

class _SaleEditProcessedLine {
  const _SaleEditProcessedLine({
    required this.item,
    required this.unitCostCents,
    required this.lineCostCents,
    required this.lineSubtotalCents,
    required this.lineTaxCents,
    required this.lineTotalCents,
    required this.allocations,
  });

  final SaleItemInput item;
  final int unitCostCents;
  final int lineCostCents;
  final int lineSubtotalCents;
  final int lineTaxCents;
  final int lineTotalCents;
  final List<_FifoAllocation> allocations;
}

class _SaleMovementDelta {
  const _SaleMovementDelta({
    required this.productId,
    required this.warehouseId,
    required this.signedDelta,
  });

  final String productId;
  final String warehouseId;
  final double signedDelta;
}

class _SalePaymentSummary {
  const _SalePaymentSummary({
    required this.paymentsCount,
    required this.consignmentCount,
  });

  final int paymentsCount;
  final int consignmentCount;
}

class _FifoAllocation {
  const _FifoAllocation({
    required this.lotId,
    required this.qty,
    required this.unitCostCents,
    required this.lineCostCents,
  });

  final String? lotId;
  final double qty;
  final int unitCostCents;
  final int lineCostCents;
}

class _SaleException implements Exception {
  const _SaleException(this.message);
  final String message;
}
