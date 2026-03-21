import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../configuracion/presentation/configuracion_providers.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../ventas_pos/presentation/widgets/pos_inventory_movement_dialog.dart';
import '../data/inventario_local_datasource.dart';
import 'inventario_providers.dart';
import 'widgets/inventory_movement_card.dart';
import 'widgets/inventory_movement_type_tabs.dart';

class MovimientosInventarioPage extends ConsumerStatefulWidget {
  const MovimientosInventarioPage({super.key});

  @override
  ConsumerState<MovimientosInventarioPage> createState() =>
      _MovimientosInventarioPageState();
}

class _MovimientosInventarioPageState
    extends ConsumerState<MovimientosInventarioPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  List<Warehouse> _warehouses = <Warehouse>[];
  List<InventoryMovementReason> _reasons = <InventoryMovementReason>[];
  List<InventoryMovementView> _movements = <InventoryMovementView>[];

  String? _selectedWarehouseId;
  String _selectedType = 'all';
  String _selectedReasonCode = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final PerfTrace trace = PerfTrace('movimientos.bootstrap');
    setState(() => _loading = true);
    try {
      final Future<List<Warehouse>> warehousesFuture =
          ref.read(almacenesLocalDataSourceProvider).listActiveWarehouses();
      final Future<List<InventoryMovementReason>> reasonsFuture =
          ref.read(inventarioLocalDataSourceProvider).listMovementReasons();

      final List<Warehouse> warehouses = await warehousesFuture;
      final List<InventoryMovementReason> reasons = await reasonsFuture;
      trace.mark('catalogos cargados');
      final String selectedReason = _selectedReasonCode == 'all' ||
              reasons.any((InventoryMovementReason row) {
                return row.code == _selectedReasonCode;
              })
          ? _selectedReasonCode
          : 'all';
      final List<InventoryMovementView> movements = await _fetchMovements(
        selectedReasonCode: selectedReason,
      );
      trace.mark('movimientos cargados');
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _reasons = reasons;
        _selectedReasonCode = selectedReason;
        _movements = movements;
        _loading = false;
      });
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      trace.end('error');
      _show('No se pudieron cargar movimientos: $e');
    }
  }

  Future<void> _reloadMovements() async {
    final List<InventoryMovementView> movements = await _fetchMovements();
    if (!mounted) {
      return;
    }
    setState(() {
      _movements = movements;
    });
  }

  Future<List<InventoryMovementView>> _fetchMovements({
    String? selectedReasonCode,
  }) async {
    final String reasonCode = selectedReasonCode ?? _selectedReasonCode;
    final String queryType = _selectedType == 'adjust' ? 'all' : _selectedType;
    final List<InventoryMovementView> rows =
        await ref.read(inventarioLocalDataSourceProvider).listMovements(
              warehouseId: _selectedWarehouseId,
              movementType: queryType,
              reasonCode: reasonCode,
            );
    if (_selectedType != 'adjust') {
      return rows;
    }
    return rows
        .where(
            (InventoryMovementView movement) => _isAdjustmentMovement(movement))
        .toList(growable: false);
  }

  Future<void> _openMovementForm() async {
    final UserSession? session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (_warehouses.isEmpty) {
      _show('No hay almacenes disponibles.');
      return;
    }

    final InventarioLocalDataSource ds =
        ref.read(inventarioLocalDataSourceProvider);
    final String selectedWarehouseId =
        _selectedWarehouseId ?? _warehouses.first.id;

    final List<InventoryView> adjustRows = await ds.listInventoryPage(
      warehouseId: selectedWarehouseId,
      limit: 5000,
      offset: 0,
    );
    if (adjustRows.isEmpty) {
      _show('No hay productos activos en este almacén.');
      return;
    }

    final List<InventoryMovementReason> entryReasons =
        await ds.listManualMovementReasons(movementType: 'in');
    final List<InventoryMovementReason> outputReasons =
        await ds.listManualMovementReasons(movementType: 'out');
    if (entryReasons.isEmpty && outputReasons.isEmpty) {
      _show('No hay motivos disponibles para registrar movimientos.');
      return;
    }

    if (!mounted) {
      return;
    }

    final config = ref.read(currentAppConfigProvider);
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return PosInventoryMovementDialog(
          adjustRows: adjustRows,
          entryReasons: entryReasons,
          outputReasons: outputReasons,
          currencySymbol: config.currencySymbol,
          warehouseOptions: _warehouses
              .map(
                (Warehouse row) => InventoryMovementWarehouseOption(
                  id: row.id,
                  name: row.name,
                ),
              )
              .toList(),
          initialWarehouseId: selectedWarehouseId,
          loadAdjustRowsForWarehouse: (String warehouseId) {
            return ds.listInventoryPage(
              warehouseId: warehouseId,
              limit: 5000,
              offset: 0,
            );
          },
          priceLabelBuilder: (InventoryView row) {
            final String currencyCode = row.currencyCode.trim().toUpperCase();
            return '$currencyCode ${(row.priceCents / 100).toStringAsFixed(2)}';
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final String safeProductId = result['productId'] as String;
    final bool isEntry = result['isEntry'] as bool;
    final double qty = result['qty'] as double;
    final String safeReasonCode = result['reasonCode'] as String;
    final String note = (result['note'] as String).trim();
    final String safeWarehouseId =
        ((result['warehouseId'] as String?) ?? selectedWarehouseId).trim();
    final double currentQty = (result['currentStock'] as double?) ?? 0;

    if (!isEntry && qty > currentQty) {
      _show('La salida supera el stock disponible.');
      return;
    }

    try {
      await ds.createManualMovement(
        productId: safeProductId,
        warehouseId: safeWarehouseId,
        type: isEntry ? 'in' : 'out',
        qty: qty,
        reasonCode: safeReasonCode,
        userId: session.userId,
        note: note.isEmpty
            ? (isEntry
                ? 'Entrada manual inventario'
                : 'Salida manual inventario')
            : note,
      );
      if (mounted) {
        setState(() => _selectedWarehouseId = safeWarehouseId);
      }
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _bootstrap();
      _show('Movimiento registrado.');
    } catch (e) {
      _show('No se pudo registrar movimiento: $e');
    }
  }

  Future<void> _openReasonsManager() async {
    final InventarioLocalDataSource ds =
        ref.read(inventarioLocalDataSourceProvider);
    List<InventoryMovementReason> reasons = await ds.listMovementReasons();
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            Future<void> refreshReasons() async {
              final List<InventoryMovementReason> updated =
                  await ds.listMovementReasons();
              if (!context.mounted) {
                return;
              }
              setStateDialog(() {
                reasons = updated;
              });
            }

            return AlertDialog(
              title: Row(
                children: <Widget>[
                  const Expanded(child: Text('Motivos de movimiento')),
                  IconButton(
                    tooltip: 'Agregar',
                    onPressed: () async {
                      final bool saved = await _openReasonEditor();
                      if (!saved) {
                        return;
                      }
                      await refreshReasons();
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView.separated(
                    key: const PageStorageKey<String>(
                      'inventario-reasons-list',
                    ),
                    itemCount: reasons.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, int index) {
                      final InventoryMovementReason reason = reasons[index];
                      return KeyedSubtree(
                        key: ValueKey<String>(reason.code),
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(reason.label),
                          subtitle: Text(
                            '${reason.code} • ${_appliesToLabel(reason.appliesTo)}',
                          ),
                          trailing: reason.isSystem
                              ? const Icon(Icons.lock_outline_rounded, size: 18)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    IconButton(
                                      tooltip: 'Editar',
                                      onPressed: () async {
                                        final bool saved =
                                            await _openReasonEditor(
                                          reason: reason,
                                        );
                                        if (!saved) {
                                          return;
                                        }
                                        await refreshReasons();
                                      },
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      onPressed: () async {
                                        final bool? confirm =
                                            await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Eliminar motivo'),
                                              content: Text(
                                                'Se eliminara "${reason.label}".',
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text('Cancelar'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text('Eliminar'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (confirm != true) {
                                          return;
                                        }
                                        try {
                                          await ds.deleteMovementReason(
                                            reason.code,
                                          );
                                          await refreshReasons();
                                        } catch (e) {
                                          if (!mounted) {
                                            return;
                                          }
                                          _show('No se pudo eliminar: $e');
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );

    await _bootstrap();
  }

  Future<void> _openQuickFilters() async {
    String? draftWarehouse = _selectedWarehouseId;
    String draftReason = _selectedReasonCode;
    final license = ref.read(currentLicenseStatusProvider);

    final bool? apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String?>(
                      initialValue: draftWarehouse,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Almacén'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ..._warehouses.map(
                          (Warehouse w) => DropdownMenuItem<String?>(
                            value: w.id,
                            child: Text(
                              w.name,
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
                    DropdownButtonFormField<String>(
                      initialValue: draftReason,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                      items: <DropdownMenuItem<String>>[
                        const DropdownMenuItem<String>(
                          value: 'all',
                          child: Text('Todos'),
                        ),
                        ..._reasons.map(
                          (InventoryMovementReason row) =>
                              DropdownMenuItem<String>(
                            value: row.code,
                            child: Text(row.label),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() => draftReason = value);
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 6),
                    if (license.canWrite)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop(false);
                            await _openReasonsManager();
                          },
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Gestionar motivos'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }

    setState(() {
      _selectedWarehouseId = draftWarehouse;
      _selectedReasonCode = draftReason;
    });
    await _reloadMovements();
  }

  Future<bool> _openReasonEditor({InventoryMovementReason? reason}) async {
    final bool isEdit = reason != null;
    String labelText = reason?.label ?? '';
    String appliesTo = reason?.appliesTo ?? 'both';
    bool saved = false;
    final InventarioLocalDataSource ds =
        ref.read(inventarioLocalDataSourceProvider);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Editar motivo' : 'Nuevo motivo'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      initialValue: labelText,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                      onChanged: (String value) => labelText = value,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: appliesTo,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Aplica para'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                          value: 'both',
                          child: Text('Entrada y salida'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'in',
                          child: Text('Solo entrada'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'out',
                          child: Text('Solo salida'),
                        ),
                      ],
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        setStateDialog(() => appliesTo = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    try {
                      if (isEdit) {
                        await ds.updateMovementReason(
                          code: reason.code,
                          label: labelText,
                          appliesTo: appliesTo,
                        );
                      } else {
                        await ds.createMovementReason(
                          label: labelText,
                          appliesTo: appliesTo,
                        );
                      }
                      saved = true;
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(content: Text('No se pudo guardar: $e')),
                        );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    return saved;
  }

  String _appliesToLabel(String appliesTo) {
    switch (appliesTo) {
      case 'in':
        return 'Solo entrada';
      case 'out':
        return 'Solo salida';
      default:
        return 'Entrada y salida';
    }
  }

  String _formatDateTime(DateTime date) {
    final DateTime local = date.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    final String hh = local.hour.toString().padLeft(2, '0');
    final String mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatDateGroup(DateTime date) {
    const List<String> monthShort = <String>[
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    final DateTime local = date.toLocal();
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime movementDay = DateTime(local.year, local.month, local.day);
    if (movementDay == today) {
      return 'HOY — ${local.day} ${monthShort[local.month - 1]}';
    }
    if (movementDay == today.subtract(const Duration(days: 1))) {
      return 'AYER — ${local.day} ${monthShort[local.month - 1]}';
    }
    return '${local.day} ${monthShort[local.month - 1]} ${local.year}';
  }

  String _formatTimeShort(DateTime date) {
    final DateTime local = date.toLocal();
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String mm = local.minute.toString().padLeft(2, '0');
    final String period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$mm $period';
  }

  bool _isAdjustmentMovement(InventoryMovementView movement) {
    final String reason = movement.reasonCode.toLowerCase();
    if (reason == 'adjust' || reason == 'breakage' || reason == 'shrinkage') {
      return true;
    }
    if (reason == 'sale' || reason == 'purchase') {
      return false;
    }
    return movement.movementSource == 'manual';
  }

  bool _matchesSearch(InventoryMovementView movement, String query) {
    if (query.isEmpty) {
      return true;
    }
    final String q = query.toLowerCase();
    return movement.productName.toLowerCase().contains(q) ||
        movement.sku.toLowerCase().contains(q) ||
        movement.warehouseName.toLowerCase().contains(q) ||
        _formatDateTime(movement.createdAt).toLowerCase().contains(q) ||
        movement.reasonLabel.toLowerCase().contains(q);
  }

  List<_MovementDateGroup> _groupByDate(List<InventoryMovementView> rows) {
    final Map<String, List<InventoryMovementView>> grouped =
        <String, List<InventoryMovementView>>{};
    final Map<String, DateTime> dateByKey = <String, DateTime>{};
    for (final InventoryMovementView row in rows) {
      final DateTime local = row.createdAt.toLocal();
      final String key =
          '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => <InventoryMovementView>[]).add(row);
      dateByKey[key] = DateTime(local.year, local.month, local.day);
    }
    final List<String> orderedKeys = grouped.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));
    final List<_MovementDateGroup> result = <_MovementDateGroup>[];
    for (final String key in orderedKeys) {
      final DateTime? day = dateByKey[key];
      final List<InventoryMovementView>? items = grouped[key];
      if (day == null || items == null || items.isEmpty) {
        continue;
      }
      result.add(
        _MovementDateGroup(
          date: day,
          items: items,
        ),
      );
    }
    return result;
  }

  Future<void> _onTypeChanged(String value) async {
    if (_selectedType == value) {
      return;
    }
    setState(() => _selectedType = value);
    await _reloadMovements();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<Widget> _buildGroupedMovementWidgets(List<_MovementDateGroup> groups) {
    final List<Widget> widgets = <Widget>[];
    for (final _MovementDateGroup group in groups) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          child: Text(
            _formatDateGroup(group.date),
            style: const TextStyle(
              letterSpacing: 1.0,
              fontSize: 34 / 2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF374151),
            ),
          ),
        ),
      );
      for (final InventoryMovementView movement in group.items) {
        widgets.add(
          InventoryMovementCard(
            movement: movement,
            timeLabel: _formatTimeShort(movement.createdAt),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String query = _searchCtrl.text.trim().toLowerCase();
    final List<InventoryMovementView> filteredMovements = query.isEmpty
        ? _movements
        : _movements.where((InventoryMovementView movement) {
            return _matchesSearch(movement, query);
          }).toList();
    final List<_MovementDateGroup> groups = _groupByDate(filteredMovements);
    final license = ref.watch(currentLicenseStatusProvider);

    return AppScaffold(
      title: 'Inventario',
      currentRoute: '/inventario-movimientos',
      onRefresh: _bootstrap,
      showTopTabs: false,
      useDefaultActions: false,
      showDrawer: true,
      appBarActions: <Widget>[
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
      floatingActionButton: license.canWrite
          ? AppAddActionButton(
              currentRoute: '/inventario-movimientos',
              onPressed: _openMovementForm,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _reloadMovements,
              child: ListView(
                key:
                    const PageStorageKey<String>('inventario-movimientos-list'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 92),
                children: <Widget>[
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar movimientos, SKU o productos...',
                      hintStyle: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF6B7280),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF4B5563),
                        size: 28,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFE5E7EB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF93C5FD),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  InventoryMovementTypeTabs(
                    selectedType: _selectedType,
                    onChanged: (String value) {
                      unawaited(_onTypeChanged(value));
                    },
                  ),
                  const SizedBox(height: 14),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 120),
                      child: Center(
                        child: Text(
                          'Sin movimientos para mostrar.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._buildGroupedMovementWidgets(groups),
                ],
              ),
            ),
    );
  }
}

class _MovementDateGroup {
  const _MovementDateGroup({
    required this.date,
    required this.items,
  });

  final DateTime date;
  final List<InventoryMovementView> items;
}
