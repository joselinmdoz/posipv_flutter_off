import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../compras/data/compras_local_datasource.dart';
import '../../compras/presentation/compras_providers.dart';

class LotsStatusPage extends ConsumerStatefulWidget {
  const LotsStatusPage({super.key});

  @override
  ConsumerState<LotsStatusPage> createState() => _LotsStatusPageState();
}

class _LotsStatusPageState extends ConsumerState<LotsStatusPage> {
  static const String _allWarehouseToken = '__all_warehouses__';
  static const String _allProductToken = '__all_products__';

  bool _loading = true;
  bool _alertsOnly = false;
  String _selectedWarehouseId = _allWarehouseToken;
  String _selectedProductId = _allProductToken;
  List<PurchaseWarehouseOption> _warehouses = <PurchaseWarehouseOption>[];
  List<PurchaseProductOption> _products = <PurchaseProductOption>[];
  LotStatusSnapshotView? _snapshot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load(showLoader: true);
    });
  }

  Future<void> _load({bool showLoader = false}) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }
    final ComprasLocalDataSource ds = ref.read(comprasLocalDataSourceProvider);
    try {
      final Future<List<PurchaseWarehouseOption>> warehousesFuture =
          ds.listActiveWarehouses();
      final Future<List<PurchaseProductOption>> productsFuture =
          ds.listActiveProducts(limit: 600);
      final List<PurchaseWarehouseOption> warehouses = await warehousesFuture;
      final List<PurchaseProductOption> products = await productsFuture;

      String selectedWarehouse = _selectedWarehouseId;
      if (selectedWarehouse != _allWarehouseToken &&
          warehouses.every((PurchaseWarehouseOption row) {
            return row.id != selectedWarehouse;
          })) {
        selectedWarehouse = _allWarehouseToken;
      }

      String selectedProduct = _selectedProductId;
      if (selectedProduct != _allProductToken &&
          products.every((PurchaseProductOption row) {
            return row.id != selectedProduct;
          })) {
        selectedProduct = _allProductToken;
      }

      final LotStatusSnapshotView snapshot = await ds.loadLotStatusSnapshot(
        warehouseId:
            selectedWarehouse == _allWarehouseToken ? null : selectedWarehouse,
        productId: selectedProduct == _allProductToken ? null : selectedProduct,
        alertsOnly: _alertsOnly,
        limit: 1000,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _products = products;
        _selectedWarehouseId = selectedWarehouse;
        _selectedProductId = selectedProduct;
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text('No se pudo cargar estado de lotes: $e')),
        );
    }
  }

  String _money(int cents) => r'$' + (cents / 100).toStringAsFixed(2);

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() <= 0.000001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _dateShort(DateTime value) {
    final DateTime local = value.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString();
    return '$d/$m/$y';
  }

  String _sourceLabel(LotStatusRowView row) {
    final String source = row.sourceType.trim().toLowerCase();
    if (source == 'purchase') {
      return 'Compra';
    }
    if (source == 'manual_movement') {
      return 'Ajuste manual (+)';
    }
    if (source == 'manual_fallback') {
      return 'Ajuste manual (-) sin FIFO';
    }
    if (source.isEmpty) {
      return 'Origen no definido';
    }
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final LotStatusSnapshotView? snapshot = _snapshot;

    return AppScaffold(
      title: 'Estado de lotes',
      currentRoute: '/reportes-lotes',
      onRefresh: () => _load(showLoader: false),
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Recargar',
          onPressed: _loading ? null : () => _load(showLoader: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _load(showLoader: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF263244)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedWarehouseId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            labelText: 'Almacén',
                          ),
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: _allWarehouseToken,
                              child: Text('Todos los almacenes'),
                            ),
                            ..._warehouses.map(
                              (PurchaseWarehouseOption row) =>
                                  DropdownMenuItem<String>(
                                value: row.id,
                                child: Text(row.name),
                              ),
                            ),
                          ],
                          onChanged: (String? value) async {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedWarehouseId = value);
                            await _load(showLoader: true);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedProductId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            labelText: 'Producto',
                          ),
                          items: <DropdownMenuItem<String>>[
                            const DropdownMenuItem<String>(
                              value: _allProductToken,
                              child: Text('Todos los productos'),
                            ),
                            ..._products.map(
                              (PurchaseProductOption row) =>
                                  DropdownMenuItem<String>(
                                value: row.id,
                                child: Text('${row.sku} · ${row.name}'),
                              ),
                            ),
                          ],
                          onChanged: (String? value) async {
                            if (value == null) {
                              return;
                            }
                            setState(() => _selectedProductId = value);
                            await _load(showLoader: true);
                          },
                        ),
                        const SizedBox(height: 4),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _alertsOnly,
                          title: const Text('Mostrar solo alertas'),
                          subtitle: const Text(
                            'Lotes agotados o con remanente <= 20%',
                          ),
                          onChanged: (bool value) async {
                            setState(() => _alertsOnly = value);
                            await _load(showLoader: true);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (snapshot != null)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _MetricCard(
                          label: 'Total lotes',
                          value: snapshot.totalLots.toString(),
                        ),
                        _MetricCard(
                          label: 'Activos',
                          value: snapshot.activeLots.toString(),
                        ),
                        _MetricCard(
                          label: 'Agotados',
                          value: snapshot.depletedLots.toString(),
                        ),
                        _MetricCard(
                          label: 'Alertas',
                          value: snapshot.lowLots.toString(),
                          highlight: snapshot.lowLots > 0,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (snapshot == null || snapshot.rows.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _alertsOnly
                              ? 'No hay lotes en estado de alerta con los filtros actuales.'
                              : 'No hay lotes para los filtros seleccionados.',
                        ),
                      ),
                    )
                  else
                    ...snapshot.rows.map((LotStatusRowView row) {
                      final double ratio = row.remainingRatio.clamp(0, 1);
                      final Color ratioColor = row.isDepleted
                          ? const Color(0xFFB42318)
                          : (row.isLow
                              ? const Color(0xFFB54708)
                              : const Color(0xFF15803D));
                      final String status = row.isDepleted
                          ? 'Agotado'
                          : (row.isLow ? 'Bajo' : 'Normal');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      row.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ratioColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: ratioColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('SKU: ${row.sku}'),
                              Text('Almacén: ${row.warehouseName}'),
                              Text(
                                'Lote: ${row.lotId.substring(0, row.lotId.length > 12 ? 12 : row.lotId.length)}',
                              ),
                              Text(
                                'Origen: ${_sourceLabel(row)}${(row.sourceId ?? '').isNotEmpty ? ' · ${row.sourceId}' : ''}',
                              ),
                              Text(
                                'Recibido: ${_dateShort(row.receivedAt)} · Costo U: ${_money(row.unitCostCents)}',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      'Recibido ${_qty(row.qtyIn)} · Consumido ${_qty(row.qtyConsumed)} · Restante ${_qty(row.qtyRemaining)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(ratio * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: ratioColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  color: ratioColor,
                                  backgroundColor: isDark
                                      ? const Color(0xFF243042)
                                      : const Color(0xFFE5EAF2),
                                ),
                              ),
                              if ((row.note ?? '').isNotEmpty) ...<Widget>[
                                const SizedBox(height: 6),
                                Text(
                                  'Nota: ${row.note}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color accent =
        highlight ? const Color(0xFFB54708) : const Color(0xFF1152D4);
    return Container(
      width: 160,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? accent.withValues(alpha: 0.35)
              : (isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}
