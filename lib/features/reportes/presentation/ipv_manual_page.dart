import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../data/reportes_local_datasource.dart';
import 'reportes_providers.dart';

class IpvManualPage extends ConsumerStatefulWidget {
  const IpvManualPage({super.key});

  @override
  ConsumerState<IpvManualPage> createState() => _IpvManualPageState();
}

class _IpvManualPageState extends ConsumerState<IpvManualPage> {
  bool _loading = true;
  bool _saving = false;
  bool _historyLoading = false;
  bool _exporting = false;
  bool _dirty = false;
  int _formSeed = 0;

  DateTime _reportDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  String _currencySymbol = r'$';
  bool _hasPreviousReport = false;
  String _reportId = '';

  final TextEditingController _noteCtrl = TextEditingController();
  final Map<String, TextEditingController> _paymentCtrls =
      <String, TextEditingController>{};

  List<ManualIpvEmployeeOption> _employeeOptions = <ManualIpvEmployeeOption>[];
  Set<String> _selectedEmployeeIds = <String>{};
  List<String> _paymentMethods = <String>[];
  Map<String, String> _paymentMethodLabelsByCode = <String, String>{};
  List<ManualIpvEditableLineStat> _lines = <ManualIpvEditableLineStat>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    for (final TextEditingController ctrl in _paymentCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  ReportesLocalDataSource get _ds => ref.read(reportesLocalDataSourceProvider);

  Future<void> _loadInitial() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final Future<List<AppPaymentMethodSetting>> paymentMethodsFuture = ref
          .read(configuracionLocalDataSourceProvider)
          .loadPaymentMethodSettings();
      final List<ManualIpvEmployeeOption> employees =
          await _ds.listManualIpvEmployeeOptions();
      List<AppPaymentMethodSetting> paymentSettings =
          const <AppPaymentMethodSetting>[];
      try {
        paymentSettings = await paymentMethodsFuture;
      } catch (_) {}
      if (!mounted) {
        return;
      }
      setState(() {
        _employeeOptions = employees;
        _paymentMethodLabelsByCode =
            buildPaymentMethodLabelMap(paymentSettings);
      });
      await _loadReportForDate(_reportDate, resetDirty: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar IPV manual: $e');
    }
  }

  Future<void> _loadReportForDate(
    DateTime date, {
    bool resetDirty = false,
  }) async {
    final session = ref.read(currentSessionProvider);
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final ManualIpvReportStat report = await _ds.loadOrCreateManualIpvReport(
        reportDate: date,
        userId: session?.userId,
      );
      if (!mounted) {
        return;
      }
      _reportDate = report.reportDate;
      _reportId = report.reportId;
      _currencySymbol = report.currencySymbol;
      _hasPreviousReport = report.hasPreviousReport;
      _selectedEmployeeIds = report.employeeIds.toSet();
      _paymentMethods = report.paymentMethods;
      _lines = report.lines.toList(growable: true)
        ..sort(
          (ManualIpvEditableLineStat a, ManualIpvEditableLineStat b) =>
              a.sortOrder.compareTo(b.sortOrder),
        );
      _noteCtrl.text = report.note;
      _syncPaymentControllers(report.paymentTotalsByMethod);
      setState(() {
        _loading = false;
        _dirty = resetDirty ? false : _dirty;
        _formSeed += 1;
      });
      if (resetDirty) {
        setState(() => _dirty = false);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar el IPV manual: $e');
    }
  }

