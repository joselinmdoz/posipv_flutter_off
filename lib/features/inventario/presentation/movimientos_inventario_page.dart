import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
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
    _bootstrap();
  }

  Future<void> _bootstrap() async {
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
      if (!mounted) {
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
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
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
                    itemCount: reasons.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, int index) {
                      final InventoryMovementReason reason = reasons[index];
                      return ListTile(
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
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              FilledButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
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
                                        await ds
                                            .deleteMovementReason(reason.code);
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

  String _movementTypeLabel(String type) {
    return type == 'in' ? 'Entrada' : 'Salida';
  }

  String _movementSourceLabel(String source) {
    switch (source) {
      case 'pos':
        return 'POS';
      case 'direct_sale':
        return 'Venta directa';
      case 'manual':
        return 'Manual';
      default:
        return source;
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
    const List<String> weekdays = <String>[
      'LUN',
      'MAR',
      'MIE',
      'JUE',
      'VIE',
      'SAB',
      'DOM',
    ];
    const List<String> months = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final DateTime local = date.toLocal();
    final String dayName = weekdays[local.weekday - 1];
    final String monthName = months[local.month - 1];
    return '$dayName ${local.day} de $monthName de ${local.year}';
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
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isIn = movement.movementType == 'in';
    final Color tone = isIn
        ? (isDark ? const Color(0xFF1F3A34) : const Color(0xFFE3F5EE))
        : (isDark ? const Color(0xFF472733) : const Color(0xFFFCE9EE));
    final Color ink = isIn ? const Color(0xFF57D0A6) : const Color(0xFFFF8EB4);
    final IconData icon =
        isIn ? Icons.south_west_rounded : Icons.north_east_rounded;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF342E46) : const Color(0xFFE2D9F3),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : const <BoxShadow>[
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    movement.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(icon, size: 14, color: ink),
                      const SizedBox(width: 4),
                      Text(
                        _movementTypeLabel(movement.movementType),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${movement.sku}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF28233A) : const Color(0xFFF2ECFA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Cantidad: ${_formatQty(movement.qty)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                _metaPill('Motivo', movement.reasonLabel),
                _metaPill(
                    'Origen', _movementSourceLabel(movement.movementSource)),
                _metaPill('Almacen', movement.warehouseName),
                _metaPill('Usuario', movement.username),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(movement.createdAt),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if ((movement.note ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF211D2D)
                      : const Color(0xFFF8F5FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  movement.note!.trim(),
                  style: TextStyle(color: scheme.onSurface),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metaPill(String label, String value) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28233A) : const Color(0xFFEDE7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11.5,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_MovementDateGroup> groups = _groupByDate(_movements);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Movimientos Inventario',
      currentRoute: '/inventario-movimientos',
      onRefresh: _bootstrap,
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openMovementForm,
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: <Widget>[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: DropdownButtonFormField<String?>(
                                  initialValue: _selectedWarehouseId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Almacen',
                                  ),
                                  items: <DropdownMenuItem<String?>>[
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('Todos'),
                                    ),
                                    ..._warehouses.map(
                                      (Warehouse w) =>
                                          DropdownMenuItem<String?>(
                                        value: w.id,
                                        child: Text(
                                          w.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (String? value) async {
                                    setState(
                                        () => _selectedWarehouseId = value);
                                    await _reloadMovements();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                tooltip: 'Gestionar motivos',
                                onPressed: _openReasonsManager,
                                icon: const Icon(Icons.settings_outlined),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedType,
                                  decoration:
                                      const InputDecoration(labelText: 'Tipo'),
                                  items: const <DropdownMenuItem<String>>[
                                    DropdownMenuItem<String>(
                                      value: 'all',
                                      child: Text('Todos'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'in',
                                      child: Text('Entrada'),
                                    ),
                                    DropdownMenuItem<String>(
                                      value: 'out',
                                      child: Text('Salida'),
                                    ),
                                  ],
                                  onChanged: (String? value) async {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _selectedType = value);
                                    await _reloadMovements();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedReasonCode,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Motivo'),
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
                                  onChanged: (String? value) async {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() => _selectedReasonCode = value);
                                    await _reloadMovements();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _reloadMovements,
                      child: _movements.isEmpty
                          ? ListView(
                              children: const <Widget>[
                                SizedBox(height: 48),
                                Center(
                                  child: Text('Sin movimientos para mostrar.'),
                                ),
                              ],
                            )
                          : ListView.builder(
                              itemCount: groups.length,
                              itemBuilder: (_, int index) {
                                final _MovementDateGroup group = groups[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == groups.length - 1 ? 0 : 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF28233A)
                                              : const Color(0xFFEFEAF9),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Text(
                                                _formatDateGroup(group.date),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${group.items.length} mov.',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...group.items.map(
                                        (InventoryMovementView movement) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: _movementCard(movement),
                                          );
                                        },
                                      ),
                                    ],
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

class _MovementDateGroup {
  const _MovementDateGroup({
    required this.date,
    required this.items,
  });

  final DateTime date;
  final List<InventoryMovementView> items;
}
