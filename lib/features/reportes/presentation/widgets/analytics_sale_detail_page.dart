import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/db/app_database.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../productos/presentation/productos_providers.dart';
import '../../data/reportes_local_datasource.dart';
import '../../../ventas_pos/presentation/ventas_pos_providers.dart';
import '../../../ventas_pos/domain/sale_models.dart';
import '../reportes_providers.dart';

class AnalyticsSaleDetailPage extends ConsumerStatefulWidget {
  const AnalyticsSaleDetailPage({
    super.key,
    required this.saleId,
    required this.currencySymbol,
  });

  final String saleId;
  final String currencySymbol;

  @override
  ConsumerState<AnalyticsSaleDetailPage> createState() =>
      _AnalyticsSaleDetailPageState();
}

class _AnalyticsSaleDetailPageState
    extends ConsumerState<AnalyticsSaleDetailPage> {
  bool _loading = false;
  SalesAnalyticsSaleDetailStat? detail;
  bool _savingEdit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final SalesAnalyticsSaleDetailStat? result = await ref
          .read(reportesLocalDataSourceProvider)
          .getSaleDetailForAnalytics(widget.saleId);
      if (mounted) {
        setState(() {
          detail = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _show('Error al cargar detalle: $e');
      }
    }
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  String _money(int cents) {
    return '${widget.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  String _qty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.0001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  Future<void> _archiveSale() async {
    if (detail == null) return;
    final session = ref.read(currentSessionProvider);
    final String userId = session?.userId.trim() ?? '';
    if (userId.isEmpty) {
      _show('No hay usuario autenticado para archivar.');
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Archivar venta'),
        content: const Text(
          '¿Estás seguro de archivar esta venta? Se ocultará de los reportes generales.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _savingEdit = true);
    try {
      await ref
          .read(ventasPosLocalDataSourceProvider)
          .archiveSale(saleId: widget.saleId, userId: userId);
      if (mounted) {
        _show('Venta archivada correctamente.');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingEdit = false);
        _show('Error al archivar: $e');
      }
    }
  }

  Future<void> _editSale() async {
    if (detail == null) return;
    final session = ref.read(currentSessionProvider);
    final String userId = session?.userId.trim() ?? '';
    if (userId.isEmpty) {
      _show('No hay usuario autenticado para editar.');
      return;
    }

    final List<Product> products = await ref.read(allProductsProvider.future);
    if (products.isEmpty) {
      _show('No hay productos disponibles para editar esta venta.');
      return;
    }
    final List<_PaymentMethodOption> paymentOptions =
        (await ref.read(paymentMethodOptionsProvider.future))
            .map(
              (method) => _PaymentMethodOption(
                key: method.code,
                label: _paymentMethodLabel(method.code),
              ),
            )
            .toList(growable: false);
    final List<_PaymentMethodOption> safePaymentOptions = paymentOptions.isEmpty
        ? const <_PaymentMethodOption>[
            _PaymentMethodOption(key: 'cash', label: 'Efectivo'),
          ]
        : paymentOptions;

    if (!mounted) return;

    final _EditSalePayload? payload =
        await Navigator.of(context).push<_EditSalePayload>(
      MaterialPageRoute<_EditSalePayload>(
        fullscreenDialog: true,
        builder: (BuildContext ctx) => _EditSaleDialog(
          detail: detail!,
          products: products,
          currencySymbol: widget.currencySymbol,
          paymentMethodOptions: safePaymentOptions,
        ),
      ),
    );

    if (payload == null) return;

    setState(() => _savingEdit = true);
    try {
      await ref.read(ventasPosLocalDataSourceProvider).updateSale(
            UpdateSaleInput(
              saleId: widget.saleId,
              items: payload.items,
              payments: payload.payments,
              userId: userId,
              isConsignmentSale: payload.isConsignmentSale,
            ),
          );
      await _load();
      if (mounted) {
        _show('Venta actualizada correctamente.');
      }
    } catch (e) {
      if (mounted) {
        _show('Error al guardar cambios: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _savingEdit = false);
      }
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method.trim().toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'card':
        return 'Tarjeta';
      case 'transfer':
        return 'Transferencia';
      case 'wallet':
        return 'Billetera';
      case 'consignment':
        return 'Consignación';
      default:
        final String clean = method.trim();
        return clean.isEmpty ? 'Método' : clean;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final session = ref.watch(currentSessionProvider);
    final bool canArchiveSale = session?.isAdmin ?? false;
    final bool canEditSale = session?.isAdmin ?? false;
    final SalesAnalyticsSaleDetailStat? current = detail;

    return AppScaffold(
      title: 'Detalle de Venta',
      currentRoute: '/reportes',
      showDrawer: false,
      appBarActions: <Widget>[
        if (canEditSale)
          IconButton(
            tooltip: 'Editar venta',
            onPressed: _loading || _savingEdit ? null : _editSale,
            icon: _savingEdit
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined),
          ),
        if (canArchiveSale)
          IconButton(
            tooltip: 'Archivar venta',
            onPressed: _loading || _savingEdit ? null : _archiveSale,
            icon: const Icon(Icons.archive_outlined),
          ),
      ],
      appBarLeading: IconButton(
        tooltip: 'Volver',
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
            return;
          }
          context.go('/reportes');
        },
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : current == null
              ? const Center(child: Text('No se encontró la venta.'))
              : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool compact = constraints.maxWidth < 900;
                    final int paidCents = current.payments.fold<int>(
                      0,
                      (int sum, SalesAnalyticsSalePaymentStat row) =>
                          sum + row.amountCents,
                    );
                    final bool isConsignmentSale = current.payments.isEmpty ||
                        current.payments.any(
                          (SalesAnalyticsSalePaymentStat row) =>
                              row.method.trim().toLowerCase() == 'consignment',
                        );
                    final int pendingCents = current.totalCents - paidCents;
                    final Color pageBg = isDark
                        ? const Color(0xFF0B1220)
                        : const Color(0xFFF7F9FB);
                    final Color cardBg =
                        isDark ? const Color(0xFF111827) : Colors.white;
                    final Color borderColor = isDark
                        ? const Color(0xFF263244)
                        : const Color(0xFFE2E8F0);
                    final Color textMuted = isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF5B6472);

                    Widget transactionCard() {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _surfaceDecoration(
                          isDark: isDark,
                          bgColor: cardBg,
                          borderColor: borderColor,
                          radius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'ID DE TRANSACCIÓN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              current.sale.folio,
                              style: const TextStyle(
                                fontSize: 26 / 2,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1152D4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 10,
                              children: <Widget>[
                                _metaCell(
                                  label: 'FECHA Y HORA',
                                  value:
                                      _formatDateTime(current.sale.createdAt),
                                  mutedColor: textMuted,
                                ),
                                _metaCell(
                                  label: 'CANAL',
                                  value: current.sale.channel == 'pos'
                                      ? 'Tienda Física'
                                      : 'Venta Directa',
                                  mutedColor: textMuted,
                                ),
                                _metaCell(
                                  label: 'ALMACÉN',
                                  value: current.sale.warehouseName,
                                  mutedColor: textMuted,
                                ),
                                _metaCell(
                                  label: 'TPV / CAJA',
                                  value: (current.sale.terminalName ?? '')
                                          .trim()
                                          .isEmpty
                                      ? 'No aplica'
                                      : current.sale.terminalName!,
                                  mutedColor: textMuted,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    Widget customerCard() {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _surfaceDecoration(
                          isDark: isDark,
                          bgColor: cardBg,
                          borderColor: borderColor,
                          radius: 14,
                        ),
                        child: Column(
                          children: <Widget>[
                            _profileRow(
                              label: 'CLIENTE',
                              value: current.sale.customerName ?? 'Sin cliente',
                              icon: Icons.person_rounded,
                              iconBg: const Color(0xFFDDEAFE),
                              iconColor: const Color(0xFF1E40AF),
                              mutedColor: textMuted,
                            ),
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 12),
                            _profileRow(
                              label: 'EMPLEADO',
                              value: current.sale.cashierUsername,
                              icon: Icons.badge_rounded,
                              iconBg: const Color(0xFFE5EEFF),
                              iconColor: const Color(0xFF1152D4),
                              mutedColor: textMuted,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                _show('Historial de cliente: próximamente.');
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                side: BorderSide(color: borderColor),
                                foregroundColor: const Color(0xFF1152D4),
                              ),
                              icon: const Icon(Icons.contact_page_outlined),
                              label: const Text('Ver Historial de Cliente'),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget productsCard() {
                      return Container(
                        decoration: _surfaceDecoration(
                          isDark: isDark,
                          bgColor: cardBg,
                          borderColor: borderColor,
                          radius: 14,
                        ),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 14, 10),
                              child: Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      'Productos Vendidos',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1A1152D4),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${current.lines.length} ITEMS',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1152D4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              color: isDark
                                  ? const Color(0xFF162133)
                                  : const Color(0xFFF2F4F6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: compact ? 5 : 4,
                                    child: Text(
                                      'PRODUCTO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                  if (!compact)
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'SKU',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'TOTAL',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...current.lines.map(
                              (SalesAnalyticsSaleLineStat row) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      flex: compact ? 5 : 4,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            row.productName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_qty(row.qty)} x ${_money(row.unitPriceCents)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!compact)
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          row.sku,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textMuted,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _money(row.lineTotalCents),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1152D4),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Widget paymentsCard() {
                      final Color statusColor;
                      final String statusLabel;
                      if (isConsignmentSale) {
                        statusColor = const Color(0xFFB45309);
                        statusLabel = 'Consignación';
                      } else if (pendingCents <= 0) {
                        statusColor = const Color(0xFF059669);
                        statusLabel = 'Pagado';
                      } else if (paidCents > 0) {
                        statusColor = const Color(0xFF2563EB);
                        statusLabel = 'Pago parcial';
                      } else {
                        statusColor = const Color(0xFFDC2626);
                        statusLabel = 'Pendiente';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _surfaceDecoration(
                          isDark: isDark,
                          bgColor: cardBg,
                          borderColor: borderColor,
                          radius: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1152D4),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: const Icon(
                                    Icons.payments_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'MÉTODO DE PAGO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w700,
                                          color: textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        isConsignmentSale
                                            ? 'Consignación'
                                            : (current.payments.isEmpty
                                                ? 'Sin pagos'
                                                : _paymentMethodLabel(current
                                                    .payments.first.method)),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      'Estado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textMuted,
                                      ),
                                    ),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (current.payments.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              ...current.payments.map(
                                (SalesAnalyticsSalePaymentStat row) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          _paymentMethodLabel(row.method),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: textMuted,
                                          ),
                                        ),
                                      ),
                                      if ((row.transactionId ?? '')
                                          .trim()
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            '#${row.transactionId}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        _money(row.amountCents),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    Widget actionsCard() {
                      return Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Imprimir Ticket',
                                  icon: Icons.print_outlined,
                                  bgColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE9EDF2),
                                  textColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  onTap: () => _show(
                                      'Impresión de ticket: próximamente.'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Enviar por Email',
                                  icon: Icons.mail_outline_rounded,
                                  bgColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFE9EDF2),
                                  textColor: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F2937),
                                  onTap: () =>
                                      _show('Envío por email: próximamente.'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildActionButton(
                            label: 'Solicitar Devolución',
                            icon: Icons.assignment_return_outlined,
                            bgColor: const Color(0xFFA63A00),
                            textColor: Colors.white,
                            isFullWidth: true,
                            onTap: () =>
                                _show('Flujo de devolución: próximamente.'),
                          ),
                        ],
                      );
                    }

                    Widget totalCard() {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: _surfaceDecoration(
                          isDark: isDark,
                          bgColor: cardBg,
                          borderColor: borderColor,
                          radius: 14,
                        ).copyWith(
                          border: Border(
                            top: const BorderSide(
                              color: Color(0xFF1152D4),
                              width: 3,
                            ),
                            left: BorderSide(color: borderColor),
                            right: BorderSide(color: borderColor),
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            _summaryRow(
                              label: 'Subtotal',
                              value: _money(current.subtotalCents),
                              color: textMuted,
                            ),
                            const SizedBox(height: 10),
                            _summaryRow(
                              label: 'IVA',
                              value: _money(current.taxCents),
                              color: textMuted,
                            ),
                            const SizedBox(height: 12),
                            Divider(color: borderColor, height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'TOTAL DE LA VENTA',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Incluye impuestos y cargos',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _money(current.totalCents),
                                  style: TextStyle(
                                    fontSize: compact ? 29 / 2 : 36 / 2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (!isConsignmentSale) ...<Widget>[
                              const SizedBox(height: 10),
                              _summaryRow(
                                label: 'Pagado',
                                value: _money(paidCents),
                                color: textMuted,
                              ),
                              const SizedBox(height: 6),
                              _summaryRow(
                                label: 'Pendiente',
                                value: _money(pendingCents),
                                color: textMuted,
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ColoredBox(
                      color: pageBg,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 12 : 20,
                          12,
                          compact ? 12 : 20,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            transactionCard(),
                            const SizedBox(height: 12),
                            customerCard(),
                            const SizedBox(height: 12),
                            productsCard(),
                            const SizedBox(height: 12),
                            if (compact) ...<Widget>[
                              paymentsCard(),
                              const SizedBox(height: 10),
                              actionsCard(),
                              const SizedBox(height: 10),
                              totalCard(),
                            ] else ...<Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      children: <Widget>[
                                        paymentsCard(),
                                        const SizedBox(height: 10),
                                        actionsCard(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: totalCard()),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDateTime(DateTime value) {
    final DateTime local = value.toLocal();
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final String day = local.day.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day ${months[local.month - 1]} ${local.year}, $hour:$minute';
  }

  BoxDecoration _surfaceDecoration({
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    double radius = 12,
  }) {
    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: isDark
          ? null
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
    );
  }

  Widget _metaCell({
    required String label,
    required String value,
    required Color mutedColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: mutedColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _profileRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color mutedColor,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: mutedColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodOption {
  const _PaymentMethodOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}

class _EditSalePayload {
  const _EditSalePayload({
    required this.items,
    required this.payments,
    required this.isConsignmentSale,
  });

  final List<SaleItemInput> items;
  final List<PaymentInput> payments;
  final bool isConsignmentSale;
}

class _EditSaleDialog extends StatefulWidget {
  const _EditSaleDialog({
    required this.detail,
    required this.products,
    required this.currencySymbol,
    required this.paymentMethodOptions,
  });

  final SalesAnalyticsSaleDetailStat detail;
  final List<Product> products;
  final String currencySymbol;
  final List<_PaymentMethodOption> paymentMethodOptions;

  @override
  State<_EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<_EditSaleDialog> {
  late final Map<String, Product> _productsById;
  late final List<_EditableSaleLineForm> _lineForms;
  late final List<_EditableSalePaymentForm> _paymentForms;
  late bool _isConsignmentSale;

  @override
  void initState() {
    super.initState();
    _productsById = <String, Product>{
      for (final Product row in widget.products) row.id: row,
    };
    _lineForms = widget.detail.lines.map((SalesAnalyticsSaleLineStat row) {
      return _EditableSaleLineForm(
        productId: row.productId,
        qtyText: _formatQty(row.qty),
        unitPriceText: _formatCents(row.unitPriceCents),
        taxRateBps: row.taxRateBps,
      );
    }).toList(growable: true);
    if (_lineForms.isEmpty) {
      final Product fallback = widget.products.first;
      _lineForms.add(
        _EditableSaleLineForm(
          productId: fallback.id,
          qtyText: '1',
          unitPriceText: _formatCents(fallback.priceCents),
          taxRateBps: fallback.taxRateBps,
        ),
      );
    }
    final Set<String> allowedPaymentMethods = widget.paymentMethodOptions
        .map((_PaymentMethodOption row) => row.key)
        .toSet();
    _paymentForms =
        widget.detail.payments.map((SalesAnalyticsSalePaymentStat row) {
      final String normalizedMethod = row.method.trim().toLowerCase();
      return _EditableSalePaymentForm(
        method: allowedPaymentMethods.contains(normalizedMethod)
            ? normalizedMethod
            : widget.paymentMethodOptions.first.key,
        amountText: _formatCents(row.amountCents),
        transactionId: (row.transactionId ?? '').trim(),
        sourceCurrencyCode: row.sourceCurrencyCode,
        sourceAmountCents: row.sourceAmountCents,
      );
    }).toList(growable: true);
    _isConsignmentSale = _paymentForms.isEmpty ||
        _paymentForms.any(
          (_EditableSalePaymentForm row) => row.method == 'consignment',
        );
    if (!_isConsignmentSale && _paymentForms.isEmpty) {
      _paymentForms.add(_EditableSalePaymentForm(method: 'cash'));
    }
  }

  @override
  void dispose() {
    for (final _EditableSaleLineForm row in _lineForms) {
      row.dispose();
    }
    for (final _EditableSalePaymentForm row in _paymentForms) {
      row.dispose();
    }
    super.dispose();
  }

  String _formatQty(double qty) {
    if ((qty - qty.roundToDouble()).abs() < 0.0001) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _formatCents(int cents) {
    return (cents / 100).toStringAsFixed(2);
  }

  int? _parseMoneyToCents(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    final double? value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    return (value * 100).round();
  }

  double? _parseQty(String raw) {
    final String normalized = raw.trim().replaceAll(',', '.');
    final double? value = double.tryParse(normalized);
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    return value;
  }

  int _lineSubtotalCents(_EditableSaleLineForm row) {
    final double qty = _parseQty(row.qtyCtrl.text) ?? 0;
    final int unitPriceCents = _parseMoneyToCents(row.unitPriceCtrl.text) ?? 0;
    return (qty * unitPriceCents).round();
  }

  int _lineTaxCents(_EditableSaleLineForm row) {
    final int subtotal = _lineSubtotalCents(row);
    return (subtotal * row.taxRateBps / 10000).round();
  }

  int _subtotalCents() {
    int total = 0;
    for (final _EditableSaleLineForm row in _lineForms) {
      total += _lineSubtotalCents(row);
    }
    return total;
  }

  int _taxCents() {
    int total = 0;
    for (final _EditableSaleLineForm row in _lineForms) {
      total += _lineTaxCents(row);
    }
    return total;
  }

  int _totalCents() {
    return _subtotalCents() + _taxCents();
  }

  int _paymentsTotalCents() {
    int total = 0;
    for (final _EditableSalePaymentForm row in _paymentForms) {
      total += _parseMoneyToCents(row.amountCtrl.text) ?? 0;
    }
    return total;
  }

  String _money(int cents) {
    return '${widget.currencySymbol}${(cents / 100).toStringAsFixed(2)}';
  }

  void _addLine() {
    final Product product = widget.products.first;
    setState(() {
      _lineForms.add(
        _EditableSaleLineForm(
          productId: product.id,
          qtyText: '1',
          unitPriceText: _formatCents(product.priceCents),
          taxRateBps: product.taxRateBps,
        ),
      );
    });
  }

  void _removeLine(int index) {
    if (_lineForms.length <= 1) {
      return;
    }
    setState(() {
      final _EditableSaleLineForm row = _lineForms.removeAt(index);
      row.dispose();
    });
  }

  void _addPayment() {
    setState(() {
      _paymentForms.add(
        _EditableSalePaymentForm(
          method: 'cash',
          amountText: _formatCents(_totalCents()),
        ),
      );
    });
  }

  void _removePayment(int index) {
    if (_paymentForms.length <= 1) {
      return;
    }
    setState(() {
      final _EditableSalePaymentForm row = _paymentForms.removeAt(index);
      row.dispose();
    });
  }

  void _toggleConsignment(bool value) {
    setState(() {
      _isConsignmentSale = value;
      if (_isConsignmentSale) {
        for (final _EditableSalePaymentForm row in _paymentForms) {
          row.dispose();
        }
        _paymentForms.clear();
      } else if (_paymentForms.isEmpty) {
        _paymentForms.add(
          _EditableSalePaymentForm(
            method: 'cash',
            amountText: _formatCents(_totalCents()),
          ),
        );
      }
    });
  }

  Future<void> _submit() async {
    final List<SaleItemInput> items = <SaleItemInput>[];
    for (final _EditableSaleLineForm row in _lineForms) {
      final String productId = row.productId.trim();
      if (!_productsById.containsKey(productId)) {
        _show('Selecciona un producto válido en cada línea.');
        return;
      }
      final double? qty = _parseQty(row.qtyCtrl.text);
      if (qty == null || qty <= 0) {
        _show('La cantidad debe ser mayor que 0 en todas las líneas.');
        return;
      }
      final int? unitPriceCents = _parseMoneyToCents(row.unitPriceCtrl.text);
      if (unitPriceCents == null || unitPriceCents < 0) {
        _show('El precio unitario es inválido en una línea.');
        return;
      }
      items.add(
        SaleItemInput(
          productId: productId,
          qty: qty,
          unitPriceCents: unitPriceCents,
          taxRateBps: row.taxRateBps,
        ),
      );
    }

    final List<PaymentInput> payments = <PaymentInput>[];
    if (!_isConsignmentSale) {
      if (_paymentForms.isEmpty) {
        _show('Debes registrar al menos un pago.');
        return;
      }
      for (final _EditableSalePaymentForm row in _paymentForms) {
        final String method = row.method.trim().toLowerCase();
        if (method.isEmpty || method == 'consignment') {
          _show('Selecciona un método de pago válido.');
          return;
        }
        final int? amountCents = _parseMoneyToCents(row.amountCtrl.text);
        if (amountCents == null || amountCents < 0) {
          _show('El importe de pago es inválido.');
          return;
        }
        payments.add(
          PaymentInput(
            method: method,
            amountCents: amountCents,
            transactionId: row.transactionCtrl.text.trim().isEmpty
                ? null
                : row.transactionCtrl.text.trim(),
            sourceCurrencyCode: row.sourceCurrencyCode,
            sourceAmountCents: row.sourceAmountCents,
          ),
        );
      }
    }

    Navigator.of(context).pop(
      _EditSalePayload(
        items: items,
        payments: payments,
        isConsignmentSale: _isConsignmentSale,
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  BoxDecoration _cardDecoration({
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    double radius = 14,
  }) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: isDark
          ? null
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int subtotal = _subtotalCents();
    final int tax = _taxCents();
    final int total = subtotal + tax;
    final int paymentsTotal = _paymentsTotalCents();
    final int pending = total - paymentsTotal;
    final Color pageBg =
        isDark ? const Color(0xFF0B1220) : const Color(0xFFF7F9FB);
    final Color cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF263244) : const Color(0xFFE2E8F0);
    final Color mutedText =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6472);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        title: Text('Editar venta ${widget.detail.sale.folio}'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool compact = constraints.maxWidth < 950;

          Widget sectionTitle(String value) {
            return Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: mutedText,
              ),
            );
          }

          Widget productsEditorCard() {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('PRODUCTOS'),
                  const SizedBox(height: 10),
                  ...List<Widget>.generate(_lineForms.length, (int index) {
                    final _EditableSaleLineForm row = _lineForms[index];
                    final bool hasProduct =
                        _productsById.containsKey(row.productId);

                    final Widget productSelector =
                        DropdownButtonFormField<String>(
                      initialValue: hasProduct ? row.productId : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Producto',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.products
                          .map(
                            (Product product) => DropdownMenuItem<String>(
                              value: product.id,
                              child: Text(
                                '${product.name} (${product.sku})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return;
                        }
                        final Product selected = _productsById[value]!;
                        setState(() {
                          row.productId = value;
                          row.taxRateBps = selected.taxRateBps;
                          row.unitPriceCtrl.text = _formatCents(
                            selected.priceCents,
                          );
                        });
                      },
                    );

                    final Widget qtyField = TextFormField(
                      controller: row.qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    );

                    final Widget priceField = TextFormField(
                      controller: row.unitPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    );

                    final Widget removeBtn = IconButton(
                      tooltip: 'Eliminar línea',
                      onPressed: _lineForms.length > 1
                          ? () => _removeLine(index)
                          : null,
                      icon: const Icon(Icons.delete_outline_rounded),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: compact
                          ? Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF162133)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: borderColor),
                              ),
                              child: Column(
                                children: <Widget>[
                                  productSelector,
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Expanded(child: qtyField),
                                      const SizedBox(width: 8),
                                      Expanded(child: priceField),
                                      const SizedBox(width: 2),
                                      removeBtn,
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(flex: 5, child: productSelector),
                                const SizedBox(width: 10),
                                Expanded(flex: 2, child: qtyField),
                                const SizedBox(width: 10),
                                Expanded(flex: 2, child: priceField),
                                const SizedBox(width: 4),
                                removeBtn,
                              ],
                            ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar producto'),
                  ),
                ],
              ),
            );
          }

          Widget paymentsEditorCard() {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  sectionTitle('PAGOS'),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isConsignmentSale,
                    onChanged: _toggleConsignment,
                    title: const Text('Venta en consignación'),
                    subtitle: const Text('Sin pagos iniciales en el momento'),
                  ),
                  const SizedBox(height: 6),
                  if (!_isConsignmentSale) ...<Widget>[
                    ...List<Widget>.generate(_paymentForms.length, (int index) {
                      final _EditableSalePaymentForm row = _paymentForms[index];

                      final Widget methodSelector =
                          DropdownButtonFormField<String>(
                        initialValue: row.method,
                        decoration: const InputDecoration(
                          labelText: 'Método',
                          border: OutlineInputBorder(),
                        ),
                        items: widget.paymentMethodOptions
                            .map(
                              (_PaymentMethodOption option) =>
                                  DropdownMenuItem<String>(
                                value: option.key,
                                child: Text(option.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return;
                          }
                          setState(() => row.method = value);
                        },
                      );

                      final Widget amountField = TextFormField(
                        controller: row.amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Importe',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      );

                      final Widget codeField = TextFormField(
                        controller: row.transactionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          border: OutlineInputBorder(),
                        ),
                      );

                      final Widget removeBtn = IconButton(
                        tooltip: 'Eliminar pago',
                        onPressed: _paymentForms.length > 1
                            ? () => _removePayment(index)
                            : null,
                        icon: const Icon(Icons.delete_outline_rounded),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: compact
                            ? Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF162133)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Column(
                                  children: <Widget>[
                                    methodSelector,
                                    const SizedBox(height: 8),
                                    Row(
                                      children: <Widget>[
                                        Expanded(child: amountField),
                                        const SizedBox(width: 8),
                                        Expanded(child: codeField),
                                        const SizedBox(width: 2),
                                        removeBtn,
                                      ],
                                    ),
                                  ],
                                ),
                              )
                            : Row(
                                children: <Widget>[
                                  Expanded(flex: 3, child: methodSelector),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 2, child: amountField),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 3, child: codeField),
                                  const SizedBox(width: 4),
                                  removeBtn,
                                ],
                              ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addPayment,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar pago'),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'En consignación no se registran pagos iniciales.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          Widget summaryCard() {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ).copyWith(
                border: Border(
                  top: const BorderSide(color: Color(0xFF1152D4), width: 3),
                  left: BorderSide(color: borderColor),
                  right: BorderSide(color: borderColor),
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Column(
                children: <Widget>[
                  _TotalRow(label: 'Subtotal', value: _money(subtotal)),
                  _TotalRow(label: 'Impuesto', value: _money(tax)),
                  const Divider(height: 14),
                  _TotalRow(
                      label: 'Total', value: _money(total), highlight: true),
                  if (!_isConsignmentSale) ...<Widget>[
                    _TotalRow(label: 'Pagado', value: _money(paymentsTotal)),
                    _TotalRow(
                      label: 'Diferencia',
                      value: _money(pending),
                      highlight: pending == 0,
                    ),
                  ],
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                compact ? 12 : 20, 8, compact ? 12 : 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                productsEditorCard(),
                const SizedBox(height: 12),
                if (compact) ...<Widget>[
                  paymentsEditorCard(),
                  const SizedBox(height: 12),
                  summaryCard(),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: paymentsEditorCard()),
                      const SizedBox(width: 12),
                      Expanded(child: summaryCard()),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EditableSaleLineForm {
  _EditableSaleLineForm({
    required this.productId,
    required String qtyText,
    required String unitPriceText,
    required this.taxRateBps,
  })  : qtyCtrl = TextEditingController(text: qtyText),
        unitPriceCtrl = TextEditingController(text: unitPriceText);

  String productId;
  int taxRateBps;
  final TextEditingController qtyCtrl;
  final TextEditingController unitPriceCtrl;

  void dispose() {
    qtyCtrl.dispose();
    unitPriceCtrl.dispose();
  }
}

class _EditableSalePaymentForm {
  _EditableSalePaymentForm({
    required this.method,
    String amountText = '0.00',
    String transactionId = '',
    this.sourceCurrencyCode,
    this.sourceAmountCents,
  })  : amountCtrl = TextEditingController(text: amountText),
        transactionCtrl = TextEditingController(text: transactionId);

  String method;
  final String? sourceCurrencyCode;
  final int? sourceAmountCents;
  final TextEditingController amountCtrl;
  final TextEditingController transactionCtrl;

  void dispose() {
    amountCtrl.dispose();
    transactionCtrl.dispose();
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final Color valueColor = highlight
        ? const Color(0xFF1152D4)
        : Theme.of(context).textTheme.bodyMedium?.color ??
            const Color(0xFF0F172A);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
