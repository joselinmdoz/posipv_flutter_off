import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/app_scaffold.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/reportes_local_datasource.dart';
import '../reportes_providers.dart';
import 'analytics_sale_detail_page.dart';
import 'manual_sale_entry_page.dart';

class AnalyticsSalesListPage extends ConsumerStatefulWidget {
  const AnalyticsSalesListPage({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.currencySymbol,
    this.title = 'Total de ventas',
    this.channel,
    this.terminalId,
    this.paymentMethodKey,
    this.dependentKey,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String currencySymbol;
  final String title;
  final String? channel;
  final String? terminalId;
  final String? paymentMethodKey;
  final String? dependentKey;

  @override
  ConsumerState<AnalyticsSalesListPage> createState() =>
      _AnalyticsSalesListPageState();
}

class _AnalyticsSalesListPageState
    extends ConsumerState<AnalyticsSalesListPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<SalesAnalyticsSaleStat> _sales = <SalesAnalyticsSaleStat>[];
  List<SalesAnalyticsProductOption> _productOptions =
      <SalesAnalyticsProductOption>[];
  bool _loading = true;
  bool _hasChanges = false;
  String _selectedChannel = 'all';
  String? _selectedWarehouse;
  String? _selectedCashier;
  String? _selectedProductId;
  late DateTime _fromDate;
  late DateTime _toDate;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedChannel = (widget.channel ?? 'all').trim().toLowerCase();
    if (_selectedChannel.isEmpty) {
      _selectedChannel = 'all';
    }
    _fromDate = _startOfDay(widget.fromDate);
    _toDate = _startOfDay(widget.toDate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final ReportesLocalDataSource ds =
          ref.read(reportesLocalDataSourceProvider);
      final String? channel = _effectiveChannelFilter();
      final Future<List<SalesAnalyticsSaleStat>> salesFuture =
          ds.listSalesForAnalyticsRange(
        fromDate: _fromDate,
        toDate: _toDate,
        limit: 1000,
        channel: channel,
        terminalId: widget.terminalId,
        paymentMethodKey: widget.paymentMethodKey,
        dependentKey: widget.dependentKey,
        productId: _selectedProductId,
      );
      final Future<List<SalesAnalyticsProductOption>> productsFuture =
          ds.listSalesProductOptionsForRange(
        fromDate: _fromDate,
        toDate: _toDate,
        channel: channel,
        terminalId: widget.terminalId,
        paymentMethodKey: widget.paymentMethodKey,
        dependentKey: widget.dependentKey,
      );
      final List<dynamic> loaded = await Future.wait<dynamic>(<Future<dynamic>>[
        salesFuture,
        productsFuture,
      ]);
      final List<SalesAnalyticsSaleStat> rows =
          loaded[0] as List<SalesAnalyticsSaleStat>;
      final List<SalesAnalyticsProductOption> products =
          loaded[1] as List<SalesAnalyticsProductOption>;
      if (!mounted) {
        return;
      }
      setState(() {
        _sales = rows;
        _productOptions = products;
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
          SnackBar(content: Text('No se pudo cargar ventas: $e')),
        );
    }
  }

  String _money(int cents) {
    return '${widget.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  DateTime _startOfDay(DateTime value) {
    final DateTime local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String? _effectiveChannelFilter() {
    final String clean = _selectedChannel.trim().toLowerCase();
    if (clean == 'all') {
      return null;
    }
    return clean;
  }

  String _formatDateOnly(DateTime date) {
    final DateTime local = date.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    return '$day/$month/$year';
  }

  List<String> _warehouseOptions() {
    final Set<String> values = _sales
        .map((SalesAnalyticsSaleStat row) => row.warehouseName.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
    final List<String> result = values.toList()..sort();
    return result;
  }

  List<String> _cashierOptions() {
    final Set<String> values = _sales
        .map((SalesAnalyticsSaleStat row) => row.cashierUsername.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
    final List<String> result = values.toList()..sort();
    return result;
  }

  String _selectedProductLabel() {
    final String id = (_selectedProductId ?? '').trim();
    if (id.isEmpty) {
      return 'Producto';
    }
    for (final SalesAnalyticsProductOption row in _productOptions) {
      if (row.productId == id) {
        return '${row.productName} • ${row.sku}';
      }
    }
    return 'Producto $id';
  }

  bool get _isChannelLocked => (widget.channel ?? '').trim().isNotEmpty;

  bool _isSameDay(DateTime a, DateTime b) {
    final DateTime aa = _startOfDay(a);
    final DateTime bb = _startOfDay(b);
    return aa.year == bb.year && aa.month == bb.month && aa.day == bb.day;
  }

  List<SalesAnalyticsSaleStat> _filteredSales() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    return _sales.where((SalesAnalyticsSaleStat sale) {
      if (_selectedWarehouse != null &&
          sale.warehouseName.trim() != _selectedWarehouse) {
        return false;
      }
      if (_selectedCashier != null &&
          sale.cashierUsername.trim() != _selectedCashier) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final List<String> values = <String>[
        sale.folio,
        sale.warehouseName,
        sale.cashierUsername,
        sale.customerName ?? '',
        sale.terminalName ?? '',
        _dateTime(sale.createdAt),
      ];
      return values.any((String value) => value.toLowerCase().contains(query));
    }).toList(growable: false);
  }

  bool get _hasAppliedFilters {
    final bool rangeChanged = !_isSameDay(_fromDate, widget.fromDate) ||
        !_isSameDay(_toDate, widget.toDate);
    final bool channelChanged = !_isChannelLocked && _selectedChannel != 'all';
    return rangeChanged ||
        channelChanged ||
        _selectedWarehouse != null ||
        _selectedCashier != null ||
        _selectedProductId != null;
  }

  Future<void> _clearFilters() async {
    setState(() {
      _fromDate = _startOfDay(widget.fromDate);
      _toDate = _startOfDay(widget.toDate);
      _selectedChannel = _isChannelLocked
          ? (widget.channel ?? 'all').trim().toLowerCase()
          : 'all';
      _selectedWarehouse = null;
      _selectedCashier = null;
      _selectedProductId = null;
      _searchCtrl.clear();
    });
    await _load();
  }

  Future<void> _openQuickFilters() async {
    DateTime draftFrom = _fromDate;
    DateTime draftTo = _toDate;
    String draftChannel = _selectedChannel;
    String? draftWarehouse = _selectedWarehouse;
    String? draftCashier = _selectedCashier;
    String? draftProduct = _selectedProductId;
    final List<String> warehouseOptions = _warehouseOptions();
    final List<String> cashierOptions = _cashierOptions();
    final List<SalesAnalyticsProductOption> productOptions = _productOptions;

    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Filtros rápidos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!_isChannelLocked) ...<Widget>[
                        DropdownButtonFormField<String>(
                          initialValue: draftChannel,
                          decoration: const InputDecoration(
                              labelText: 'Canal de venta'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'all',
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'pos',
                              child: Text('POS'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'directa',
                              child: Text('Directa'),
                            ),
                          ],
                          onChanged: (String? value) {
                            if (value == null) {
                              return;
                            }
                            setModalState(() => draftChannel = value);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      DropdownButtonFormField<String?>(
                        initialValue: draftWarehouse,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Almacén'),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...warehouseOptions.map(
                            (String value) => DropdownMenuItem<String?>(
                              value: value,
                              child: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setModalState(() => draftWarehouse = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: draftCashier,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Dependiente'),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...cashierOptions.map(
                            (String value) => DropdownMenuItem<String?>(
                              value: value,
                              child: Text(
                                value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setModalState(() => draftCashier = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String?>(
                        initialValue: draftProduct,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'Producto'),
                        items: <DropdownMenuItem<String?>>[
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...productOptions.map(
                            (SalesAnalyticsProductOption row) =>
                                DropdownMenuItem<String?>(
                              value: row.productId,
                              child: Text(
                                '${row.productName} • ${row.sku}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          setModalState(() => draftProduct = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: draftFrom,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  helpText: 'Desde',
                                );
                                if (picked == null || !context.mounted) {
                                  return;
                                }
                                setModalState(() {
                                  draftFrom = _startOfDay(picked);
                                  if (draftTo.isBefore(draftFrom)) {
                                    draftTo = draftFrom;
                                  }
                                });
                              },
                              icon: const Icon(Icons.date_range_rounded),
                              label: Text(_formatDateOnly(draftFrom)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: draftTo,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  helpText: 'Hasta',
                                );
                                if (picked == null || !context.mounted) {
                                  return;
                                }
                                setModalState(() {
                                  draftTo = _startOfDay(picked);
                                  if (draftFrom.isAfter(draftTo)) {
                                    draftFrom = draftTo;
                                  }
                                });
                              },
                              icon: const Icon(Icons.event_rounded),
                              label: Text(_formatDateOnly(draftTo)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setModalState(() {
                              draftFrom = _startOfDay(widget.fromDate);
                              draftTo = _startOfDay(widget.toDate);
                              draftChannel = _isChannelLocked
                                  ? (widget.channel ?? 'all')
                                  : 'all';
                              draftWarehouse = null;
                              draftCashier = null;
                              draftProduct = null;
                            });
                          },
                          child: const Text('Restablecer filtros'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Aplicar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }

    final bool shouldReload = !_isSameDay(_fromDate, draftFrom) ||
        !_isSameDay(_toDate, draftTo) ||
        (_selectedChannel != draftChannel) ||
        (_selectedProductId != draftProduct);

    setState(() {
      _fromDate = draftFrom;
      _toDate = draftTo;
      _selectedChannel = draftChannel;
      _selectedWarehouse = draftWarehouse;
      _selectedCashier = draftCashier;
      _selectedProductId = draftProduct;
    });

    if (shouldReload) {
      await _load();
    }
  }

  String _dateTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString();
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Future<void> _openDetail(SalesAnalyticsSaleStat sale) async {
    final bool? result = await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AnalyticsSaleDetailPage(
          saleId: sale.saleId,
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
    if (result == true) {
      _hasChanges = true;
      await _load();
    }
  }

  Future<void> _openManualSaleEntry() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualSaleEntryPage(
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
    if (created == true) {
      _hasChanges = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Colores basados en el HTML
    const Color primaryNavy = Color(0xFF1E3A8A); // primary
    const Color accentBlue = Color(0xFF3B82F6); // accent
    final Color backgroundPage = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAF4); // slate-900 / slate-50
    final Color cardBg = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFFFFFFF); // slate-800 / white
    final Color borderCol = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0); // slate-700 / slate-200
    final Color textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B); // slate-400 / slate-500

    final session = ref.watch(currentSessionProvider);
    final bool canCreateManualSales = session?.isAdmin ?? false;
    final List<SalesAnalyticsSaleStat> visibleSales = _filteredSales();

    return AppScaffold(
      title: widget.title,
      currentRoute: '/reportes',
      showDrawer: false,
      onRefresh: _load,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(_hasChanges);
            return;
          }
          context.go('/reportes');
        },
        icon: Icon(Icons.arrow_back_rounded,
            color: isDark ? Colors.white : Colors.black87),
      ),
      appBarActions: <Widget>[
        if (canCreateManualSales)
          IconButton(
            tooltip: 'Venta manual histórica',
            onPressed: _openManualSaleEntry,
            icon: const Icon(Icons.history_toggle_off_rounded),
          ),
        IconButton(
          tooltip: 'Filtros',
          onPressed: _openQuickFilters,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF6D4BB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/ventas-pos'),
        backgroundColor: primaryNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      body: Container(
        color: backgroundPage,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : visibleSales.isEmpty
                ? const Center(child: Text('No hay ventas en este período.'))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: <Widget>[
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar por folio, cliente o dependiente',
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 22),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        if (_hasAppliedFilters)
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      if (!_isSameDay(
                                          _fromDate, widget.fromDate))
                                        Chip(
                                          label: Text(
                                              'Desde ${_formatDateOnly(_fromDate)}'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (!_isSameDay(_toDate, widget.toDate))
                                        Chip(
                                          label: Text(
                                              'Hasta ${_formatDateOnly(_toDate)}'),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (!_isChannelLocked &&
                                          _selectedChannel != 'all')
                                        Chip(
                                          label: Text(
                                            _selectedChannel == 'pos'
                                                ? 'Canal POS'
                                                : 'Canal Directa',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (_selectedWarehouse != null)
                                        Chip(
                                          label: Text(_selectedWarehouse!),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (_selectedCashier != null)
                                        Chip(
                                          label: Text(_selectedCashier!),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      if (_selectedProductId != null)
                                        Chip(
                                          label: Text(_selectedProductLabel()),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Limpiar filtros',
                                  onPressed: () => _clearFilters(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                        if (_hasAppliedFilters) const SizedBox(height: 12),
                        ...List<Widget>.generate(visibleSales.length,
                            (int index) {
                          final SalesAnalyticsSaleStat sale =
                              visibleSales[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleSales.length - 1 ? 0 : 16,
                            ),
                            child: _buildSaleCard(
                              context,
                              sale,
                              isDark,
                              primaryNavy,
                              accentBlue,
                              cardBg,
                              borderCol,
                              textMuted,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSaleCard(
    BuildContext context,
    SalesAnalyticsSaleStat sale,
    bool isDark,
    Color primaryNavy,
    Color accentBlue,
    Color cardBg,
    Color borderCol,
    Color textMuted,
  ) {
    final String channelLabel =
        sale.channel.trim().toLowerCase() == 'directa' ? 'DIRECTA' : 'POS';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openDetail(sale),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderCol),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Row 1: Folio and Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.folio,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? accentBlue : primaryNavy,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateTime(sale.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: channelLabel == 'POS'
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFFDE68A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: channelLabel == 'POS'
                            ? const Color(0xFFBFDBFE)
                            : const Color(0xFFFCD34D),
                      ),
                    ),
                    child: Text(
                      channelLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: channelLabel == 'POS'
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFF92400E),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Field Info
              _buildInfoRow(
                  'Dependiente:', sale.cashierUsername, textMuted, isDark),
              const SizedBox(height: 4),
              _buildInfoRow('Almacén:', sale.warehouseName, textMuted, isDark),
              const SizedBox(height: 4),
              _buildInfoRow(
                'Cliente:',
                sale.customerName ?? 'Sin cliente',
                textMuted,
                isDark,
                italic: sale.customerName == null,
              ),
              if ((sale.terminalName ?? '').trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                _buildInfoRow(
                  'TPV:',
                  sale.terminalName!.trim(),
                  textMuted,
                  isDark,
                ),
              ],
              const SizedBox(height: 16),
              // Footer
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${sale.itemsCount} líneas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                    Text(
                      _money(sale.totalCents),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textMuted, bool isDark,
      {bool italic = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: italic
                  ? textMuted.withValues(alpha: 0.7)
                  : (isDark ? Colors.white : Colors.black87),
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
