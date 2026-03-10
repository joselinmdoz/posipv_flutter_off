import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/utils/app_result.dart';
import '../domain/sale_models.dart';

class SaleService {
  SaleService(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;

  Future<AppResult<CreateSaleResult>> createSale(CreateSaleInput input) async {
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

    try {
      final CreateSaleResult result = await _db.transaction(() async {
        final Warehouse? warehouse = await (_db.select(_db.warehouses)
              ..where((Warehouses tbl) => tbl.id.equals(input.warehouseId)))
            .getSingleOrNull();
        if (warehouse == null || !warehouse.isActive) {
          throw const _SaleException('El almacen seleccionado no es valido.');
        }

        final DateTime now = DateTime.now();
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

        final int totalCents = subtotalCents + taxCents;
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
                  refType: const Value('sale'),
                  refId: Value(saleId),
                  note: Value('Venta POS $folio'),
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

  String _buildFolio(DateTime now) {
    final String y = now.year.toString().padLeft(4, '0');
    final String m = now.month.toString().padLeft(2, '0');
    final String d = now.day.toString().padLeft(2, '0');
    final String hh = now.hour.toString().padLeft(2, '0');
    final String mm = now.minute.toString().padLeft(2, '0');
    final String ss = now.second.toString().padLeft(2, '0');
    return 'POS-$y$m$d-$hh$mm$ss';
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
