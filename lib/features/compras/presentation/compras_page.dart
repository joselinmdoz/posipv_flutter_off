import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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

enum _PurchaseExportAction {
  exportCsv,
  exportPdf,
  shareCsv,
  sharePdf,
}

class _ComprasPageState extends ConsumerState<ComprasPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  bool _saving = false;
  bool _exporting = false;
  List<PurchaseSummaryView> _purchases = <PurchaseSummaryView>[];
  List<PurchaseProductOption> _products = <PurchaseProductOption>[];
  String? _selectedProductId;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadPurchases(refreshCatalogs: true);
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

  DateTime _startOfDay(DateTime value) {
    final DateTime d = value.toLocal();
    return DateTime(d.year, d.month, d.day);
  }

  Future<void> _loadPurchases({bool refreshCatalogs = false}) async {
    setState(() => _loading = true);
    try {
      final ComprasLocalDataSource ds =
          ref.read(comprasLocalDataSourceProvider);
      List<PurchaseProductOption> products = _products;
      if (refreshCatalogs || products.isEmpty) {
        products = await ds.listActiveProducts(limit: 600);
      }
      String? selectedProductId = (_selectedProductId ?? '').trim().isEmpty
          ? null
          : _selectedProductId!.trim();
      if (selectedProductId != null &&
          products.every(
              (PurchaseProductOption row) => row.id != selectedProductId)) {
        selectedProductId = null;
      }
      final DateTime? createdFrom =
          _selectedDateFrom == null ? null : _startOfDay(_selectedDateFrom!);
      final DateTime? createdTo = _selectedDateTo == null
          ? null
          : _startOfDay(_selectedDateTo!).add(const Duration(days: 1));
      final List<PurchaseSummaryView> rows = await ds.listPurchases(
        search: _searchCtrl.text,
        productId: selectedProductId,
        createdFrom: createdFrom,
        createdTo: createdTo,
        limit: 600,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _purchases = rows;
        _products = products;
        _selectedProductId = selectedProductId;
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
      await _loadPurchases(refreshCatalogs: true);
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

  String _dateOnly(DateTime value) {
    final DateTime local = value.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  String _selectedProductLabel() {
    final String selected = (_selectedProductId ?? '').trim();
    if (selected.isEmpty) {
      return 'Todos';
    }
    for (final PurchaseProductOption row in _products) {
      if (row.id == selected) {
        return '${row.sku} · ${row.name}';
      }
    }
    return 'Todos';
  }

  PurchaseExportFilters _currentExportFilters() {
    final String query = _searchCtrl.text.trim();
    return PurchaseExportFilters(
      dateFrom: _selectedDateFrom == null ? '-' : _dateOnly(_selectedDateFrom!),
      dateTo: _selectedDateTo == null ? '-' : _dateOnly(_selectedDateTo!),
      product: _selectedProductLabel(),
      search: query.isEmpty ? '-' : query,
    );
  }

  int get _totalFilteredCents => _purchases.fold<int>(
        0,
        (int sum, PurchaseSummaryView row) => sum + row.totalCents,
      );

  Future<void> _pickDateFrom() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _selectedDateFrom ?? _selectedDateTo ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Fecha inicial',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDateFrom = picked;
      if (_selectedDateTo != null &&
          _startOfDay(_selectedDateTo!).isBefore(_startOfDay(picked))) {
        _selectedDateTo = picked;
      }
    });
    await _loadPurchases();
  }

  Future<void> _pickDateTo() async {
    final DateTime now = DateTime.now();
    final DateTime initial = _selectedDateTo ?? _selectedDateFrom ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: 'Fecha final',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDateTo = picked;
      if (_selectedDateFrom != null &&
          _startOfDay(_selectedDateFrom!).isAfter(_startOfDay(picked))) {
        _selectedDateFrom = picked;
      }
    });
    await _loadPurchases();
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedProductId = null;
      _selectedDateFrom = null;
      _selectedDateTo = null;
    });
    await _loadPurchases();
  }

  Future<void> _handleExportAction(_PurchaseExportAction action) async {
    if (_exporting) {
      return;
    }
    if (_purchases.isEmpty) {
      _show('No hay compras filtradas para exportar.');
      return;
    }
    final bool csv = action == _PurchaseExportAction.exportCsv ||
        action == _PurchaseExportAction.shareCsv;
    final bool share = action == _PurchaseExportAction.shareCsv ||
        action == _PurchaseExportAction.sharePdf;
    setState(() => _exporting = true);
    try {
      final ComprasLocalDataSource ds =
          ref.read(comprasLocalDataSourceProvider);
      final String path = csv
          ? await ds.exportPurchasesCsv(
              purchases: _purchases,
              filters: _currentExportFilters(),
            )
          : await ds.exportPurchasesPdf(
              purchases: _purchases,
              filters: _currentExportFilters(),
            );
      if (share) {
        await Share.shareXFiles(
          <XFile>[XFile(path)],
          text: 'Listado de compras',
          subject: 'Compras',
        );
      }
      _show(
        share
            ? 'Archivo listo para compartir:\n$path'
            : (csv ? 'CSV exportado: $path' : 'PDF exportado: $path'),
      );
    } catch (e) {
      _show('No se pudo exportar compras: $e');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
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
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(currentSessionProvider);
    final bool canManage =
        session?.hasPermission(AppPermissionKeys.purchasesManage) ?? false;
    final bool canViewLotStatus =
        session?.hasPermission(AppPermissionKeys.purchasesView) ?? false;
    final List<Widget> appBarActions = <Widget>[
      if (canViewLotStatus)
        IconButton(
          tooltip: 'Estado de lotes',
          onPressed: () => context.push('/reportes-lotes'),
          icon: const Icon(Icons.inventory_2_outlined),
        ),
      if (_exporting)
        const Padding(
          padding: EdgeInsets.only(right: 14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      else
        PopupMenuButton<_PurchaseExportAction>(
          tooltip: 'Exportar / compartir',
          onSelected: _handleExportAction,
          itemBuilder: (_) => const <PopupMenuEntry<_PurchaseExportAction>>[
            PopupMenuItem<_PurchaseExportAction>(
              value: _PurchaseExportAction.exportCsv,
              child: Text('Exportar CSV'),
            ),
            PopupMenuItem<_PurchaseExportAction>(
              value: _PurchaseExportAction.exportPdf,
              child: Text('Exportar PDF'),
            ),
            PopupMenuDivider(),
            PopupMenuItem<_PurchaseExportAction>(
              value: _PurchaseExportAction.shareCsv,
              child: Text('Compartir CSV'),
            ),
            PopupMenuItem<_PurchaseExportAction>(
              value: _PurchaseExportAction.sharePdf,
              child: Text('Compartir PDF'),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.more_vert_rounded),
          ),
        ),
    ];

    return AppScaffold(
      title: 'Compras',
      currentRoute: '/compras',
      showTopTabs: false,
      appBarActions: appBarActions,
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por folio, proveedor o almacén',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2B3444)
                        : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.filter_alt_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Filtros',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: (_selectedProductId ?? '').isNotEmpty ||
                                  _selectedDateFrom != null ||
                                  _selectedDateTo != null
                              ? _clearFilters
                              : null,
                          child: const Text('Limpiar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos los productos'),
                        ),
                        ..._products.map(
                          (PurchaseProductOption row) =>
                              DropdownMenuItem<String?>(
                            value: row.id,
                            child: Text(
                              '${row.sku} · ${row.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (String? value) async {
                        setState(() => _selectedProductId = value);
                        await _loadPurchases();
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDateFrom,
                            icon: const Icon(Icons.event_rounded, size: 18),
                            label: Text(
                              _selectedDateFrom == null
                                  ? 'Desde'
                                  : _dateOnly(_selectedDateFrom!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDateTo,
                            icon: const Icon(Icons.event_available_rounded,
                                size: 18),
                            label: Text(
                              _selectedDateTo == null
                                  ? 'Hasta'
                                  : _dateOnly(_selectedDateTo!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mostrando ${_purchases.length} compra(s) · Total ${_money(_totalFilteredCents)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
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
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                            itemCount: _purchases.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (BuildContext context, int index) {
                              final PurchaseSummaryView row = _purchases[index];
                              return _buildPurchaseCard(context, row);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(BuildContext context, PurchaseSummaryView row) {
    final bool hasSupplier = (row.supplierName ?? '').trim().isNotEmpty;
    final bool hasSupplierDoc = (row.supplierDoc ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openPurchaseDetail(row.id),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_rounded,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  row.folio,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Almacén ${row.warehouseName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _money(row.totalCents),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0C4A6E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        children: <Widget>[
                          _chip('Líneas: ${row.linesCount}',
                              const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
                          _chip(
                            'Usuario: ${row.createdByUsername}',
                            const Color(0xFFF3F4F6),
                            const Color(0xFF374151),
                          ),
                          _chip(
                            _dateShort(row.createdAt),
                            const Color(0xFFF3F4F6),
                            const Color(0xFF374151),
                          ),
                        ],
                      ),
                      if (hasSupplier || hasSupplierDoc) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          hasSupplier
                              ? 'Proveedor: ${row.supplierName}'
                              : 'Proveedor: -',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (hasSupplierDoc)
                          Text(
                            'Documento: ${row.supplierDoc}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
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

  Widget _chip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final EdgeInsets insets = MediaQuery.viewInsetsOf(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + insets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2B3444)
                      : const Color(0xFFE5E7EB),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Detalle de Compra',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                detail.summary.folio,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF4B5563),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(detail.summary.totalCents),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? const Color(0xFF7DD3FC)
                                : const Color(0xFF0C4A6E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _chip(
                          detail.summary.warehouseName,
                          const Color(0xFFEFF6FF),
                          const Color(0xFF1D4ED8),
                        ),
                        _chip(
                          '${detail.summary.linesCount} líneas',
                          const Color(0xFFF3F4F6),
                          const Color(0xFF374151),
                        ),
                        _chip(
                          dateShort(detail.summary.createdAt),
                          const Color(0xFFF3F4F6),
                          const Color(0xFF374151),
                        ),
                      ],
                    ),
                    if ((detail.note ?? '').trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          'Nota: ${detail.note}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: detail.lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final PurchaseDetailLineView line = detail.lines[index];
                  final bool noLotTrace = line.lotQtyIn <= 0.000001;
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF111827) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2B3444)
                            : const Color(0xFFE5E7EB),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  line.productName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                money(line.lineCostCents),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? const Color(0xFF7DD3FC)
                                      : const Color(0xFF0C4A6E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: ${line.sku}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF4B5563),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _chip(
                                'Cant. ${_qty(line.qty)}',
                                const Color(0xFFF8FAFC),
                                const Color(0xFF334155),
                              ),
                              _chip(
                                'Costo U. ${money(line.unitCostCents)}',
                                const Color(0xFFF8FAFC),
                                const Color(0xFF334155),
                              ),
                              _chip(
                                'Lote +${_qty(line.lotQtyIn)}',
                                const Color(0xFFDCFCE7),
                                const Color(0xFF166534),
                              ),
                              _chip(
                                'Consumido ${_qty(line.consumedQty)}',
                                const Color(0xFFFFEDD5),
                                const Color(0xFF9A3412),
                              ),
                              _chip(
                                'Restante ${_qty(line.lotQtyRemaining)}',
                                const Color(0xFFE0F2FE),
                                const Color(0xFF0C4A6E),
                              ),
                            ],
                          ),
                          if (noLotTrace)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFED7AA),
                                  ),
                                ),
                                child: const Text(
                                  'Sin trazabilidad de lotes para esta línea (compra antigua o ajuste legado).',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9A3412),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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
