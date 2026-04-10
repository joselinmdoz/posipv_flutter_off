import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/compras_local_datasource.dart';
import 'compras_providers.dart';

class ComprasPage extends ConsumerStatefulWidget {
  const ComprasPage({super.key});

  @override
  ConsumerState<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends ConsumerState<ComprasPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _saving = false;
  List<PurchaseSummaryView> _purchases = <PurchaseSummaryView>[];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadPurchases();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) {
        return;
      }
      _loadPurchases();
    });
  }

  Future<void> _loadPurchases() async {
    setState(() => _loading = true);
    try {
      final ComprasLocalDataSource ds =
          ref.read(comprasLocalDataSourceProvider);
      final List<PurchaseSummaryView> rows = await ds.listPurchases(
        search: _searchCtrl.text,
        limit: 200,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _purchases = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar las compras: $e');
    }
  }

  Future<void> _openCreateDialog() async {
    if (_saving) {
      return;
    }
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Sesion inválida.');
      return;
    }

    final ComprasLocalDataSource ds = ref.read(comprasLocalDataSourceProvider);
    try {
      final List<PurchaseWarehouseOption> warehouses =
          await ds.listActiveWarehouses();
      final List<PurchaseProductOption> products =
          await ds.listActiveProducts(limit: 400);
      if (!mounted) {
        return;
      }
      if (warehouses.isEmpty || products.isEmpty) {
        _show(
            'Debes tener almacenes y productos activos para registrar compras.');
        return;
      }

      final _CreatePurchaseDraft? draft =
          await showModalBottomSheet<_CreatePurchaseDraft>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return _PurchaseCreateSheet(
            warehouses: warehouses,
            products: products,
          );
        },
      );

      if (draft == null) {
        return;
      }

      setState(() => _saving = true);
      final CreatePurchaseResult result = await ds.createPurchase(
        CreatePurchaseInput(
          warehouseId: draft.warehouseId,
          userId: session.userId,
          supplierName: draft.supplierName,
          supplierDoc: draft.supplierDoc,
          note: draft.note,
          lines: draft.lines,
        ),
      );
      if (!mounted) {
        return;
      }
      _show('Compra ${result.folio} registrada.');
      await _loadPurchases();
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo registrar la compra: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(int cents) => r'$' + (cents / 100).toStringAsFixed(2);

  String _dateShort(DateTime value) {
    final DateTime local = value.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString().padLeft(4, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Future<void> _openPurchaseDetail(String purchaseId) async {
    final String id = purchaseId.trim();
    if (id.isEmpty) {
      return;
    }
    final ComprasLocalDataSource ds = ref.read(comprasLocalDataSourceProvider);
    try {
      final PurchaseDetailView? detail = await ds.getPurchaseDetail(id);
      if (!mounted || detail == null) {
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return _PurchaseDetailSheet(
            detail: detail,
            money: _money,
            dateShort: _dateShort,
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo cargar el detalle de la compra: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.purchasesManage) ?? false;
    final bool canViewLotStatus =
        session?.hasPermission(AppPermissionKeys.purchasesView) ?? false;

    return AppScaffold(
      title: 'Compras',
      currentRoute: '/compras',
      showTopTabs: false,
      appBarActions: canViewLotStatus
          ? <Widget>[
              IconButton(
                tooltip: 'Estado de lotes',
                onPressed: () => context.push('/reportes-lotes'),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
            ]
          : null,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _saving ? null : _openCreateDialog,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart_rounded),
              label: const Text('Nueva compra'),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por folio, proveedor o almacén',
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _purchases.isEmpty
                      ? Center(
                          child: Text(
                            'No hay compras registradas.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPurchases,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                            itemCount: _purchases.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (BuildContext context, int index) {
                              final PurchaseSummaryView row = _purchases[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openPurchaseDetail(row.id),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                row.folio,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                              ),
                                            ),
                                            Text(
                                              _money(row.totalCents),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${row.warehouseName} · ${row.linesCount} líneas',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Registrada por ${row.createdByUsername} · ${_dateShort(row.createdAt)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        if ((row.supplierName ?? '').isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              'Proveedor: ${row.supplierName}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                        if ((row.supplierDoc ?? '').isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'Documento: ${row.supplierDoc}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseDetailSheet extends StatelessWidget {
  const _PurchaseDetailSheet({
    required this.detail,
    required this.money,
    required this.dateShort,
  });

  final PurchaseDetailView detail;
  final String Function(int cents) money;
  final String Function(DateTime value) dateShort;

  String _qty(double value) {
    if ((value - value.roundToDouble()).abs() <= 0.000001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Detalle de Compra',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              '${detail.summary.folio} · ${dateShort(detail.summary.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${detail.summary.warehouseName} · ${detail.summary.linesCount} líneas',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if ((detail.note ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Nota: ${detail.note}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: detail.lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final PurchaseDetailLineView line = detail.lines[index];
                  final bool noLotTrace = line.lotQtyIn <= 0.000001;
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  line.productName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                money(line.lineCostCents),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${line.sku}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 14,
                            runSpacing: 6,
                            children: <Widget>[
                              Text(
                                'Cant.: ${_qty(line.qty)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Costo U.: ${money(line.unitCostCents)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Lote recibido: ${_qty(line.lotQtyIn)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Lote consumido: ${_qty(line.consumedQty)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Lote restante: ${_qty(line.lotQtyRemaining)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if (noLotTrace)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Sin trazabilidad de lotes para esta línea (compra antigua o ajuste legado).',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.orange[800]),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCreateSheet extends StatefulWidget {
  const _PurchaseCreateSheet({
    required this.warehouses,
    required this.products,
  });

  final List<PurchaseWarehouseOption> warehouses;
  final List<PurchaseProductOption> products;

  @override
  State<_PurchaseCreateSheet> createState() => _PurchaseCreateSheetState();
}

class _PurchaseCreateSheetState extends State<_PurchaseCreateSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _supplierCtrl = TextEditingController();
  final TextEditingController _supplierDocCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  late String _warehouseId;
  final List<_PurchaseDraftLine> _lines = <_PurchaseDraftLine>[];

  @override
  void initState() {
    super.initState();
    _warehouseId = widget.warehouses.first.id;
    _lines.add(_PurchaseDraftLine());
  }

  @override
  void dispose() {
    _supplierCtrl.dispose();
    _supplierDocCtrl.dispose();
    _noteCtrl.dispose();
    for (final _PurchaseDraftLine line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    setState(() => _lines.add(_PurchaseDraftLine()));
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) {
      return;
    }
    setState(() {
      final _PurchaseDraftLine removed = _lines.removeAt(index);
      removed.dispose();
    });
  }

  void _onProductChanged(int index, String? productId) {
    final _PurchaseDraftLine line = _lines[index];
    line.productId = productId;
    final PurchaseProductOption product = widget.products.firstWhere(
      (PurchaseProductOption row) => row.id == productId,
      orElse: () => const PurchaseProductOption(
        id: '',
        sku: '',
        name: '',
        salePriceCents: 0,
        defaultCostCents: 0,
      ),
    );
    if (product.id.isNotEmpty &&
        line.costCtrl.text.trim().isEmpty &&
        product.defaultCostCents > 0) {
      line.costCtrl.text = (product.defaultCostCents / 100).toStringAsFixed(2);
    }
    setState(() {});
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final List<PurchaseLineInput> lines = <PurchaseLineInput>[];
    for (final _PurchaseDraftLine line in _lines) {
      final String productId = (line.productId ?? '').trim();
      if (productId.isEmpty) {
        continue;
      }
      final double? qty = _parseDecimal(line.qtyCtrl.text);
      final double? cost = _parseDecimal(line.costCtrl.text);
      if (qty == null || qty <= 0 || cost == null || cost < 0) {
        continue;
      }
      lines.add(
        PurchaseLineInput(
          productId: productId,
          qty: qty,
          unitCostCents: (cost * 100).round(),
        ),
      );
    }

    if (lines.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
              content: Text('Debes agregar al menos una línea válida.')),
        );
      return;
    }

    Navigator.of(context).pop(
      _CreatePurchaseDraft(
        warehouseId: _warehouseId,
        supplierName: _supplierCtrl.text.trim(),
        supplierDoc: _supplierDocCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        lines: lines,
      ),
    );
  }

  double? _parseDecimal(String raw) {
    final String clean = raw.trim().replaceAll(',', '.');
    if (clean.isEmpty) {
      return null;
    }
    return double.tryParse(clean);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + insets.bottom),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Registrar compra',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _warehouseId,
                  decoration: const InputDecoration(labelText: 'Almacén'),
                  items: widget.warehouses
                      .map(
                        (PurchaseWarehouseOption row) =>
                            DropdownMenuItem<String>(
                          value: row.id,
                          child: Text(row.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return;
                    }
                    setState(() => _warehouseId = value);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Proveedor (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _supplierDocCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Documento proveedor (opcional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Líneas',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ...List<Widget>.generate(_lines.length, (int index) {
                  final _PurchaseDraftLine line = _lines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: Column(
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            initialValue: line.productId,
                            decoration: const InputDecoration(
                              labelText: 'Producto',
                            ),
                            items: widget.products
                                .map(
                                  (PurchaseProductOption product) =>
                                      DropdownMenuItem<String>(
                                    value: product.id,
                                    child: Text(
                                      '${product.sku} · ${product.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            validator: (String? value) {
                              final String clean = (value ?? '').trim();
                              if (clean.isEmpty) {
                                return 'Selecciona un producto';
                              }
                              return null;
                            },
                            onChanged: (String? value) =>
                                _onProductChanged(index, value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: TextFormField(
                                  controller: line.qtyCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Cantidad',
                                  ),
                                  validator: (String? value) {
                                    final double? qty =
                                        _parseDecimal(value ?? '');
                                    if (qty == null || qty <= 0) {
                                      return 'Inválida';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: line.costCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Costo unitario',
                                  ),
                                  validator: (String? value) {
                                    final double? cost =
                                        _parseDecimal(value ?? '');
                                    if (cost == null || cost < 0) {
                                      return 'Inválido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                tooltip: 'Eliminar línea',
                                onPressed: () => _removeLine(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar línea'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: const Text('Registrar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseDraftLine {
  _PurchaseDraftLine()
      : qtyCtrl = TextEditingController(text: '1'),
        costCtrl = TextEditingController();

  String? productId;
  final TextEditingController qtyCtrl;
  final TextEditingController costCtrl;

  void dispose() {
    qtyCtrl.dispose();
    costCtrl.dispose();
  }
}

class _CreatePurchaseDraft {
  const _CreatePurchaseDraft({
    required this.warehouseId,
    required this.supplierName,
    required this.supplierDoc,
    required this.note,
    required this.lines,
  });

  final String warehouseId;
  final String supplierName;
  final String supplierDoc;
  final String note;
  final List<PurchaseLineInput> lines;
}
