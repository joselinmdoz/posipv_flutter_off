import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class MovimientosInventarioPage extends ConsumerStatefulWidget {
  const MovimientosInventarioPage({super.key});

  @override
  ConsumerState<MovimientosInventarioPage> createState() =>
      _MovimientosInventarioPageState();
}

class _MovimientosInventarioPageState
    extends ConsumerState<MovimientosInventarioPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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
    _searchFocusNode.dispose();
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
      final List<InventoryMovementView> movements =
          await ref.read(inventarioLocalDataSourceProvider).listMovements(
                warehouseId: _selectedWarehouseId,
                movementType: _selectedType,
                reasonCode: selectedReason,
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
    final List<InventoryMovementView> movements =
        await ref.read(inventarioLocalDataSourceProvider).listMovements(
              warehouseId: _selectedWarehouseId,
              movementType: _selectedType,
              reasonCode: _selectedReasonCode,
            );
    if (!mounted) {
      return;
    }
    setState(() {
      _movements = movements;
    });
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

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
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
      return 'HOY, ${monthShort[local.month - 1]} ${local.day}';
    }
    if (movementDay == today.subtract(const Duration(days: 1))) {
      return 'AYER, ${monthShort[local.month - 1]} ${local.day}';
    }
    return '${monthShort[local.month - 1]} ${local.day}, ${local.year}';
  }

  String _formatTimeShort(DateTime date) {
    final DateTime local = date.toLocal();
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String mm = local.minute.toString().padLeft(2, '0');
    final String period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$mm $period';
  }

  bool _isNeutralMovement(InventoryMovementView movement) {
    final String reason = movement.reasonCode.toLowerCase();
    final String label = movement.reasonLabel.toLowerCase();
    return reason.contains('transfer') || label.contains('transfer');
  }

  bool _matchesSearch(InventoryMovementView movement, String query) {
    if (query.isEmpty) {
      return true;
    }
    final String q = query.toLowerCase();
    return movement.productName.toLowerCase().contains(q) ||
        movement.sku.toLowerCase().contains(q) ||
        (movement.refId ?? '').toLowerCase().contains(q) ||
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
    return orderedKeys.map((String key) {
      return _MovementDateGroup(
        date: dateByKey[key]!,
        items: grouped[key]!,
      );
    }).toList();
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _movementCard(InventoryMovementView movement) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isIn = movement.movementType == 'in';
    final bool neutral = _isNeutralMovement(movement);

    final Color tone = neutral
        ? (isDark
            ? const Color(0x4D1E293B)
            : const Color(0xFFF1F5F9)) // slate-800/30 : slate-100
        : isIn
            ? (isDark
                ? const Color(0x4D14532D)
                : const Color(0xFFDCFCE7)) // green-900/30 : green-100
            : (isDark
                ? const Color(0x4D7F1D1D)
                : const Color(0xFFFEE2E2)); // red-900/30 : red-100
    final Color ink = neutral
        ? (isDark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF475569)) // slate-400 : slate-600
        : isIn
            ? const Color(0xFF16A34A) // green-600
            : const Color(0xFFDC2626); // red-600
    final IconData icon = neutral
        ? Icons.sync_alt_rounded
        : isIn
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;

    final String amountText = neutral
        ? _formatQty(movement.qty)
        : isIn
            ? '+${_formatQty(movement.qty)}'
            : '-${_formatQty(movement.qty)}';
    final String skuRef = (movement.refId ?? '').trim().isEmpty
        ? 'SKU: ${movement.sku}'
        : 'SKU: ${movement.sku} • Ref: ${movement.refId!.trim()}';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(
                    0xFFF1F5F9), // border-slate-800 : border-slate-100
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: ink, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    movement.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    skuRef,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF64748B), // slate-500
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  amountText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimeShort(movement.createdAt),
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF94A3B8), // slate-400
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final bool selected = _selectedType == value;
    return InkWell(
      onTap: () async {
        if (_selectedType == value) {
          return;
        }
        setState(() => _selectedType = value);
        await _reloadMovements();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF1152D4) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF1152D4)
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
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
      title: 'Movimientos',
      currentRoute: '/inventario-movimientos',
      onRefresh: _bootstrap,
      showTopTabs: false,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        onPressed: () => context.go('/inventario'),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Buscar',
          onPressed: () => _searchFocusNode.requestFocus(),
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Filtros',
          onPressed: _openQuickFilters,
          icon: const Icon(
            Icons.filter_list_rounded,
            color: Color(0xFF1152D4),
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
              child: CustomScrollView(
                key: const PageStorageKey<String>(
                  'inventario-movimientos-groups',
                ),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.appBarTheme.backgroundColor ??
                            theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF1E293B) // slate-800
                                : const Color(0xFFE2E8F0), // slate-200
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: Row(
                          children: <Widget>[
                            _buildTypeTab(
                              label: 'Todos',
                              value: 'all',
                              theme: theme,
                            ),
                            const SizedBox(width: 24),
                            _buildTypeTab(
                              label: 'Entradas',
                              value: 'in',
                              theme: theme,
                            ),
                            const SizedBox(width: 24),
                            _buildTypeTab(
                              label: 'Salidas',
                              value: 'out',
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar SKU, Referencia o Fecha',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: theme.brightness == Brightness.dark
                                ? const Color(0xFF94A3B8) // slate-400
                                : const Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(Icons.search_rounded,
                              size: 20, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 40, // accommodate prefix icon properly
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  if (groups.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'Sin movimientos para mostrar.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          int itemIndex = 0;
                          for (final _MovementDateGroup group in groups) {
                            if (index == itemIndex) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Text(
                                  _formatDateGroup(group.date).toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    fontSize: 12,
                                    color: theme.brightness == Brightness.dark
                                        ? const Color(0xFF64748B) // slate-500
                                        : const Color(0xFF94A3B8), // slate-400
                                  ),
                                ),
                              );
                            }
                            itemIndex++;
                            for (final movement in group.items) {
                              if (index == itemIndex) {
                                return _movementCard(movement);
                              }
                              itemIndex++;
                            }
                          }
                          return null;
                        },
                        childCount: groups.fold<int>(
                          0,
                          (int sum, _MovementDateGroup g) =>
                              sum + 1 + g.items.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
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