  void _syncPaymentControllers(Map<String, int> totalsByMethod) {
    final Set<String> methodSet = _paymentMethods.toSet();
    final List<String> stale = _paymentCtrls.keys
        .where((String key) => !methodSet.contains(key))
        .toList(growable: false);
    for (final String key in stale) {
      _paymentCtrls.remove(key)?.dispose();
    }
    for (final String method in _paymentMethods) {
      final TextEditingController ctrl =
          _paymentCtrls.putIfAbsent(method, TextEditingController.new);
      final int cents = totalsByMethod[method] ?? 0;
      ctrl.text = (cents / 100).toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    if (!await _confirmDiscardIfDirty()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reportDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Fecha IPV manual',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null) {
      return;
    }
    final DateTime normalized = DateTime(picked.year, picked.month, picked.day);
    await _loadReportForDate(normalized, resetDirty: true);
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_dirty) {
      return true;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cambios sin guardar'),
          content: const Text(
            'Hay cambios pendientes. Si continúas se perderán. ¿Deseas continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
    return confirm == true;
  }

  Future<void> _pickEmployees() async {
    final Set<String> current = _selectedEmployeeIds.toSet();
    final Set<String>? selected = await showDialog<Set<String>>(
      context: context,
      builder: (BuildContext context) {
        final Set<String> temp = current.toSet();
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setD) {
            return AlertDialog(
              title: const Text('Empleados del IPV'),
              content: SizedBox(
                width: 420,
                child: _employeeOptions.isEmpty
                    ? const Text('No hay empleados activos.')
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _employeeOptions.map((row) {
                            final bool selected = temp.contains(row.id);
                            return CheckboxListTile(
                              dense: true,
                              value: selected,
                              contentPadding: EdgeInsets.zero,
                              title: Text(row.name),
                              onChanged: (bool? value) {
                                setD(() {
                                  if (value == true) {
                                    temp.add(row.id);
                                  } else {
                                    temp.remove(row.id);
                                  }
                                });
                              },
                            );
                          }).toList(growable: false),
                        ),
                      ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(temp),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null) {
      return;
    }
    setState(() {
      _selectedEmployeeIds = selected;
      _dirty = true;
    });
  }

  Future<void> _showAddProductMenu() async {
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Agregar desde productos activos'),
                onTap: () => Navigator.of(context).pop('catalog'),
              ),
              ListTile(
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Agregar producto manual'),
                onTap: () => Navigator.of(context).pop('manual'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == 'catalog') {
      await _addFromCatalog();
      return;
    }
    if (selected == 'manual') {
      await _addManualProduct();
    }
  }

  Future<void> _addFromCatalog() async {
    if (_reportId.trim().isEmpty) {
      _show('Primero carga el reporte manual.');
      return;
    }
    try {
      final List<ManualIpvProductOption> options =
          await _ds.listManualIpvAddableProducts(
        reportId: _reportId,
        reportDate: _reportDate,
      );
      if (!mounted) {
        return;
      }
      if (options.isEmpty) {
        _show('No hay productos activos disponibles para agregar.');
        return;
      }
      final ManualIpvProductOption? selected =
          await showDialog<ManualIpvProductOption>(
        context: context,
        builder: (BuildContext context) {
          String query = '';
          return StatefulBuilder(
            builder:
                (BuildContext context, void Function(void Function()) setD) {
              final List<ManualIpvProductOption> filtered =
                  options.where((row) {
                final String value = '${row.name} ${row.sku}'.toLowerCase();
                return value.contains(query.trim().toLowerCase());
              }).toList(growable: false);
              return AlertDialog(
                title: const Text('Agregar producto activo'),
                content: SizedBox(
                  width: 540,
                  height: 420,
                  child: Column(
                    children: <Widget>[
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Buscar por nombre o código',
                        ),
                        onChanged: (String value) {
                          setD(() => query = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text('No hay coincidencias.'),
                              )
                            : ListView.separated(
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final ManualIpvProductOption row =
                                      filtered[index];
                                  return ListTile(
                                    title: Text(row.name),
                                    subtitle: Text('Código: ${row.sku}'),
                                    trailing: Text(
                                      '$_currencySymbol${(row.priceCents / 100).toStringAsFixed(2)}',
                                    ),
                                    onTap: () => Navigator.of(context).pop(row),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text('Cancelar'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (selected == null) {
        return;
      }
      final bool exists = _lines.any((ManualIpvEditableLineStat row) =>
          row.productId == selected.productId);
      if (exists) {
        _show('Ese producto ya está en la tabla.');
        return;
      }
      final int nextSort = _nextSortOrder();
      final ManualIpvEditableLineStat line = _recalculateLocalLine(
        ManualIpvEditableLineStat(
          lineId: _tempLineId(),
          productId: selected.productId,
          isCustom: false,
          productName: selected.name,
          sku: selected.sku,
          startQty: selected.suggestedStartQty,
          entriesQty: 0,
          outputsQty: 0,
          salesQty: 0,
          finalQty: selected.suggestedStartQty,
          salePriceCents: selected.priceCents,
          unitCostCents: selected.costCents,
          totalAmountCents: 0,
          sortOrder: nextSort,
        ),
      );
      setState(() {
        _lines = <ManualIpvEditableLineStat>[..._lines, line];
        _dirty = true;
        _formSeed += 1;
      });
    } catch (e) {
      _show('No se pudo cargar productos activos: $e');
    }
  }

  Future<void> _addManualProduct() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController skuCtrl = TextEditingController();
    final TextEditingController startCtrl = TextEditingController(text: '0');
    final TextEditingController priceCtrl = TextEditingController(text: '0.00');
    final TextEditingController costCtrl = TextEditingController(text: '0.00');
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nuevo producto manual'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 430,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Producto *',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: startCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Inicio',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: costCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Costo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
    if (ok != true) {
      nameCtrl.dispose();
      skuCtrl.dispose();
      startCtrl.dispose();
      priceCtrl.dispose();
      costCtrl.dispose();
      return;
    }
    final String name = nameCtrl.text.trim();
    if (name.isEmpty) {
      _show('Debes indicar el nombre del producto.');
      nameCtrl.dispose();
      skuCtrl.dispose();
      startCtrl.dispose();
      priceCtrl.dispose();
      costCtrl.dispose();
      return;
    }
    final double startQty = _parseDouble(startCtrl.text) ?? 0;
    final int priceCents = _parseMoneyToCents(priceCtrl.text);
    final int costCents = _parseMoneyToCents(costCtrl.text);
    final ManualIpvEditableLineStat line = _recalculateLocalLine(
      ManualIpvEditableLineStat(
        lineId: _tempLineId(),
        productId: null,
        isCustom: true,
        productName: name,
        sku: skuCtrl.text.trim().isEmpty ? '-' : skuCtrl.text.trim(),
        startQty: startQty,
        entriesQty: 0,
        outputsQty: 0,
        salesQty: 0,
        finalQty: startQty,
        salePriceCents: priceCents,
        unitCostCents: costCents,
        totalAmountCents: 0,
        sortOrder: _nextSortOrder(),
      ),
    );
    setState(() {
      _lines = <ManualIpvEditableLineStat>[..._lines, line];
      _dirty = true;
      _formSeed += 1;
    });
    nameCtrl.dispose();
    skuCtrl.dispose();
    startCtrl.dispose();
    priceCtrl.dispose();
    costCtrl.dispose();
  }

  Future<void> _save() async {
    if (_saving || _loading) {
      return;
    }
    setState(() => _saving = true);
    try {
      final List<ManualIpvEditableLineStat> ordered =
          _lines.toList(growable: true)
            ..sort(
              (ManualIpvEditableLineStat a, ManualIpvEditableLineStat b) =>
                  a.sortOrder.compareTo(b.sortOrder),
            );
      final Map<String, int> paymentTotals = <String, int>{
        for (final String method in _paymentMethods)
          method: _parseMoneyToCents(_paymentCtrls[method]?.text ?? '0'),
      };
      final Map<String, String> employeeNameById = <String, String>{
        for (final ManualIpvEmployeeOption row in _employeeOptions)
          row.id: row.name,
      };
      final List<String> employeeNames = _selectedEmployeeIds
          .map((String id) => (employeeNameById[id] ?? '').trim())
          .where((String value) => value.isNotEmpty)
          .toList(growable: false);

      await _ds.saveManualIpvReport(
        reportId: _reportId,
        reportDate: _reportDate,
        currencySymbol: _currencySymbol,
        employeeIds: _selectedEmployeeIds.toList(growable: false),
        employeeNames: employeeNames,
        paymentTotalsByMethod: paymentTotals,
        note: _noteCtrl.text.trim(),
        lines: ordered,
      );
      if (!mounted) {
        return;
      }
      await _loadReportForDate(_reportDate, resetDirty: true);
      if (!mounted) {
        return;
      }
      _show('IPV manual guardado correctamente.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar el IPV manual: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _deleteCurrentReport() async {
    if (_reportId.trim().isEmpty || _saving || _loading) {
      return;
    }
    if (_dirty && !await _confirmDiscardIfDirty()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final String dateLabel =
            '${_reportDate.day.toString().padLeft(2, '0')}/${_reportDate.month.toString().padLeft(2, '0')}/${_reportDate.year}';
        return AlertDialog(
          title: const Text('Eliminar IPV manual'),
          content: Text(
            'Se eliminará el IPV manual del $dateLabel y luego se recalcularán los inicios de los reportes siguientes. Esta acción no se puede deshacer. ¿Deseas continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      final DateTime deletedDate = _reportDate;
      final String userId =
          (ref.read(currentSessionProvider)?.userId ?? '').trim();
      await _ds.deleteManualIpvReport(
        reportId: _reportId,
        requestedByUserId: userId,
      );
      await _ds.recalculateManualIpvStarts(
        fromDate: deletedDate,
        requestedByUserId: userId,
      );
      if (!mounted) {
        return;
      }
      await _loadReportForDate(deletedDate, resetDirty: true);
      if (!mounted) {
        return;
      }
      _show('IPV manual eliminado. Inicios recalculados.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo eliminar el IPV manual: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _recalculateStartsFromCurrentDate() async {
    if (_saving || _loading) {
      return;
    }
    if (_dirty && !await _confirmDiscardIfDirty()) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final String dateLabel =
            '${_reportDate.day.toString().padLeft(2, '0')}/${_reportDate.month.toString().padLeft(2, '0')}/${_reportDate.year}';
        return AlertDialog(
          title: const Text('Recalcular inicios'),
          content: Text(
            'Se recalcularán los inicios desde el IPV del $dateLabel en adelante usando el final del reporte anterior. ¿Deseas continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Recalcular'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    setState(() => _saving = true);
    try {
      final String userId =
          (ref.read(currentSessionProvider)?.userId ?? '').trim();
      await _ds.recalculateManualIpvStarts(
        fromDate: _reportDate,
        requestedByUserId: userId,
      );
      if (!mounted) {
        return;
      }
      await _loadReportForDate(_reportDate, resetDirty: true);
      if (!mounted) {
        return;
      }
      _show('Inicios recalculados correctamente.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo recalcular inicios: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _handleCurrentExportAction(_ManualIpvExportAction action) async {
    if (_reportId.trim().isEmpty) {
      _show('No hay IPV manual cargado para exportar.');
      return;
    }
    switch (action) {
      case _ManualIpvExportAction.exportCsv:
        await _exportManualReportById(
          reportId: _reportId,
          format: 'csv',
          shareFile: false,
        );
        break;
      case _ManualIpvExportAction.exportPdf:
        await _exportManualReportById(
          reportId: _reportId,
          format: 'pdf',
          shareFile: false,
        );
        break;
      case _ManualIpvExportAction.shareCsv:
        await _exportManualReportById(
          reportId: _reportId,
          format: 'csv',
          shareFile: true,
        );
        break;
      case _ManualIpvExportAction.sharePdf:
        await _exportManualReportById(
          reportId: _reportId,
          format: 'pdf',
          shareFile: true,
        );
        break;
    }
  }

  Future<void> _exportManualReportById({
    required String reportId,
    required String format,
    required bool shareFile,
  }) async {
    if (_exporting) {
      return;
    }
    setState(() => _exporting = true);
    try {
      final String path = format == 'pdf'
          ? await _ds.exportManualIpvReportPdf(
              reportId: reportId,
              currencySymbol: _currencySymbol,
            )
          : await _ds.exportManualIpvReportCsv(
              reportId: reportId,
              currencySymbol: _currencySymbol,
            );
      if (!mounted) {
        return;
      }
      if (shareFile) {
        await Share.shareXFiles(
          <XFile>[XFile(path)],
          text: 'IPV manual ${_formatShortDate(_reportDate)}',
          subject: 'IPV manual',
        );
        if (!mounted) {
          return;
        }
      }
      _show(
        shareFile
            ? 'IPV manual listo para compartir:\n$path'
            : 'IPV manual exportado en:\n$path',
      );
    } catch (e) {
      _show('No se pudo exportar IPV manual: $e');
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Future<void> _openHistory() async {
    if (_historyLoading) {
      return;
    }
    setState(() => _historyLoading = true);
    try {
      final List<ManualIpvHistoryStat> rows =
          await _ds.listManualIpvHistory(limit: 500);
      if (!mounted) {
        return;
      }
      setState(() => _historyLoading = false);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext context) {
          final bool isAdmin =
              ref.read(currentSessionProvider)?.isAdmin ?? false;
          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.92,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Historial IPV manual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${rows.length} reportes',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (rows.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No hay reportes manuales creados.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int index) {
                            final ManualIpvHistoryStat row = rows[index];
                            return _buildHistoryRow(
                              row: row,
                              isAdmin: isAdmin,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _historyLoading = false);
      _show('No se pudo cargar historial: $e');
    }
  }

  Widget _buildHistoryRow({
    required ManualIpvHistoryStat row,
    required bool isAdmin,
  }) {
    final String employees = row.employeeNames.isEmpty
        ? 'Sin empleados'
        : row.employeeNames.join(', ');
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        title: Text(
          '${_formatShortDate(row.reportDate)} • ${row.lineCount} líneas',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Importe ${_formatMoney(row.totalAmountCents)} • Ganancia ${_formatMoney(row.totalRealProfitCents)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Pagos ${_formatMoney(row.totalPaymentsCents)} • $employees',
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: PopupMenuButton<_ManualIpvHistoryAction>(
          onSelected: (_ManualIpvHistoryAction action) =>
              _handleHistoryAction(action: action, row: row, isAdmin: isAdmin),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<_ManualIpvHistoryAction>>[
              const PopupMenuItem<_ManualIpvHistoryAction>(
                value: _ManualIpvHistoryAction.open,
                child: Text('Abrir'),
              ),
              const PopupMenuItem<_ManualIpvHistoryAction>(
                value: _ManualIpvHistoryAction.exportCsv,
                child: Text('Exportar CSV'),
              ),
              const PopupMenuItem<_ManualIpvHistoryAction>(
                value: _ManualIpvHistoryAction.exportPdf,
                child: Text('Exportar PDF'),
              ),
              const PopupMenuItem<_ManualIpvHistoryAction>(
                value: _ManualIpvHistoryAction.shareCsv,
                child: Text('Compartir CSV'),
              ),
              const PopupMenuItem<_ManualIpvHistoryAction>(
                value: _ManualIpvHistoryAction.sharePdf,
                child: Text('Compartir PDF'),
              ),
              if (isAdmin) const PopupMenuDivider(),
              if (isAdmin)
                const PopupMenuItem<_ManualIpvHistoryAction>(
                  value: _ManualIpvHistoryAction.recalculateFrom,
                  child: Text('Recalcular desde aquí'),
                ),
              if (isAdmin)
                const PopupMenuItem<_ManualIpvHistoryAction>(
                  value: _ManualIpvHistoryAction.delete,
                  child: Text('Eliminar'),
                ),
            ];
          },
        ),
      ),
    );
  }

  Future<void> _handleHistoryAction({
    required _ManualIpvHistoryAction action,
    required ManualIpvHistoryStat row,
    required bool isAdmin,
  }) async {
    switch (action) {
      case _ManualIpvHistoryAction.open:
        if (_dirty && !await _confirmDiscardIfDirty()) {
          return;
        }
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop();
        await _loadReportForDate(row.reportDate, resetDirty: true);
        break;
      case _ManualIpvHistoryAction.exportCsv:
        await _exportManualReportById(
          reportId: row.reportId,
          format: 'csv',
          shareFile: false,
        );
        break;
      case _ManualIpvHistoryAction.exportPdf:
        await _exportManualReportById(
          reportId: row.reportId,
          format: 'pdf',
          shareFile: false,
        );
        break;
      case _ManualIpvHistoryAction.shareCsv:
        await _exportManualReportById(
          reportId: row.reportId,
          format: 'csv',
          shareFile: true,
        );
        break;
      case _ManualIpvHistoryAction.sharePdf:
        await _exportManualReportById(
          reportId: row.reportId,
          format: 'pdf',
          shareFile: true,
        );
        break;
      case _ManualIpvHistoryAction.recalculateFrom:
        if (!isAdmin) {
          _show('Solo administrador puede recalcular.');
          return;
        }
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Recalcular inicios'),
            content: Text(
              'Se recalcularán los inicios desde ${_formatShortDate(row.reportDate)} en adelante. ¿Continuar?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Recalcular'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          return;
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
        final String userId =
            (ref.read(currentSessionProvider)?.userId ?? '').trim();
        await _ds.recalculateManualIpvStarts(
          fromDate: row.reportDate,
          requestedByUserId: userId,
        );
        if (!mounted) {
          return;
        }
        _show(
            'Inicios recalculados desde ${_formatShortDate(row.reportDate)}.');
        break;
      case _ManualIpvHistoryAction.delete:
        if (!isAdmin) {
          _show('Solo administrador puede eliminar.');
          return;
        }
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar IPV manual'),
            content: Text(
              'Se eliminará el IPV del ${_formatShortDate(row.reportDate)} y se recalcularán inicios posteriores. ¿Continuar?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB91C1C),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          return;
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
        final String userId =
            (ref.read(currentSessionProvider)?.userId ?? '').trim();
        await _ds.deleteManualIpvReport(
          reportId: row.reportId,
          requestedByUserId: userId,
        );
        await _ds.recalculateManualIpvStarts(
          fromDate: row.reportDate,
          requestedByUserId: userId,
        );
        if (!mounted) {
          return;
        }
        _show('IPV manual eliminado y cadena recalculada.');
        break;
    }
  }

  ManualIpvEditableLineStat _recalculateLocalLine(
    ManualIpvEditableLineStat line,
  ) {
    final double finalQty =
        line.startQty + line.entriesQty - line.outputsQty - line.salesQty;
    final int amountCents = (line.salesQty * line.salePriceCents).round();
    return line.copyWith(
      finalQty: finalQty,
      totalAmountCents: amountCents,
    );
  }

  int _nextSortOrder() {
    if (_lines.isEmpty) {
      return 0;
    }
    int maxSort = _lines.first.sortOrder;
    for (final ManualIpvEditableLineStat row in _lines) {
      maxSort = math.max(maxSort, row.sortOrder);
    }
    return maxSort + 1;
  }

  void _updateLineField(
    ManualIpvEditableLineStat line,
    _LineField field,
    String raw,
  ) {
    final int index = _lines.indexWhere((ManualIpvEditableLineStat row) {
      return row.lineId == line.lineId;
    });
    if (index < 0) {
      return;
    }
    ManualIpvEditableLineStat next = _lines[index];
    switch (field) {
      case _LineField.start:
        final bool lockStart = _hasPreviousReport && next.productId != null;
        if (lockStart) {
          return;
        }
        next = next.copyWith(startQty: _parseDouble(raw) ?? 0);
        break;
      case _LineField.entries:
        next = next.copyWith(entriesQty: _parseDouble(raw) ?? 0);
        break;
      case _LineField.outputs:
        next = next.copyWith(outputsQty: _parseDouble(raw) ?? 0);
        break;
      case _LineField.sales:
        next = next.copyWith(salesQty: _parseDouble(raw) ?? 0);
        break;
      case _LineField.price:
        next = next.copyWith(salePriceCents: _parseMoneyToCents(raw));
        break;
    }
    next = _recalculateLocalLine(next);
    setState(() {
      _lines[index] = next;
      _dirty = true;
    });
  }

  void _removeLine(ManualIpvEditableLineStat line) {
    setState(() {
      _lines.removeWhere(
          (ManualIpvEditableLineStat row) => row.lineId == line.lineId);
      int sort = 0;
      _lines = _lines
          .map((ManualIpvEditableLineStat row) =>
              row.copyWith(sortOrder: sort++))
          .toList(growable: true);
      _dirty = true;
      _formSeed += 1;
    });
  }

  double? _parseDouble(String raw) {
    final String clean = raw.trim().replaceAll(',', '.');
    if (clean.isEmpty) {
      return 0;
    }
    final double? value = double.tryParse(clean);
    if (value == null || !value.isFinite) {
      return null;
    }
    return value;
  }

  int _parseMoneyToCents(String raw) {
    final double? value = _parseDouble(raw);
    if (value == null || value <= 0) {
      return 0;
    }
    return (value * 100).round();
  }

  String _formatQty(double value) {
    if ((value - value.roundToDouble()).abs() < 0.000001) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatMoney(int cents) {
    return '$_currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _formatShortDate(DateTime value) {
    final String d = value.day.toString().padLeft(2, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String y = value.year.toString();
    return '$d/$m/$y';
  }

  String _paymentMethodLabel(String method) {
    final String code = method.trim().toLowerCase();
    if (code.isEmpty) {
      return 'Metodo';
    }
    return _paymentMethodLabelsByCode[code] ?? defaultPaymentMethodLabel(code);
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(currentSessionProvider);
    final bool isAdmin = session?.isAdmin ?? false;
    return AppScaffold(
      title: 'IPV Manual',
      currentRoute: '/ipv-manual',
      onRefresh: _loadInitial,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInitial,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      children: <Widget>[
                        _buildTopCard(isAdmin),
                        const SizedBox(height: 8),
                        _buildPaymentsCard(),
                        const SizedBox(height: 8),
                        _buildLinesCard(isAdmin),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTopCard(bool isAdmin) {
    final List<String> selectedNames = _employeeOptions
        .where((ManualIpvEmployeeOption row) =>
            _selectedEmployeeIds.contains(row.id))
        .map((ManualIpvEmployeeOption row) => row.name)
        .toList(growable: false);
    final String employeesLabel = selectedNames.isEmpty
        ? 'Sin empleados seleccionados'
        : selectedNames.join(', ');
    final String dateLabel =
        '${_reportDate.day.toString().padLeft(2, '0')}/${_reportDate.month.toString().padLeft(2, '0')}/${_reportDate.year}';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text('Fecha: $dateLabel'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _historyLoading ? null : _openHistory,
                icon: _historyLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.history_rounded, size: 18),
                label: const Text('Historial'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEmployees,
                  icon: const Icon(Icons.group_rounded, size: 18),
                  label: const Text('Empleados'),
                ),
              ),
              const SizedBox(width: 8),
              if (_exporting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<_ManualIpvExportAction>(
                  tooltip: 'Exportar / compartir',
                  onSelected: _handleCurrentExportAction,
                  itemBuilder: (BuildContext context) =>
                      const <PopupMenuEntry<_ManualIpvExportAction>>[
                    PopupMenuItem<_ManualIpvExportAction>(
                      value: _ManualIpvExportAction.exportCsv,
                      child: Text('Exportar CSV'),
                    ),
                    PopupMenuItem<_ManualIpvExportAction>(
                      value: _ManualIpvExportAction.exportPdf,
                      child: Text('Exportar PDF'),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem<_ManualIpvExportAction>(
                      value: _ManualIpvExportAction.shareCsv,
                      child: Text('Compartir CSV'),
                    ),
                    PopupMenuItem<_ManualIpvExportAction>(
                      value: _ManualIpvExportAction.sharePdf,
                      child: Text('Compartir PDF'),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Icon(Icons.ios_share_rounded),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            employeesLabel,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              isDense: true,
            ),
            onChanged: (_) {
              setState(() => _dirty = true);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _showAddProductMenu,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar producto'),
              ),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_rounded),
                label: Text(_dirty ? 'Guardar cambios' : 'Guardar'),
              ),
              if (isAdmin)
                OutlinedButton.icon(
                  onPressed: _saving ? null : _recalculateStartsFromCurrentDate,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Recalcular inicios'),
                ),
              if (isAdmin)
                OutlinedButton.icon(
                  onPressed: _saving ? null : _deleteCurrentReport,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Eliminar IPV'),
                ),
              if (_hasPreviousReport)
                const Chip(
                  avatar: Icon(Icons.link_rounded, size: 16),
                  label: Text('Inicio enlazado al IPV anterior'),
                  side: BorderSide(color: Color(0xFFBFDBFE)),
                  backgroundColor: Color(0xFFEFF6FF),
                ),
              if (isAdmin)
                const Chip(
                  avatar: Icon(Icons.admin_panel_settings_rounded, size: 16),
                  label: Text('Vista administrador'),
                  backgroundColor: Color(0xFFF1F5F9),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Pagos manuales por método',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paymentMethods.map((String method) {
              final TextEditingController ctrl = _paymentCtrls.putIfAbsent(
                method,
                TextEditingController.new,
              );
              return SizedBox(
                width: 152,
                child: TextField(
                  controller: ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _paymentMethodLabel(method),
                    prefixText: _currencySymbol,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() => _dirty = true),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesCard(bool isAdmin) {
    int totalAmount = 0;
    int totalRealProfit = 0;
    for (final ManualIpvEditableLineStat line in _lines) {
      totalAmount += line.totalAmountCents;
      totalRealProfit += line.realProfitCents;
    }

    const double productWidth = 250;
    const double qtyWidth = 84;
    const double priceWidth = 100;
    const double amountWidth = 120;
    const double adminWidth = 120;
    final List<_TableColumnMeta> columns = <_TableColumnMeta>[
      const _TableColumnMeta('Producto / Código', productWidth),
      const _TableColumnMeta('Inicio', qtyWidth),
      const _TableColumnMeta('Entradas', qtyWidth),
      const _TableColumnMeta('Salidas', qtyWidth),
      const _TableColumnMeta('Ventas', qtyWidth),
      const _TableColumnMeta('Final', qtyWidth),
      const _TableColumnMeta('Precio', priceWidth),
      const _TableColumnMeta('Importe', amountWidth),
      if (isAdmin) const _TableColumnMeta('Ganancia x Prod.', adminWidth),
      if (isAdmin) const _TableColumnMeta('Ganancia Real', adminWidth),
    ];
    final double totalWidth = columns.fold<double>(
      0,
      (double sum, _TableColumnMeta col) => sum + col.width,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: totalWidth,
          child: Column(
            children: <Widget>[
              Container(
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: columns
                      .map(
                        (_TableColumnMeta col) => SizedBox(
                          width: col.width,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              col.label,
                              textAlign: col.label == 'Producto / Código'
                                  ? TextAlign.left
                                  : TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const Divider(height: 1),
              if (_lines.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No hay productos en el IPV manual.'),
                )
              else
                ..._lines.map(
                  (ManualIpvEditableLineStat line) =>
                      _buildLineRow(line, isAdmin),
                ),
              Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(14)),
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: productWidth,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'TOTAL',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: qtyWidth),
                    const SizedBox(width: qtyWidth),
                    const SizedBox(width: qtyWidth),
                    const SizedBox(width: qtyWidth),
                    const SizedBox(width: qtyWidth),
                    const SizedBox(width: priceWidth),
                    SizedBox(
                      width: amountWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          _formatMoney(totalAmount),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1152D4),
                          ),
                        ),
                      ),
                    ),
                    if (isAdmin) const SizedBox(width: adminWidth),
                    if (isAdmin)
                      SizedBox(
                        width: adminWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _formatMoney(totalRealProfit),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF15803D),
                            ),
                          ),
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

  Widget _buildLineRow(ManualIpvEditableLineStat line, bool isAdmin) {
    const double productWidth = 250;
    const double qtyWidth = 84;
    const double priceWidth = 100;
    const double amountWidth = 120;
    const double adminWidth = 120;
    final bool lockStart = _hasPreviousReport && line.productId != null;
    final Color rowBg = line.isCustom ? const Color(0xFFFFFBEB) : Colors.white;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: rowBg,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: productWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          line.productName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          line.sku,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (line.isCustom)
                    IconButton(
                      onPressed: () => _removeLine(line),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFB91C1C),
                      ),
                      tooltip: 'Eliminar línea',
                    ),
                ],
              ),
            ),
          ),
          _editableCell(
            width: qtyWidth,
            line: line,
            field: _LineField.start,
            value: _formatQty(line.startQty),
            readOnly: lockStart,
          ),
          _editableCell(
            width: qtyWidth,
            line: line,
            field: _LineField.entries,
            value: _formatQty(line.entriesQty),
          ),
          _editableCell(
            width: qtyWidth,
            line: line,
            field: _LineField.outputs,
            value: _formatQty(line.outputsQty),
          ),
          _editableCell(
            width: qtyWidth,
            line: line,
            field: _LineField.sales,
            value: _formatQty(line.salesQty),
          ),
          SizedBox(
            width: qtyWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatQty(line.finalQty),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          _editableCell(
            width: priceWidth,
            line: line,
            field: _LineField.price,
            value: (line.salePriceCents / 100).toStringAsFixed(2),
            isMoney: true,
          ),
          SizedBox(
            width: amountWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _formatMoney(line.totalAmountCents),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (isAdmin)
            SizedBox(
              width: adminWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatMoney(line.profitMarginCents),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: line.profitMarginCents >= 0
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (isAdmin)
            SizedBox(
              width: adminWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _formatMoney(line.realProfitCents),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: line.realProfitCents >= 0
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _editableCell({
    required double width,
    required ManualIpvEditableLineStat line,
    required _LineField field,
    required String value,
    bool readOnly = false,
    bool isMoney = false,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: TextFormField(
          key: ValueKey('${_formSeed}_${line.lineId}_${field.name}'),
          initialValue: value,
          textAlign: TextAlign.right,
          readOnly: readOnly,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            border: const OutlineInputBorder(),
            prefixText: isMoney ? _currencySymbol : null,
            fillColor: readOnly ? const Color(0xFFF1F5F9) : null,
            filled: readOnly,
          ),
          onChanged: readOnly
              ? null
              : (String raw) => _updateLineField(line, field, raw),
        ),
      ),
    );
  }
}

class _TableColumnMeta {
  const _TableColumnMeta(this.label, this.width);

  final String label;
  final double width;
}

enum _ManualIpvExportAction {
  exportCsv,
  exportPdf,
  shareCsv,
  sharePdf,
}

enum _ManualIpvHistoryAction {
  open,
  exportCsv,
  exportPdf,
  shareCsv,
  sharePdf,
  recalculateFrom,
  delete,
}

enum _LineField {
  start,
  entries,
  outputs,
  sales,
  price;
}

extension on _LineField {
  String get name {
    switch (this) {
      case _LineField.start:
        return 'start';
      case _LineField.entries:
        return 'entries';
      case _LineField.outputs:
        return 'outputs';
      case _LineField.sales:
        return 'sales';
      case _LineField.price:
        return 'price';
    }
  }
}

extension _TempId on _IpvManualPageState {
  String _tempLineId() {
    return 'tmp_${DateTime.now().microsecondsSinceEpoch}_${_lines.length}';
  }
}
