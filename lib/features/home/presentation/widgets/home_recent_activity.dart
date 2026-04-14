import 'package:flutter/material.dart';
import '../../../reportes/data/reportes_local_datasource.dart';

class HomeRecentActivity extends StatelessWidget {
  final List<RecentSaleStat> recentSales;
  final List<RecentSessionClosureStat> recentSessionClosures;
  final List<IpvReportSummaryStat> recentIpvReports;
  final List<RecentAuditActivityStat> recentAuditActivities;
  final String currencySymbol;
  final String Function(int) moneyFormatter;
  final VoidCallback? onViewAllTap;
  final VoidCallback? onCardTap;
  final int? maxItems;

  const HomeRecentActivity({
    super.key,
    required this.recentSales,
    required this.recentSessionClosures,
    required this.recentIpvReports,
    required this.recentAuditActivities,
    required this.currencySymbol,
    required this.moneyFormatter,
    this.onViewAllTap,
    this.onCardTap,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<_ActivityEntry> entries = _buildEntries();
    final int? limit = maxItems;
    final List<_ActivityEntry> visibleEntries = limit == null
        ? entries
        : entries.take(limit < 0 ? 0 : limit).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVIDAD RECIENTE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: 1.5,
              ),
            ),
            if (onViewAllTap != null)
              TextButton(
                onPressed: onViewAllTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1152D4),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ver Todo'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCardTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
                boxShadow: isDark
                    ? <BoxShadow>[]
                    : <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                children: visibleEntries.isEmpty
                    ? <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No hay actividad reciente para mostrar.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ]
                    : visibleEntries.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final _ActivityEntry row = entry.value;
                        return Column(
                          children: [
                            _buildActivityItem(row: row, isDark: isDark),
                            if (idx < visibleEntries.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF8FAFC),
                              ),
                          ],
                        );
                      }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_ActivityEntry> _buildEntries() {
    final List<_ActivityEntry> rows = <_ActivityEntry>[
      ...recentSales.map((RecentSaleStat sale) {
        return _ActivityEntry(
          timestamp: sale.createdAt,
          title: 'Venta ${sale.folio}',
          subtitle: '${sale.cashierUsername} • ${sale.warehouseName}',
          status: 'COMPLETADO',
          amount: moneyFormatter(sale.totalCents),
          icon: Icons.receipt_long_rounded,
          accentColor: const Color(0xFF3B82F6),
          isPositiveAmount: true,
        );
      }),
      ...recentSessionClosures.map((RecentSessionClosureStat closure) {
        return _ActivityEntry(
          timestamp: closure.closedAt,
          title: 'Cierre de caja',
          subtitle: '${closure.cashierUsername} • ${closure.terminalName}',
          status: 'CAJA CERRADA',
          amount:
              _formatMoney(closure.closingCashCents, closure.currencySymbol),
          icon: Icons.point_of_sale_rounded,
          accentColor: const Color(0xFF0EA5E9),
          isPositiveAmount: false,
        );
      }),
      ...recentIpvReports.map((IpvReportSummaryStat report) {
        final DateTime eventDate = report.closedAt ?? report.openedAt;
        final bool isClosed = report.status.trim().toLowerCase() == 'closed';
        return _ActivityEntry(
          timestamp: eventDate,
          title: 'IPV ${report.terminalName}',
          subtitle: 'Sesión ${report.sessionId}',
          status: isClosed ? 'IPV CERRADO' : 'IPV ABIERTO',
          amount: _formatMoney(report.totalAmountCents, report.currencySymbol),
          icon: Icons.inventory_2_rounded,
          accentColor: const Color(0xFFF59E0B),
          isPositiveAmount: true,
        );
      }),
      ...recentAuditActivities.map((RecentAuditActivityStat audit) {
        final _AuditVisual visual = _auditVisualForAction(audit.action);
        return _ActivityEntry(
          timestamp: audit.createdAt,
          title: audit.title,
          subtitle: audit.subtitle,
          status: audit.status,
          amount: '-',
          icon: visual.icon,
          accentColor: visual.color,
          isPositiveAmount: false,
        );
      }),
    ];

    rows.sort(
      (_ActivityEntry a, _ActivityEntry b) =>
          b.timestamp.compareTo(a.timestamp),
    );
    return rows;
  }

  String _formatMoney(int cents, String? symbol) {
    final String cleanSymbol = (symbol ?? '').trim();
    final String effectiveSymbol =
        cleanSymbol.isNotEmpty ? cleanSymbol : currencySymbol;
    return '$effectiveSymbol${(cents / 100).toStringAsFixed(2)}';
  }

  _AuditVisual _auditVisualForAction(String action) {
    final String safeAction = action.trim().toUpperCase();
    switch (safeAction) {
      case 'TPV_TERMINAL_CREATED':
        return const _AuditVisual(
          icon: Icons.add_business_rounded,
          color: Color(0xFF16A34A),
        );
      case 'TPV_TERMINAL_UPDATED':
        return const _AuditVisual(
          icon: Icons.edit_note_rounded,
          color: Color(0xFF0284C7),
        );
      case 'TPV_TERMINAL_DEACTIVATED':
        return const _AuditVisual(
          icon: Icons.domain_disabled_rounded,
          color: Color(0xFFDC2626),
        );
      case 'TPV_SESSION_OPENED':
        return const _AuditVisual(
          icon: Icons.play_circle_fill_rounded,
          color: Color(0xFF0EA5E9),
        );
      case 'TPV_SESSION_CLOSED':
        return const _AuditVisual(
          icon: Icons.stop_circle_rounded,
          color: Color(0xFFEA580C),
        );
      case 'TPV_SESSION_AUTO_CLOSED':
        return const _AuditVisual(
          icon: Icons.auto_mode_rounded,
          color: Color(0xFF7C3AED),
        );
      default:
        return const _AuditVisual(
          icon: Icons.history_rounded,
          color: Color(0xFF64748B),
        );
    }
  }

  String _formatTimestamp(DateTime value) {
    final DateTime local = value.toLocal();
    final String day = local.day.toString().padLeft(2, '0');
    final String month = local.month.toString().padLeft(2, '0');
    final String hour = local.hour.toString().padLeft(2, '0');
    final String minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }

  Widget _buildActivityItem({
    required _ActivityEntry row,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? row.accentColor.withValues(alpha: 0.2)
                  : row.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              row.icon,
              color: row.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  row.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(row.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${row.isPositiveAmount ? '+' : ''}${row.amount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                row.status,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: row.accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.amount,
    required this.icon,
    required this.accentColor,
    required this.isPositiveAmount,
  });

  final DateTime timestamp;
  final String title;
  final String subtitle;
  final String status;
  final String amount;
  final IconData icon;
  final Color accentColor;
  final bool isPositiveAmount;
}

class _AuditVisual {
  const _AuditVisual({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
