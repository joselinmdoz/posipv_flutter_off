import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_searchable_select_field.dart';
import '../../../inventario/data/inventario_local_datasource.dart';

class InventoryMovementWarehouseOption {
  const InventoryMovementWarehouseOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

class PosInventoryMovementDialog extends StatefulWidget {
  static const String kindEntry = 'entry';
  static const String kindOutput = 'output';
  static const String kindTransfer = 'transfer';

  final List<InventoryView> adjustRows;
  final List<InventoryMovementReason> entryReasons;
  final List<InventoryMovementReason> outputReasons;
  final bool allowTransfer;
  final String? transferFixedDestinationWarehouseId;
  final String currencySymbol;
  final String Function(InventoryView row)? priceLabelBuilder;
  final List<InventoryMovementWarehouseOption> warehouseOptions;
  final String? initialWarehouseId;
  final String? initialDestinationWarehouseId;
  final Future<List<InventoryView>> Function(String warehouseId)?
      loadAdjustRowsForWarehouse;
  final String? initialProductId;
  final bool? initialIsEntry;
  final String? initialReasonCode;
  final double? initialQty;
  final String? initialNote;
  final String title;
  final String confirmLabel;

  const PosInventoryMovementDialog({
    super.key,
    required this.adjustRows,
    required this.entryReasons,
    required this.outputReasons,
    this.allowTransfer = false,
    this.transferFixedDestinationWarehouseId,
    required this.currencySymbol,
    this.priceLabelBuilder,
    this.warehouseOptions = const <InventoryMovementWarehouseOption>[],
    this.initialWarehouseId,
    this.initialDestinationWarehouseId,
    this.loadAdjustRowsForWarehouse,
    this.initialProductId,
    this.initialIsEntry,
    this.initialReasonCode,
    this.initialQty,
    this.initialNote,
    this.title = 'Movimiento de Inventario',
    this.confirmLabel = 'Aplicar',
  });

