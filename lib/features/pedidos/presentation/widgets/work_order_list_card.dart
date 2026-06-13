import 'package:flutter/material.dart';

import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../data/pedidos_local_datasource.dart';
import 'work_order_payment_variants.dart';
import 'work_order_priority_badge.dart';
import 'work_order_status_badge.dart';

class WorkOrderListCard extends StatelessWidget {
  const WorkOrderListCard({
    super.key,
    required this.item,
    required this.currencyConfig,
    required this.paymentDisplayConfig,
    required this.onTap,
  });

  final WorkOrderListItem item;
  final AppCurrencyConfig currencyConfig;
  final WorkOrderPaymentDisplayConfig paymentDisplayConfig;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isCancelled = item.status == WorkOrderStatusCatalog.cancelled;
    final bool isLate = _isLate(item);
    final bool isDueToday = _isDueToday(item);
    final WorkOrderStatusColors statusColors =
        workOrderStatusColorsFor(item.status);
    final Color cardColor =
        isCancelled ? const Color(0xFFF8FAFC) : Colors.white;
    final Color borderColor = isCancelled
        ? const Color(0xFFFECACA)
        : isLate
            ? const Color(0xFFFECACA)
            : const Color(0xFFE2E8F0);
    final Color headerColor = isCancelled
        ? const Color(0xFFF8FAFC)
        : statusColors.background.withValues(alpha: 0.72);
    final Color titleColor =
        isCancelled ? const Color(0xFF64748B) : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isCancelled
                    ? const Color(0xFFB91C1C).withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: isCancelled ? 8 : 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    width: 6,
                    color: statusColors.foreground,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                            decoration: BoxDecoration(
                              color: headerColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCancelled
                                    ? const Color(0xFFFECACA)
                                    : statusColors.background,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: isCancelled ? 0.7 : 0.88,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.95,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              item.folio,
                                              style: const TextStyle(
                                                color: Color(0xFF475569),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ),
                                          if (isCancelled) ...<Widget>[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEE2E2),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'CANCELADO',
                                                style: TextStyle(
                                                  color: Color(0xFFB91C1C),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.customerName ??
                                            'Pedido sin cliente',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCancelled
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF475569),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    WorkOrderStatusBadge(status: item.status),
                                    const SizedBox(height: 6),
                                    WorkOrderPriorityBadge(
                                        priority: item.priority),
                                    const SizedBox(height: 6),
                                    _PaymentStatePill(
                                      status: item.paymentStatus,
                                    ),
                                    if (isLate || isDueToday) ...<Widget>[
                                      const SizedBox(height: 6),
                                      _DueStatePill(
                                        label:
                                            isLate ? 'Vencido' : 'Entrega hoy',
                                        color: isLate
                                            ? const Color(0xFFB91C1C)
                                            : const Color(0xFFEA580C),
                                        backgroundColor: isLate
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFFFEDD5),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isCancelled
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: <Widget>[
                              _MetaPill(
                                icon: Icons.shopping_bag_outlined,
                                text: item.itemCount == 1
                                    ? item.itemSummary
                                    : '${item.itemCount} productos',
                                isMuted: isCancelled,
                              ),
                              _MetaPill(
                                icon: Icons.badge_outlined,
                                text: item.assignmentSummary,
                                isMuted: isCancelled,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isCancelled
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFFFAFCFF),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: _InfoColumn(
                                    title: 'Valores del pedido',
                                    rows: _buildValueRows(
                                        isCancelled: isCancelled),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 86,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  color: const Color(0xFFE2E8F0),
                                ),
                                Expanded(
                                  child: _InfoColumn(
                                    title: 'Fechas',
                                    rows: <Widget>[
                                      _InfoLine(
                                        icon: Icons.edit_calendar_outlined,
                                        text:
                                            'Pedido: ${_date(item.createdAt)}',
                                        color: isCancelled
                                            ? const Color(0xFF94A3B8)
                                            : null,
                                        muted: isCancelled,
                                      ),
                                      const SizedBox(height: 8),
                                      _InfoLine(
                                        icon: Icons.event_outlined,
                                        text: item.dueAt == null
                                            ? 'Entrega: Sin fecha'
                                            : 'Entrega: ${_date(item.dueAt!)}',
                                        color: isCancelled
                                            ? const Color(0xFF94A3B8)
                                            : isLate
                                                ? const Color(0xFFB91C1C)
                                                : isDueToday
                                                    ? const Color(0xFFEA580C)
                                                    : null,
                                        muted: isCancelled,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isLate(WorkOrderListItem value) {
    final DateTime? dueAt = value.dueAt;
    if (dueAt == null) {
      return false;
    }
    if (!WorkOrderStatusCatalog.activeStatuses.contains(value.status)) {
      return false;
    }
    return dueAt.isBefore(DateTime.now());
  }

  bool _isDueToday(WorkOrderListItem value) {
    final DateTime? dueAt = value.dueAt;
    if (dueAt == null) {
      return false;
    }
    if (!WorkOrderStatusCatalog.activeStatuses.contains(value.status)) {
      return false;
    }
    final DateTime now = DateTime.now();
    return dueAt.year == now.year &&
        dueAt.month == now.month &&
        dueAt.day == now.day;
  }

  String _date(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  List<Widget> _buildValueRows({required bool isCancelled}) {
    final List<WorkOrderPaymentValue> variants = item.paymentValues.isEmpty
        ? buildWorkOrderPaymentVariants(
            totals: item.orderTotalCosts,
            currencyConfig: currencyConfig,
            paymentDisplayConfig: paymentDisplayConfig,
          )
        : item.paymentValues;
    if (variants.isEmpty) {
      return <Widget>[
        _InfoLine(
          icon: Icons.account_balance_wallet_outlined,
          text: 'Sin valor calculado',
          muted: isCancelled,
        ),
      ];
    }

    return variants
        .map(
          (WorkOrderPaymentValue row) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _InfoLine(
              icon: _iconForVariant(row.label),
              text:
                  '${row.label}: ${_money(row.amountCents, row.currencyCode)}',
              color: isCancelled
                  ? const Color(0xFF64748B)
                  : _colorForVariant(row.label),
              muted: isCancelled,
            ),
          ),
        )
        .toList(growable: false);
  }

  String _money(int cents, String currencyCode) {
    return '${_symbolFor(currencyCode)}${(cents / 100).toStringAsFixed(2)}';
  }

  IconData _iconForVariant(String label) {
    final String normalized = label.toLowerCase();
    if (normalized.contains('transfer')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (normalized.contains('efectivo')) {
      return Icons.payments_outlined;
    }
    return Icons.attach_money_rounded;
  }

  Color _colorForVariant(String label) {
    final String normalized = label.toLowerCase();
    if (normalized.contains('transfer')) {
      return const Color(0xFF059669);
    }
    if (normalized.contains('efectivo')) {
      return const Color(0xFF1152D4);
    }
    return const Color(0xFF0F172A);
  }

  String _symbolFor(String currencyCode) {
    switch (currencyCode.trim().toUpperCase()) {
      case 'USD':
        return r'$';
      case 'EUR':
        return '€';
      case 'CUP':
        return '₱';
      default:
        return '${currencyCode.trim().toUpperCase()} ';
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.text,
    this.isMuted = false,
  });

  final IconData icon;
  final String text;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isMuted ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isMuted ? const Color(0xFFE5E7EB) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 15,
            color: isMuted ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color:
                  isMuted ? const Color(0xFF64748B) : const Color(0xFF334155),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
    this.color,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final Color? color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: color ??
              (muted ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color ??
                  (muted ? const Color(0xFF64748B) : const Color(0xFF475569)),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }
}

class _DueStatePill extends StatelessWidget {
  const _DueStatePill({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PaymentStatePill extends StatelessWidget {
  const _PaymentStatePill({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final ({Color bg, Color fg, String text}) config =
        _paymentPillConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        config.text,
        style: TextStyle(
          color: config.fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

({Color bg, Color fg, String text}) _paymentPillConfig(String status) {
  switch (status) {
    case WorkOrderPaymentStatusCatalog.paid:
      return (
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF047857),
        text: 'Cobrado',
      );
    case WorkOrderPaymentStatusCatalog.partial:
      return (
        bg: const Color(0xFFFEF3C7),
        fg: const Color(0xFFB45309),
        text: 'Pago parcial',
      );
    case WorkOrderPaymentStatusCatalog.unpaid:
    default:
      return (
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFFB91C1C),
        text: 'Pend. cobro',
      );
  }
}
