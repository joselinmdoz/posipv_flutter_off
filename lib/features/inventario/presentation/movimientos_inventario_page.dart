import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../almacenes/presentation/almacenes_providers.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../productos/presentation/productos_providers.dart';
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
  List<Product> _products = <Product>[];
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
      final Future<List<Product>> productsFuture =
          ref.read(productosLocalDataSourceProvider).listActiveProducts();
      final Future<List<InventoryMovementReason>> reasonsFuture =
          ref.read(inventarioLocalDataSourceProvider).listMovementReasons();

      final List<Warehouse> warehouses = await warehousesFuture;
      final List<Product> products = await productsFuture;
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
        _products = products;
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
    if (_products.isEmpty) {
      _show('No hay productos activos.');
      return;
    }

    final InventarioLocalDataSource ds =
        ref.read(inventarioLocalDataSourceProvider);
    String selectedWarehouseId = _selectedWarehouseId ?? _warehouses.first.id;
    String selectedProductId = _products.first.id;
    String movementType = 'in';
    List<InventoryMovementReason> reasons =
        await ds.listManualMovementReasons(movementType: movementType);
    String? selectedReasonCode = reasons.isEmpty ? null : reasons.first.code;
    String movementQtyText = '';
    String movementNoteText = '';

    bool submitted = false;

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setModalState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Registrar movimiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              DropdownButtonFormField<String>(
                                initialValue: selectedWarehouseId,
                                isExpanded: true,
                                decoration:
                                    const InputDecoration(labelText: 'Almacen'),
                                items: _warehouses
                                    .map(
                                      (Warehouse w) => DropdownMenuItem<String>(
                                        value: w.id,
                                        child: Text(
                                          w.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setModalState(
                                      () => selectedWarehouseId = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: selectedProductId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                    labelText: 'Producto'),
                                items: _products
                                    .map(
                                      (Product p) => DropdownMenuItem<String>(
                                        value: p.id,
                                        child: Text(
                                          '${p.sku} - ${p.name}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setModalState(
                                      () => selectedProductId = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SegmentedButton<String>(
                                  segments: const <ButtonSegment<String>>[
                                    ButtonSegment<String>(
                                      value: 'in',
                                      label: Text('Entrada'),
                                      icon: Icon(Icons.add_box_outlined),
                                    ),
                                    ButtonSegment<String>(
                                      value: 'out',
                                      label: Text('Salida'),
                                      icon: Icon(
                                        Icons.indeterminate_check_box_outlined,
                                      ),
                                    ),
                                  ],
                                  selected: <String>{movementType},
                                  onSelectionChanged:
                                      (Set<String> value) async {
                                    final String nextType = value.first;
                                    if (nextType == movementType) {
                                      return;
                                    }
                                    final List<InventoryMovementReason>
                                        nextReasons =
                                        await ds.listManualMovementReasons(
                                      movementType: nextType,
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    setModalState(() {
                                      movementType = nextType;
                                      reasons = nextReasons;
                                      selectedReasonCode = reasons.isEmpty
                                          ? null
                                          : reasons.first.code;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                initialValue: selectedReasonCode,
                                isExpanded: true,
                                decoration:
                                    const InputDecoration(labelText: 'Motivo'),
                                items: reasons
                                    .map(
                                      (InventoryMovementReason row) =>
                                          DropdownMenuItem<String>(
                                        value: row.code,
                                        child: Text(row.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (String? value) {
                                  setModalState(
                                      () => selectedReasonCode = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  hintText: '0.00',
                                ),
                                onChanged: (String value) =>
                                    movementQtyText = value,
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Nota (opcional)',
                                ),
                                onChanged: (String value) =>
                                    movementNoteText = value,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (selectedReasonCode == null) {
                              _show('Selecciona un motivo valido.');
                              return;
                            }
                            final double? qty = double.tryParse(
                              movementQtyText.trim().replaceAll(',', '.'),
                            );
                            if (qty == null || qty <= 0) {
                              _show('Cantidad invalida.');
                              return;
                            }

                            try {
                              await ds.createManualMovement(
                                productId: selectedProductId,
                                warehouseId: selectedWarehouseId,
                                type: movementType,
                                qty: qty,
                                reasonCode: selectedReasonCode!,
                                userId: session.userId,
                                note: movementNoteText,
                              );
                              submitted = true;
                              if (!context.mounted) {
                                return;
                              }
                              Navigator.of(context).pop();
                            } catch (e) {
                              _show('No se pudo registrar movimiento: $e');
                            }
                          },
                          child: const Text('Guardar movimiento'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (!submitted || !mounted) {
      return;
    }
    await _bootstrap();
    _show('Movimiento registrado.');
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
    final bool isIn = movement.movementType == 'in';
    final bool neutral = _isNeutralMovement(movement);
    final Color tone = neutral
        ? (theme.brightness == Brightness.dark
            ? const Color(0xFF334155)
            : const Color(0xFFF1F5F9))
        : isIn
            ? (theme.brightness == Brightness.dark
                ? const Color(0xFF14532D)
                : const Color(0xFFDCFCE7))
            : (theme.brightness == Brightness.dark
                ? const Color(0xFF7F1D1D)
                : const Color(0xFFFEE2E2));
    final Color ink = neutral
        ? theme.colorScheme.onSurfaceVariant
        : isIn
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626);
    final IconData icon = neutral
        ? Icons.swap_horiz_rounded
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
            color: theme.colorScheme.outline.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                      color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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
          ? FloatingActionButton(
              onPressed: _openMovementForm,
              backgroundColor: const Color(0xFF1152D4),
              child: const Icon(Icons.add_rounded, color: Colors.white),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Buscar SKU, Referencia o Fecha',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: theme.cardColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
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
                              color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline.withValues(alpha: 0.4),
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
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  _formatDateGroup(group.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
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
                          (int sum, _MovementDateGroup g) => sum + 1 + g.items.length,
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
