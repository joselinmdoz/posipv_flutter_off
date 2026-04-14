import 'dart:async';

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
import '../../ventas_pos/data/sale_service.dart';
import '../../ventas_pos/presentation/ventas_pos_providers.dart';
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

enum _MovementMoreMenuAction { exportFiltered, repairSalesStock }

enum _MovementExportFormat { csv, pdf }

class _MovimientosInventarioPageState
    extends ConsumerState<MovimientosInventarioPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  ProviderSubscription<int>? _inventoryRefreshSubscription;

  List<Warehouse> _warehouses = <Warehouse>[];
  List<InventoryMovementReason> _reasons = <InventoryMovementReason>[];
  List<InventoryMovementView> _movements = <InventoryMovementView>[];
  List<InventoryMovementProductOption> _movementProducts =
      <InventoryMovementProductOption>[];

  String? _selectedWarehouseId;
  String? _selectedProductId;
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  String _selectedType = 'all';
  String _selectedReasonCode = 'all';
  bool _loading = true;
  bool _repairingIntegrity = false;

  @override
  void initState() {
    super.initState();
    _inventoryRefreshSubscription = ref.listenManual<int>(
      inventoryRefreshSignalProvider,
      (int? previous, int next) {
        if (!mounted) {
          return;
        }
        unawaited(_bootstrap());
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _bootstrap();
    });
  }

  @override
  void dispose() {
    _inventoryRefreshSubscription?.close();
    _inventoryRefreshSubscription = null;
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final PerfTrace trace = PerfTrace('movimientos.bootstrap');
    setState(() => _loading = true);
    try {
      final InventarioLocalDataSource ds =
          ref.read(inventarioLocalDataSourceProvider);
      final Future<List<Warehouse>> warehousesFuture = _listActiveWarehouses();
      final Future<List<InventoryMovementReason>> reasonsFuture =
          ds.listMovementReasons();

      final List<Warehouse> warehouses = await warehousesFuture;
      final List<InventoryMovementReason> reasons = await reasonsFuture;
      trace.mark('catalogos cargados');
      final String? selectedWarehouse = _selectedWarehouseId != null &&
              warehouses.every(
                (Warehouse row) => row.id != _selectedWarehouseId,
              )
          ? null
          : _selectedWarehouseId;
      final String selectedReason = _selectedReasonCode == 'all' ||
              reasons.any((InventoryMovementReason row) {
                return row.code == _selectedReasonCode;
              })
          ? _selectedReasonCode
          : 'all';
      final List<InventoryMovementProductOption> products =
          await ds.listMovementProducts(
        warehouseId: selectedWarehouse,
      );
      final String? selectedProduct = _selectedProductId != null &&
              products.every(
                (InventoryMovementProductOption row) =>
                    row.productId != _selectedProductId,
              )
          ? null
          : _selectedProductId;
      final List<InventoryMovementView> movements = await _fetchMovements(
        selectedReasonCode: selectedReason,
        selectedWarehouseId: selectedWarehouse,
        selectedProductId: selectedProduct,
      );
      trace.mark('movimientos cargados');
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() {
        _warehouses = warehouses;
        _reasons = reasons;
        _movementProducts = products;
        _selectedWarehouseId = selectedWarehouse;
        _selectedProductId = selectedProduct;
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

  Future<List<Warehouse>> _listActiveWarehouses() {
    return ref.read(almacenesLocalDataSourceProvider).listActiveWarehouses();
  }

  Future<void> _refreshWarehousesCatalog({
    bool normalizeSelection = true,
  }) async {
    final List<Warehouse> warehouses = await _listActiveWarehouses();
    if (!mounted) {
      return;
    }
    setState(() {
      _warehouses = warehouses;
      if (normalizeSelection &&
          _selectedWarehouseId != null &&
          warehouses.every((Warehouse row) => row.id != _selectedWarehouseId)) {
        _selectedWarehouseId = warehouses.isEmpty ? null : warehouses.first.id;
      }
    });
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

  List<InventoryMovementView> _currentFilteredMovements() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _movements;
    }
    return _movements
        .where(
          (InventoryMovementView movement) => _matchesSearch(movement, query),
        )
        .toList(growable: false);
  }

  String _movementTypeFilterLabel() {
    switch (_selectedType) {
      case 'in':
        return 'Entradas';
      case 'out':
        return 'Salidas';
      case 'adjust':
        return 'Ajustes';
      default:
        return 'Todos';
    }
  }

  String _warehouseFilterLabel() {
    final String selected = (_selectedWarehouseId ?? '').trim();
    if (selected.isEmpty) {
      return 'Todos';
    }
    for (final Warehouse row in _warehouses) {
      if (row.id == selected) {
        return row.name;
      }
    }
    return 'Todos';
  }

  String _reasonFilterLabel() {
    final String selected = _selectedReasonCode.trim();
    if (selected == 'all' || selected.isEmpty) {
      return 'Todos';
    }
    for (final InventoryMovementReason row in _reasons) {
      if (row.code == selected) {
        return row.label;
      }
    }
    return 'Todos';
  }

  Future<void> _handleMoreMenuAction(_MovementMoreMenuAction action) async {
    switch (action) {
      case _MovementMoreMenuAction.exportFiltered:
        await _openExportFormatsSheet();
        break;
      case _MovementMoreMenuAction.repairSalesStock:
        await _repairSalesStockIntegrity();
        break;
    }
  }

  Future<void> _repairSalesStockIntegrity() async {
    final UserSession? session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (!session.isAdmin) {
      _show('Solo el administrador puede reparar integridad.');
      return;
    }
    if (_repairingIntegrity) {
      return;
    }
    setState(() => _repairingIntegrity = true);
    try {
      final bool? didRepair = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => _SalesStockRepairPage(userId: session.userId),
          fullscreenDialog: true,
        ),
      );
      if (didRepair == true && mounted) {
        await _bootstrap();
      }
    } catch (e) {
      if (mounted) {
        _show('No se pudo reparar integridad: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _repairingIntegrity = false);
      }
    }
  }

  Future<void> _openExportFormatsSheet() async {
    final _MovementExportFormat? format =
        await showModalBottomSheet<_MovementExportFormat>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(
                title: Text('Exportar movimientos filtrados'),
                subtitle: Text('Selecciona un formato'),
              ),
              ListTile(
                leading: const Icon(Icons.table_chart_rounded),
                title: const Text('Exportar CSV'),
                onTap: () =>
                    Navigator.of(context).pop(_MovementExportFormat.csv),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded),
                title: const Text('Exportar PDF'),
                onTap: () =>
                    Navigator.of(context).pop(_MovementExportFormat.pdf),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (format == null || !mounted) {
      return;
    }
    await _exportFilteredMovements(format);
  }

  Future<void> _exportFilteredMovements(_MovementExportFormat format) async {
    final List<InventoryMovementView> rows = _currentFilteredMovements();
    if (rows.isEmpty) {
      _show('No hay movimientos filtrados para exportar.');
      return;
    }
    try {
      final InventarioLocalDataSource ds =
          ref.read(inventarioLocalDataSourceProvider);
      final String query = _searchCtrl.text.trim();
      final InventoryMovementExportFilters filters =
          InventoryMovementExportFilters(
        warehouse: _warehouseFilterLabel(),
        movementType: _movementTypeFilterLabel(),
        reason: _reasonFilterLabel(),
        product: _selectedProductLabel(),
        dateFrom: _selectedDateFrom == null
            ? '-'
            : _formatDateOnly(_selectedDateFrom!),
        dateTo:
            _selectedDateTo == null ? '-' : _formatDateOnly(_selectedDateTo!),
        search: query.isEmpty ? '-' : query,
      );
      final String path = format == _MovementExportFormat.csv
          ? await ds.exportMovementsCsv(
              movements: rows,
              filters: filters,
            )
          : await ds.exportMovementsPdf(
              movements: rows,
              filters: filters,
            );
      _show(
        format == _MovementExportFormat.csv
            ? 'CSV exportado: $path'
            : 'PDF exportado: $path',
      );
    } catch (e) {
      _show('No se pudo exportar movimientos: $e');
    }
  }

  Future<List<InventoryMovementView>> _fetchMovements({
    String? selectedReasonCode,
    String? selectedWarehouseId,
    String? selectedProductId,
  }) async {
    final String reasonCode = selectedReasonCode ?? _selectedReasonCode;
    final String queryType = _selectedType == 'adjust' ? 'all' : _selectedType;
    final DateTime? createdFrom =
        _selectedDateFrom == null ? null : _startOfDay(_selectedDateFrom!);
    final DateTime? createdTo = _selectedDateTo == null
        ? null
        : _startOfDay(_selectedDateTo!).add(const Duration(days: 1));
    final List<InventoryMovementView> rows =
        await ref.read(inventarioLocalDataSourceProvider).listMovements(
              warehouseId: selectedWarehouseId ?? _selectedWarehouseId,
              movementType: queryType,
              reasonCode: reasonCode,
              productId: selectedProductId ?? _selectedProductId,
              createdFrom: createdFrom,
              createdTo: createdTo,
              limit: 5000,
            );
    if (_selectedType != 'adjust') {
      return rows;
    }
    return rows
        .where(
            (InventoryMovementView movement) => _isAdjustmentMovement(movement))
        .toList(growable: false);
  }

  Future<void> _openMovementForm({InventoryMovementView? movement}) async {
    await _refreshWarehousesCatalog(normalizeSelection: false);
    if (!mounted) {
      return;
    }
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
    final bool isEdit = movement != null;
    final String selectedWarehouseId =
        (movement?.warehouseId ?? '').trim().isEmpty
            ? (_selectedWarehouseId ?? _warehouses.first.id)
            : movement!.warehouseId;

    final List<InventoryView> adjustRows = await ds.listInventoryPage(
      warehouseId: selectedWarehouseId,
      limit: 5000,
      offset: 0,
    );
    if (adjustRows.isEmpty) {
      _show('No hay productos activos en este almacén.');
      return;
    }

    if (isEdit &&
        !adjustRows.any(
          (InventoryView row) => row.productId == movement.productId,
        )) {
      _show(
        'No se puede editar este movimiento porque su producto ya no está activo en el almacén.',
      );
      return;
    }

    final List<InventoryMovementReason> entryReasons =
        await ds.listManualMovementReasons(movementType: 'in');
    final List<InventoryMovementReason> outputReasons =
        await ds.listManualMovementReasons(movementType: 'out');
    final bool allowTransfer = !isEdit && _warehouses.length > 1;
    if (entryReasons.isEmpty && outputReasons.isEmpty && !allowTransfer) {
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
          allowTransfer: allowTransfer,
          currencySymbol: config.currencySymbol,
          title: isEdit ? 'Editar Movimiento' : 'Movimiento de Inventario',
          confirmLabel: isEdit ? 'Guardar cambios' : 'Aplicar',
          warehouseOptions: _warehouses
              .map(
                (Warehouse row) => InventoryMovementWarehouseOption(
                  id: row.id,
                  name: row.name,
                ),
              )
              .toList(),
          initialWarehouseId: selectedWarehouseId,
          initialProductId: movement?.productId,
          initialIsEntry: movement?.movementType == 'in',
          initialReasonCode: movement?.reasonCode,
          initialQty: movement?.qty,
          initialNote: movement?.note,
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
    final String movementKind =
        ((result['movementKind'] as String?) ?? '').trim();
    final bool isTransfer = movementKind == 'transfer';
    final bool isEntry = !isTransfer
        ? (movementKind == 'entry' || result['isEntry'] == true)
        : false;
    final double qty = result['qty'] as double;
    final String safeReasonCode =
        ((result['reasonCode'] as String?) ?? (isTransfer ? 'transfer' : ''))
            .trim();
    final String note = (result['note'] as String).trim();
    final String safeWarehouseId =
        ((result['warehouseId'] as String?) ?? selectedWarehouseId).trim();
    final String safeDestinationWarehouseId =
        ((result['destinationWarehouseId'] as String?) ?? '').trim();
    final double currentQty = (result['currentStock'] as double?) ?? 0;

    if (!isEdit && !isEntry && qty > currentQty) {
      _show('La salida supera el stock disponible.');
      return;
    }

    try {
      if (isEdit) {
        await ds.updateManualMovement(
          movementId: movement.id,
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
      } else {
        if (isTransfer) {
          await ds.createWarehouseTransfer(
            productId: safeProductId,
            sourceWarehouseId: safeWarehouseId,
            destinationWarehouseId: safeDestinationWarehouseId,
            qty: qty,
            userId: session.userId,
            note: note.isEmpty ? 'Transferencia manual de inventario' : note,
          );
        } else {
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
        }
      }
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _reloadMovements();
      _show(isEdit ? 'Movimiento actualizado.' : 'Movimiento registrado.');
    } catch (e) {
      _show(
        isEdit
            ? 'No se pudo actualizar movimiento: $e'
            : 'No se pudo registrar movimiento: $e',
      );
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
    await _refreshWarehousesCatalog();
    if (!mounted) {
      return;
    }
    final InventarioLocalDataSource ds =
        ref.read(inventarioLocalDataSourceProvider);
    String? draftWarehouse = _selectedWarehouseId;
    String draftReason = _selectedReasonCode;
    String? draftProduct = _selectedProductId;
    DateTime? draftFrom = _selectedDateFrom;
    DateTime? draftTo = _selectedDateTo;
    List<InventoryMovementProductOption> draftProducts =
        await ds.listMovementProducts(
      warehouseId: draftWarehouse,
    );
    if (!mounted) {
      return;
    }
    if (draftProduct != null &&
        draftProducts.every(
          (InventoryMovementProductOption row) => row.productId != draftProduct,
        )) {
      draftProduct = null;
    }
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
                        unawaited(() async {
                          final List<InventoryMovementProductOption> options =
                              await ds.listMovementProducts(
                            warehouseId: value,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          setModalState(() {
                            draftProducts = options;
                            if (draftProduct != null &&
                                options.every(
                                  (InventoryMovementProductOption row) =>
                                      row.productId != draftProduct,
                                )) {
                              draftProduct = null;
                            }
                          });
                        }());
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: draftProduct,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Producto'),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...draftProducts.map(
                          (InventoryMovementProductOption row) =>
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
                              final DateTime now = DateTime.now();
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: draftFrom ?? draftTo ?? now,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                helpText: 'Desde',
                              );
                              if (picked == null) {
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              setModalState(() {
                                draftFrom = _startOfDay(picked);
                                if (draftTo != null &&
                                    draftTo!.isBefore(draftFrom!)) {
                                  draftTo = draftFrom;
                                }
                              });
                            },
                            icon: const Icon(Icons.date_range_rounded),
                            label: Text(
                              draftFrom == null
                                  ? 'Desde'
                                  : _formatDateOnly(draftFrom!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final DateTime now = DateTime.now();
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: draftTo ?? draftFrom ?? now,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                helpText: 'Hasta',
                              );
                              if (picked == null) {
                                return;
                              }
                              if (!context.mounted) {
                                return;
                              }
                              setModalState(() {
                                draftTo = _startOfDay(picked);
                                if (draftFrom != null &&
                                    draftFrom!.isAfter(draftTo!)) {
                                  draftFrom = draftTo;
                                }
                              });
                            },
                            icon: const Icon(Icons.event_rounded),
                            label: Text(
                              draftTo == null
                                  ? 'Hasta'
                                  : _formatDateOnly(draftTo!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            draftProduct = null;
                            draftFrom = null;
                            draftTo = null;
                          });
                        },
                        child: const Text('Limpiar producto/fecha'),
                      ),
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
      _selectedProductId = draftProduct;
      _selectedDateFrom = draftFrom;
      _selectedDateTo = draftTo;
      _movementProducts = draftProducts;
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

  DateTime _startOfDay(DateTime date) {
    final DateTime local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  String _formatDateOnly(DateTime date) {
    final DateTime local = date.toLocal();
    final String d = local.day.toString().padLeft(2, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String y = local.year.toString();
    return '$d/$m/$y';
  }

  bool get _hasAdvancedFilters {
    return _selectedProductId != null ||
        _selectedDateFrom != null ||
        _selectedDateTo != null;
  }

  String _selectedProductLabel() {
    final String id = (_selectedProductId ?? '').trim();
    if (id.isEmpty) {
      return 'Todos';
    }
    for (final InventoryMovementProductOption option in _movementProducts) {
      if (option.productId == id) {
        return '${option.productName} • ${option.sku}';
      }
    }
    return 'Producto';
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

  void _goBack() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/inventario');
  }

  bool _canArchiveMovement(InventoryMovementView movement) {
    final String source = movement.movementSource.trim().toLowerCase();
    if (source == 'transfer' || movement.reasonCode == 'transfer') {
      return false;
    }
    final UserSession? session = ref.read(currentSessionProvider);
    if (session?.isAdmin ?? false) {
      return true;
    }
    final String refType = (movement.refType ?? '').trim().toLowerCase();
    final bool isSaleRef = refType == 'sale' ||
        refType == 'sale_pos' ||
        refType == 'sale_direct' ||
        refType == 'consignment_sale' ||
        refType == 'consignment_sale_pos' ||
        refType == 'consignment_sale_direct';
    return source == 'manual' && !isSaleRef && movement.reasonCode != 'sale';
  }

  bool _canEditMovement(InventoryMovementView movement) {
    final String source = movement.movementSource.trim().toLowerCase();
    final String refType = (movement.refType ?? '').trim().toLowerCase();
    final bool isSaleRef = refType == 'sale' ||
        refType == 'sale_pos' ||
        refType == 'sale_direct' ||
        refType == 'consignment_sale' ||
        refType == 'consignment_sale_pos' ||
        refType == 'consignment_sale_direct';
    return source == 'manual' && !isSaleRef && movement.reasonCode != 'sale';
  }

  Future<void> _editMovement(InventoryMovementView movement) async {
    if (!_canEditMovement(movement)) {
      _show('Solo se pueden editar movimientos manuales.');
      return;
    }
    await _openMovementForm(movement: movement);
  }

  Future<void> _archiveMovement(InventoryMovementView movement) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesion.');
      return;
    }
    if (!_canArchiveMovement(movement)) {
      _show('Solo se pueden dar de baja movimientos manuales.');
      return;
    }
    final bool isAdmin = session.isAdmin;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archivar movimiento'),
          content: Text(
            'Se archivará el movimiento de "${movement.productName}" y se revertirá su impacto en stock.\n\n'
            'Para eliminarlo definitivamente, usa la vista de Archivados.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Archivar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    try {
      await ref.read(inventarioLocalDataSourceProvider).archiveManualMovement(
            movementId: movement.id,
            userId: session.userId,
            note: 'Movimiento archivado por ${session.username}',
            allowAnyMovement: isAdmin,
            allowNegativeResult: isAdmin,
          );
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      await _reloadMovements();
      _show('Movimiento archivado.');
    } catch (e) {
      _show('No se pudo archivar el movimiento: $e');
    }
  }

  List<Widget> _buildGroupedMovementWidgets(
    List<_MovementDateGroup> groups, {
    required bool canEdit,
    required bool canArchive,
  }) {
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
            onEdit: canEdit && _canEditMovement(movement)
                ? () => _editMovement(movement)
                : null,
            onArchive: canArchive && _canArchiveMovement(movement)
                ? () => _archiveMovement(movement)
                : null,
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
    final UserSession? session = ref.watch(currentSessionProvider);
    final bool canRepairSalesStock = session?.isAdmin ?? false;

    return AppScaffold(
      title: 'Movimientos',
      currentRoute: '/inventario-movimientos',
      onRefresh: _bootstrap,
      showTopTabs: false,
      showBottomNavigationBar: true,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
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
        PopupMenuButton<_MovementMoreMenuAction>(
          tooltip: 'Más opciones',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (_MovementMoreMenuAction action) {
            unawaited(_handleMoreMenuAction(action));
          },
          itemBuilder: (BuildContext context) =>
              <PopupMenuEntry<_MovementMoreMenuAction>>[
            const PopupMenuItem<_MovementMoreMenuAction>(
              value: _MovementMoreMenuAction.exportFiltered,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.ios_share_rounded),
                title: Text('Exportar filtrados'),
              ),
            ),
            if (canRepairSalesStock)
              PopupMenuItem<_MovementMoreMenuAction>(
                value: _MovementMoreMenuAction.repairSalesStock,
                enabled: !_repairingIntegrity,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: _repairingIntegrity
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build_circle_outlined),
                  title: Text(
                    _repairingIntegrity
                        ? 'Reparando integridad...'
                        : 'Reparar ventas/stock',
                  ),
                ),
              ),
          ],
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
                  if (_hasAdvancedFilters)
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                if (_selectedProductId != null)
                                  Chip(
                                    label: Text(_selectedProductLabel()),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (_selectedDateFrom != null)
                                  Chip(
                                    label: Text(
                                      'Desde ${_formatDateOnly(_selectedDateFrom!)}',
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (_selectedDateTo != null)
                                  Chip(
                                    label: Text(
                                      'Hasta ${_formatDateOnly(_selectedDateTo!)}',
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Limpiar filtros',
                            onPressed: () async {
                              setState(() {
                                _selectedProductId = null;
                                _selectedDateFrom = null;
                                _selectedDateTo = null;
                              });
                              await _reloadMovements();
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                  if (_hasAdvancedFilters) const SizedBox(height: 14),
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
                    ..._buildGroupedMovementWidgets(
                      groups,
                      canEdit: license.canWrite,
                      canArchive: license.canWrite,
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

class _SalesStockRepairPage extends ConsumerStatefulWidget {
  const _SalesStockRepairPage({
    required this.userId,
  });

  final String userId;

  @override
  ConsumerState<_SalesStockRepairPage> createState() =>
      _SalesStockRepairPageState();
}

class _SalesStockRepairPageState extends ConsumerState<_SalesStockRepairPage> {
  List<SaleStockIntegrityIssue> _issues = <SaleStockIntegrityIssue>[];
  Set<String> _selectedLineKeys = <String>{};
  bool _loading = true;
  bool _running = false;
  bool _allowNegativeStock = true;
  bool _didRepair = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadIssues();
    });
  }

  Future<void> _loadIssues({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<SaleStockIntegrityIssue> issues = await ref
          .read(ventasPosLocalDataSourceProvider)
          .listSalesStockIntegrityIssues(
            userId: widget.userId,
          );
      if (!mounted) {
        return;
      }
      final Set<String> validLineKeys = _allLineKeysFrom(issues);
      Set<String> nextSelection;
      if (_selectedLineKeys.isEmpty) {
        nextSelection = validLineKeys;
      } else {
        nextSelection = _selectedLineKeys.intersection(validLineKeys);
        if (nextSelection.isEmpty && validLineKeys.isNotEmpty) {
          nextSelection = validLineKeys;
        }
      }
      setState(() {
        _issues = issues;
        _selectedLineKeys = nextSelection;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar inconsistencias: $e');
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

  String _lineKey(String saleId, String productId) {
    return '$saleId|$productId';
  }

  Set<String> _allLineKeysFrom(List<SaleStockIntegrityIssue> issues) {
    final Set<String> keys = <String>{};
    for (final SaleStockIntegrityIssue issue in issues) {
      for (final SaleStockIntegrityIssueLine line in issue.lines) {
        keys.add(_lineKey(issue.saleId, line.productId));
      }
    }
    return keys;
  }

  bool _isLineSelected(
    SaleStockIntegrityIssue issue,
    SaleStockIntegrityIssueLine line,
  ) {
    return _selectedLineKeys.contains(_lineKey(issue.saleId, line.productId));
  }

  bool _isSaleFullySelected(SaleStockIntegrityIssue issue) {
    if (issue.lines.isEmpty) {
      return false;
    }
    return issue.lines.every(
      (SaleStockIntegrityIssueLine line) => _isLineSelected(issue, line),
    );
  }

  bool _isSalePartiallySelected(SaleStockIntegrityIssue issue) {
    final bool anySelected = issue.lines.any(
      (SaleStockIntegrityIssueLine line) => _isLineSelected(issue, line),
    );
    return anySelected && !_isSaleFullySelected(issue);
  }

  int get _selectedLinesCount => _selectedLineKeys.length;

  int get _selectedSalesCount {
    final Set<String> selectedSales = <String>{};
    for (final SaleStockIntegrityIssue issue in _issues) {
      final bool anySelected = issue.lines.any(
        (SaleStockIntegrityIssueLine line) => _isLineSelected(issue, line),
      );
      if (anySelected) {
        selectedSales.add(issue.saleId);
      }
    }
    return selectedSales.length;
  }

  double get _selectedMissingQty {
    double total = 0;
    for (final SaleStockIntegrityIssue issue in _issues) {
      for (final SaleStockIntegrityIssueLine line in issue.lines) {
        if (_isLineSelected(issue, line)) {
          total += line.missingQty;
        }
      }
    }
    return total;
  }

  int get _selectedWithPurgeEvidence {
    return _issues.where((SaleStockIntegrityIssue issue) {
      return issue.hasPurgeEvidence &&
          issue.lines.any(
            (SaleStockIntegrityIssueLine line) => _isLineSelected(issue, line),
          );
    }).length;
  }

  int get _selectedWithVoidedEvidence {
    return _issues.where((SaleStockIntegrityIssue issue) {
      return issue.hasVoidedMovements &&
          issue.lines.any(
            (SaleStockIntegrityIssueLine line) => _isLineSelected(issue, line),
          );
    }).length;
  }

  void _toggleSaleSelection(String saleId, bool selected) {
    setState(() {
      SaleStockIntegrityIssue? issue;
      for (final SaleStockIntegrityIssue row in _issues) {
        if (row.saleId == saleId) {
          issue = row;
          break;
        }
      }
      if (issue == null) {
        return;
      }
      for (final SaleStockIntegrityIssueLine line in issue.lines) {
        final String key = _lineKey(issue.saleId, line.productId);
        if (selected) {
          _selectedLineKeys.add(key);
        } else {
          _selectedLineKeys.remove(key);
        }
      }
    });
  }

  void _toggleLineSelection({
    required SaleStockIntegrityIssue issue,
    required SaleStockIntegrityIssueLine line,
    required bool selected,
  }) {
    setState(() {
      final String key = _lineKey(issue.saleId, line.productId);
      if (selected) {
        _selectedLineKeys.add(key);
      } else {
        _selectedLineKeys.remove(key);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedLineKeys = _allLineKeysFrom(_issues);
    });
  }

  void _clearSelection() {
    setState(() => _selectedLineKeys = <String>{});
  }

  List<SaleStockIntegrityRepairTarget> _selectedTargets() {
    final List<SaleStockIntegrityRepairTarget> result =
        <SaleStockIntegrityRepairTarget>[];
    for (final SaleStockIntegrityIssue issue in _issues) {
      for (final SaleStockIntegrityIssueLine line in issue.lines) {
        if (!_isLineSelected(issue, line)) {
          continue;
        }
        result.add(
          SaleStockIntegrityRepairTarget(
            saleId: issue.saleId,
            productId: line.productId,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _runRepair() async {
    if (_running) {
      return;
    }
    final List<SaleStockIntegrityRepairTarget> selectedTargets =
        _selectedTargets();
    if (selectedTargets.isEmpty) {
      _show('Selecciona al menos un producto para reparar.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar reparación'),
          content: Text(
            'Se repararán $_selectedSalesCount ventas seleccionadas.\n'
            '• Productos seleccionados: $_selectedLinesCount\n'
            '• Cantidad faltante: ${_formatQty(_selectedMissingQty)}\n'
            '• Evidencia de borrado manual: $_selectedWithPurgeEvidence\n'
            '• Con movimientos archivados: $_selectedWithVoidedEvidence',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reparar'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !mounted) {
      return;
    }

    setState(() => _running = true);
    try {
      final SaleStockIntegrityRepairResult result = await ref
          .read(ventasPosLocalDataSourceProvider)
          .repairSalesStockIntegrity(
            userId: widget.userId,
            dryRun: false,
            allowNegativeStock: _allowNegativeStock,
            targets: selectedTargets,
          );
      if (!mounted) {
        return;
      }
      _didRepair = true;
      ref.read(inventoryRefreshSignalProvider.notifier).state += 1;
      _show(
        'Integridad reparada.\n'
        'Movimientos reconstruidos: ${result.movementsRebuilt}\n'
        'Ajustes de stock: ${result.stockAdjustments}\n'
        'Saltadas por stock negativo: ${result.skippedForNegativeStock}',
      );
      await _loadIssues(showLoader: false);
    } catch (e) {
      if (mounted) {
        _show('No se pudo reparar integridad: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  String _formatQty(double value) {
    final double abs = value.abs();
    if ((abs - abs.roundToDouble()).abs() < 0.000001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String year = local.year.toString().padLeft(4, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  String _channelLabel(SaleStockIntegrityIssue issue) {
    return issue.terminalId.trim().isEmpty ? 'Venta directa' : 'TPV';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int selectedCount = _selectedSalesCount;
    final int totalCount = _issues.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_didRepair);
      },
      child: AppScaffold(
        title: 'Reparar ventas/stock',
        currentRoute: '/inventario-movimientos',
        onRefresh: _loadIssues,
        useDefaultActions: false,
        showDrawer: false,
        showBottomNavigationBar: false,
        appBarLeading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(_didRepair),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        appBarActions: <Widget>[
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loading || _running ? null : _loadIssues,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Ventas con inconsistencias detectadas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$selectedCount de $totalCount seleccionadas • '
                            '$_selectedLinesCount productos • '
                            'Faltante ${_formatQty(_selectedMissingQty)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: <Widget>[
                              TextButton.icon(
                                onPressed: _issues.isEmpty ? null : _selectAll,
                                icon: const Icon(Icons.select_all_rounded),
                                label: const Text('Seleccionar todo'),
                              ),
                              const SizedBox(width: 6),
                              TextButton.icon(
                                onPressed: _selectedLineKeys.isEmpty
                                    ? null
                                    : _clearSelection,
                                icon: const Icon(Icons.deselect_rounded),
                                label: const Text('Limpiar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _issues.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 54,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No hay inconsistencias pendientes entre ventas y stock.',
                                    textAlign: TextAlign.center,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            key: const PageStorageKey<String>(
                              'sales-stock-repair-list',
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                            itemCount: _issues.length,
                            itemBuilder: (BuildContext context, int index) {
                              final SaleStockIntegrityIssue issue =
                                  _issues[index];
                              final bool selected = _isSaleFullySelected(issue);
                              final bool partiallySelected =
                                  _isSalePartiallySelected(issue);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side:
                                      BorderSide(color: colors.outlineVariant),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    InkWell(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14),
                                      ),
                                      onTap: () => _toggleSaleSelection(
                                        issue.saleId,
                                        !selected,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            8, 8, 10, 6),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Checkbox(
                                              tristate: true,
                                              fillColor: WidgetStateProperty
                                                  .resolveWith<Color?>(
                                                (Set<WidgetState> states) {
                                                  if (partiallySelected &&
                                                      !selected) {
                                                    return colors.primary;
                                                  }
                                                  return null;
                                                },
                                              ),
                                              side: BorderSide(
                                                color: colors.outline,
                                              ),
                                              value: partiallySelected
                                                  ? null
                                                  : selected,
                                              checkColor:
                                                  partiallySelected && !selected
                                                      ? colors.onPrimary
                                                      : null,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              onChanged: _running
                                                  ? null
                                                  : (bool? value) {
                                                      _toggleSaleSelection(
                                                        issue.saleId,
                                                        value ?? false,
                                                      );
                                                    },
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Text(
                                                    issue.folio.trim().isEmpty
                                                        ? issue.saleId
                                                        : issue.folio,
                                                    style: theme
                                                        .textTheme.titleSmall
                                                        ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${issue.warehouseName} • ${_channelLabel(issue)}',
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatDateTime(
                                                      issue.createdAt,
                                                    ),
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Faltante\n${_formatQty(issue.totalMissingQty)}',
                                              textAlign: TextAlign.right,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colors.error,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (issue.hasPurgeEvidence ||
                                        issue.hasVoidedMovements)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            14, 0, 14, 8),
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: <Widget>[
                                            if (issue.hasPurgeEvidence)
                                              Chip(
                                                label: const Text(
                                                  'Borrado manual detectado',
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: colors
                                                    .errorContainer
                                                    .withValues(alpha: 0.75),
                                              ),
                                            if (issue.hasVoidedMovements)
                                              Chip(
                                                label: const Text(
                                                  'Movimientos archivados',
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: colors
                                                    .secondaryContainer
                                                    .withValues(alpha: 0.85),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ExpansionTile(
                                      key: PageStorageKey<String>(
                                        'repair-sale-${issue.saleId}',
                                      ),
                                      tilePadding: const EdgeInsets.fromLTRB(
                                          14, 0, 14, 2),
                                      childrenPadding:
                                          const EdgeInsets.fromLTRB(
                                              14, 0, 14, 10),
                                      title: Text(
                                        'Productos afectados (${issue.lines.length})',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      children: issue.lines
                                          .map(
                                            (SaleStockIntegrityIssueLine
                                                    line) =>
                                                Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Checkbox(
                                                    value: _isLineSelected(
                                                      issue,
                                                      line,
                                                    ),
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                    onChanged: _running
                                                        ? null
                                                        : (bool? value) {
                                                            _toggleLineSelection(
                                                              issue: issue,
                                                              line: line,
                                                              selected: value ??
                                                                  false,
                                                            );
                                                          },
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        Text(
                                                          line.productName,
                                                          style: theme.textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 2),
                                                        Text(
                                                          'SKU: ${line.productSku}',
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: colors
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Esperado ${_formatQty(line.expectedQty)} • Cubierto ${_formatQty(line.coveredQty)}',
                                                          style: theme.textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                            color: colors
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '-${_formatQty(line.missingQty)}',
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(
                                                      color: colors.error,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(
                          top: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SwitchListTile.adaptive(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Permitir stock negativo en reparación',
                            ),
                            value: _allowNegativeStock,
                            onChanged: _running
                                ? null
                                : (bool value) {
                                    setState(
                                      () => _allowNegativeStock = value,
                                    );
                                  },
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _running ||
                                      _issues.isEmpty ||
                                      _selectedLineKeys.isEmpty
                                  ? null
                                  : _runRepair,
                              icon: _running
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.build_circle_rounded),
                              label: Text(
                                _running
                                    ? 'Reparando...'
                                    : 'Reparar seleccionadas ($_selectedLinesCount productos)',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