  @override
  State<PosInventoryMovementDialog> createState() =>
      _PosInventoryMovementDialogState();
}

class _PosInventoryMovementDialogState
    extends State<PosInventoryMovementDialog> {
  late List<InventoryView> _adjustRows;
  String? _selectedWarehouseId;
  late String _selectedProductId;
  late String _movementKind;
  late String? _selectedReasonCode;
  String? _selectedDestinationWarehouseId;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _loadingRows = false;

  final Map<String, InventoryView> _rowByProductId = {};

  bool get _hasFixedTransferDestination =>
      (widget.transferFixedDestinationWarehouseId ?? '').trim().isNotEmpty;

  String get _resolvedFixedTransferDestinationId =>
      (widget.transferFixedDestinationWarehouseId ?? '').trim();

  @override
  void initState() {
    super.initState();
    _adjustRows = List<InventoryView>.from(widget.adjustRows);
    _selectedWarehouseId = widget.initialWarehouseId;
    if (widget.warehouseOptions.isNotEmpty) {
      final bool hasSelected = widget.warehouseOptions.any(
        (InventoryMovementWarehouseOption row) =>
            row.id == _selectedWarehouseId,
      );
      if (!hasSelected) {
        _selectedWarehouseId = widget.warehouseOptions.first.id;
      }
    }
    _reindexRows();

    final String desiredProductId = (widget.initialProductId ?? '').trim();
    _selectedProductId = _adjustRows.isEmpty
        ? ''
        : (_rowByProductId.containsKey(desiredProductId)
            ? desiredProductId
            : _adjustRows.first.productId);

    final String initialReasonCode = (widget.initialReasonCode ?? '').trim();
    final bool initialTransfer =
        widget.allowTransfer && initialReasonCode == 'transfer';
    if (initialTransfer) {
      _movementKind = PosInventoryMovementDialog.kindTransfer;
    } else {
      final bool startsAsEntry = widget.initialIsEntry ??
          (widget.entryReasons.isNotEmpty || widget.outputReasons.isEmpty);
      _movementKind = startsAsEntry
          ? PosInventoryMovementDialog.kindEntry
          : PosInventoryMovementDialog.kindOutput;
    }
    _selectedReasonCode = null;
    _ensureReasonForCurrentMode();
    _selectedDestinationWarehouseId =
        widget.initialDestinationWarehouseId?.trim().isEmpty ?? true
            ? null
            : widget.initialDestinationWarehouseId!.trim();
    if (_hasFixedTransferDestination) {
      _selectedDestinationWarehouseId = _resolvedFixedTransferDestinationId;
    }
    _ensureTransferDestinationWarehouse();

    if (widget.initialQty != null && widget.initialQty! > 0) {
      _qtyCtrl.text = widget.initialQty!.toStringAsFixed(2);
    }
    final String initialNote = (widget.initialNote ?? '').trim();
    if (initialNote.isNotEmpty) {
      _noteCtrl.text = initialNote;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF1152D4);

    final bool isEntryMovement =
        _movementKind == PosInventoryMovementDialog.kindEntry;
    final bool isTransferMovement =
        _movementKind == PosInventoryMovementDialog.kindTransfer;
    final List<InventoryMovementReason> selectableReasons =
        isEntryMovement ? widget.entryReasons : widget.outputReasons;
    final List<InventoryMovementWarehouseOption> transferDestinations =
        _availableDestinationWarehouses();
    final String fixedDestinationName = _warehouseNameById(
      _resolvedFixedTransferDestinationId,
    );

    final InventoryView? selectedProduct = _rowByProductId[_selectedProductId];
    final double currentStock = selectedProduct?.qty ?? 0;
    final String productPrice = selectedProduct == null
        ? '${widget.currencySymbol}0.00'
        : (widget.priceLabelBuilder?.call(selectedProduct) ??
            '${widget.currencySymbol}${(selectedProduct.priceCents / 100).toStringAsFixed(2)}');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black26),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select Product
                    if (widget.warehouseOptions.isNotEmpty) ...[
                      AppSearchableSelectField<String>(
                        label: 'Seleccionar Almacén',
                        value: _selectedWarehouseId,
                        enabled: !_loadingRows,
                        hintText: _loadingRows
                            ? 'Cargando almacenes...'
                            : 'Selecciona un almacén',
                        searchHintText: 'Buscar almacén',
                        options: widget.warehouseOptions
                            .map((InventoryMovementWarehouseOption row) =>
                                AppSearchableSelectOption<String>(
                                  value: row.id,
                                  label: row.name,
                                ))
                            .toList(growable: false),
                        onChanged: (String value) => _onWarehouseChanged(value),
                      ),
                      const SizedBox(height: 24),
                    ],

                    AppSearchableSelectField<String>(
                      label: 'Seleccionar Producto',
                      value: _rowByProductId.containsKey(_selectedProductId)
                          ? _selectedProductId
                          : null,
                      enabled: !_loadingRows && _adjustRows.isNotEmpty,
                      hintText: 'Selecciona un producto',
                      searchHintText: 'Buscar por nombre o SKU',
                      emptyStateText:
                          'No hay productos disponibles para este almacén.',
                      options: _adjustRows
                          .map((InventoryView row) =>
                              AppSearchableSelectOption<String>(
                                value: row.productId,
                                label: row.productName,
                                subtitle: 'SKU: ${row.sku}',
                                searchText: '${row.sku} ${row.productName}',
                                leadingIcon: Icons.inventory_2_outlined,
                              ))
                          .toList(growable: false),
                      onChanged: (String value) {
                        setState(() => _selectedProductId = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_adjustRows.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: const Text(
                          'No hay productos disponibles para este almacén.',
                        ),
                      ),

                    // Product Card
                    if (selectedProduct != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: _buildProductImage(selectedProduct),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedProduct.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E293B)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          'SKU: ${selectedProduct.sku}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.payments_outlined,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            productPrice,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.layers_outlined,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Stock: ${currentStock.toStringAsFixed(0)} uds',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Movement Type
                    const Text(
                      'Tipo de Movimiento',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MovementTypeBtn(
                              label: 'Entrada',
                              icon: Icons.add_circle_rounded,
                              isSelected: isEntryMovement,
                              color: const Color(0xFF10B981),
                              onTap: () => _updateMovementKind(
                                PosInventoryMovementDialog.kindEntry,
                              ),
                              isDark: isDark,
                            ),
                          ),
                          Expanded(
                            child: _MovementTypeBtn(
                              label: 'Salida',
                              icon: Icons.remove_circle_rounded,
                              isSelected: _movementKind ==
                                  PosInventoryMovementDialog.kindOutput,
                              color: const Color(0xFFF43F5E),
                              onTap: () => _updateMovementKind(
                                PosInventoryMovementDialog.kindOutput,
                              ),
                              isDark: isDark,
                            ),
                          ),
                          if (widget.allowTransfer)
                            Expanded(
                              child: _MovementTypeBtn(
                                label: 'Transferir',
                                icon: Icons.compare_arrows_rounded,
                                isSelected: isTransferMovement,
                                color: const Color(0xFF2563EB),
                                onTap: () => _updateMovementKind(
                                  PosInventoryMovementDialog.kindTransfer,
                                ),
                                isDark: isDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Qty and Reason
                    if (!isTransferMovement)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cantidad',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _qtyCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    filled: true,
                                    fillColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppSearchableSelectField<String>(
                                  label: 'Motivo',
                                  value: _selectedReasonCode,
                                  enableSearch: selectableReasons.length >= 8,
                                  searchHintText: 'Buscar motivo',
                                  hintText: 'Selecciona un motivo',
                                  options: selectableReasons
                                      .map((InventoryMovementReason reason) =>
                                          AppSearchableSelectOption<String>(
                                            value: reason.code,
                                            label: reason.label,
                                          ))
                                      .toList(growable: false),
                                  onChanged: (String value) {
                                    setState(() => _selectedReasonCode = value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cantidad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _qtyCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (isTransferMovement) ...<Widget>[
                      const SizedBox(height: 16),
                      if (_hasFixedTransferDestination)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.storefront_outlined,
                                size: 18,
                                color: Color(0xFF1D4ED8),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Destino: ${fixedDestinationName.isEmpty ? _resolvedFixedTransferDestinationId : fixedDestinationName}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (transferDestinations.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFECACA),
                            ),
                          ),
                          child: const Text(
                            'No hay otro almacén activo para transferir.',
                            style: TextStyle(
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        AppSearchableSelectField<String>(
                          label: 'Almacén destino',
                          value: _selectedDestinationWarehouseId,
                          enabled: !_loadingRows,
                          hintText: 'Selecciona almacén destino',
                          searchHintText: 'Buscar almacén',
                          options: transferDestinations
                              .map(
                                (InventoryMovementWarehouseOption row) =>
                                    AppSearchableSelectOption<String>(
                                  value: row.id,
                                  label: row.name,
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (String value) {
                            setState(
                                () => _selectedDestinationWarehouseId = value);
                          },
                        ),
                    ],
                    const SizedBox(height: 24),

                    // Notes
                    const Text(
                      'Notas (Opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText:
                            'Escribe un comentario sobre este movimiento...',
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.blueGrey[600],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _loadingRows ? null : _handleApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.done_rounded, size: 20),
                    label: Text(
                      widget.confirmLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateMovementKind(String kind) {
    if (_movementKind == kind) {
      return;
    }
    setState(() {
      _movementKind = kind;
      _ensureReasonForCurrentMode();
      _ensureTransferDestinationWarehouse();
    });
    if (kind == PosInventoryMovementDialog.kindTransfer &&
        _hasFixedTransferDestination) {
      final String currentWarehouseId = (_selectedWarehouseId ?? '').trim();
      if (currentWarehouseId == _resolvedFixedTransferDestinationId) {
        String? fallbackWarehouseId;
        for (final InventoryMovementWarehouseOption row
            in widget.warehouseOptions) {
          if (row.id != _resolvedFixedTransferDestinationId) {
            fallbackWarehouseId = row.id;
            break;
          }
        }
        if (fallbackWarehouseId != null) {
          unawaited(_onWarehouseChanged(fallbackWarehouseId));
        }
      }
    }
  }

  void _reindexRows() {
    _rowByProductId
      ..clear()
      ..addEntries(_adjustRows.map(
        (InventoryView row) =>
            MapEntry<String, InventoryView>(row.productId, row),
      ));
  }

  Future<void> _onWarehouseChanged(String? warehouseId) async {
    if (warehouseId == null ||
        warehouseId.trim().isEmpty ||
        warehouseId == _selectedWarehouseId ||
        widget.loadAdjustRowsForWarehouse == null) {
      return;
    }
    setState(() {
      _selectedWarehouseId = warehouseId;
      _loadingRows = true;
      _ensureTransferDestinationWarehouse();
    });

    try {
      final List<InventoryView> rows =
          await widget.loadAdjustRowsForWarehouse!(warehouseId);
      if (!mounted) {
        return;
      }
      setState(() {
        _adjustRows = rows;
        _reindexRows();
        if (_adjustRows.isEmpty) {
          _selectedProductId = '';
        } else {
          final bool containsSelected =
              _rowByProductId.containsKey(_selectedProductId);
          if (!containsSelected) {
            _selectedProductId = _adjustRows.first.productId;
          }
        }
        _ensureTransferDestinationWarehouse();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el almacén.')),
        );
    } finally {
      if (mounted) {
        setState(() => _loadingRows = false);
      }
    }
  }

  void _handleApply() {
    if (widget.warehouseOptions.isNotEmpty &&
        (_selectedWarehouseId == null ||
            _selectedWarehouseId!.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un almacén.')),
      );
      return;
    }
    if (_selectedProductId.trim().isEmpty ||
        !_rowByProductId.containsKey(_selectedProductId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto.')),
      );
      return;
    }

    final double? qty =
        double.tryParse(_qtyCtrl.text.trim().replaceAll(',', '.'));
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad valida.')),
      );
      return;
    }
    final bool isTransferMovement =
        _movementKind == PosInventoryMovementDialog.kindTransfer;
    if (!isTransferMovement && _selectedReasonCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un motivo.')),
      );
      return;
    }
    if (isTransferMovement) {
      final String sourceWarehouseId = (_selectedWarehouseId ?? '').trim();
      final String destinationWarehouseId = _resolveTransferDestinationId();
      if (destinationWarehouseId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selecciona el almacén destino de la transferencia.'),
          ),
        );
        return;
      }
      if (destinationWarehouseId == sourceWarehouseId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El destino debe ser diferente al almacén origen.'),
          ),
        );
        return;
      }
    }

    final double currentStock = _rowByProductId[_selectedProductId]?.qty ?? 0;
    Navigator.pop(context, {
      'warehouseId': _selectedWarehouseId,
      'destinationWarehouseId': _selectedDestinationWarehouseId,
      'productId': _selectedProductId,
      'movementKind': _movementKind,
      'isEntry': _movementKind == PosInventoryMovementDialog.kindEntry,
      'qty': qty,
      'currentStock': currentStock,
      'reasonCode': isTransferMovement ? 'transfer' : _selectedReasonCode,
      'note': _noteCtrl.text.trim(),
    });
  }

  List<InventoryMovementWarehouseOption> _availableDestinationWarehouses() {
    final String sourceWarehouseId = (_selectedWarehouseId ?? '').trim();
    final String fixedDestination = _resolvedFixedTransferDestinationId;
    return widget.warehouseOptions
        .where((InventoryMovementWarehouseOption row) {
      if (row.id == sourceWarehouseId) {
        return false;
      }
      if (fixedDestination.isNotEmpty && row.id != fixedDestination) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  void _ensureTransferDestinationWarehouse() {
    final bool isTransferMovement =
        _movementKind == PosInventoryMovementDialog.kindTransfer;
    if (!isTransferMovement) {
      _selectedDestinationWarehouseId = null;
      return;
    }
    if (_hasFixedTransferDestination) {
      _selectedDestinationWarehouseId = _resolvedFixedTransferDestinationId;
      return;
    }
    final List<InventoryMovementWarehouseOption> options =
        _availableDestinationWarehouses();
    if (options.isEmpty) {
      _selectedDestinationWarehouseId = null;
      return;
    }
    final bool currentIsValid = options.any(
      (InventoryMovementWarehouseOption row) =>
          row.id == _selectedDestinationWarehouseId,
    );
    if (!currentIsValid) {
      _selectedDestinationWarehouseId = options.first.id;
    }
  }

  String _resolveTransferDestinationId() {
    if (_hasFixedTransferDestination) {
      return _resolvedFixedTransferDestinationId;
    }
    return (_selectedDestinationWarehouseId ?? '').trim();
  }

  String _warehouseNameById(String warehouseId) {
    final String id = warehouseId.trim();
    if (id.isEmpty) {
      return '';
    }
    for (final InventoryMovementWarehouseOption row
        in widget.warehouseOptions) {
      if (row.id == id) {
        return row.name;
      }
    }
    return '';
  }

  void _ensureReasonForCurrentMode() {
    if (_movementKind == PosInventoryMovementDialog.kindTransfer) {
      _selectedReasonCode = 'transfer';
      return;
    }
    final List<InventoryMovementReason> reasons =
        _movementKind == PosInventoryMovementDialog.kindEntry
            ? widget.entryReasons
            : widget.outputReasons;
    if (reasons.isEmpty) {
      _selectedReasonCode = null;
      return;
    }
    final bool hasCurrent = reasons.any(
      (InventoryMovementReason row) => row.code == _selectedReasonCode,
    );
    if (!hasCurrent) {
      _selectedReasonCode = reasons.first.code;
    }
  }

  Widget _buildProductImage(InventoryView product) {
    final String? path = product.imagePath?.trim();
    if (path == null || path.isEmpty) {
      return const Center(
          child: Icon(Icons.inventory_2_outlined, color: Colors.grey));
    }
    final File file = File(path);
    if (!file.existsSync()) {
      return const Center(
        child: Icon(Icons.inventory_2_outlined, color: Colors.grey),
      );
    }
    return Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.grey),
        );
      },
    );
  }
}

class _MovementTypeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _MovementTypeBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : Colors.black87)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
