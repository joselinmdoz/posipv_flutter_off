import 'package:flutter/material.dart';

import '../../data/tpv_local_datasource.dart';

class TpvSessionHistoryCard extends StatelessWidget {
  const TpvSessionHistoryCard({
    super.key,
    required this.isOpen,
    required this.sessionCode,
    required this.title,
    required this.openingText,
    required this.closingText,
    required this.responsible,
    required this.currencySymbol,
    required this.breakdown,
    required this.closingCashCents,
    required this.currentSalesCents,
    required this.onPrimaryAction,
  });

  final bool isOpen;
  final String sessionCode;
  final String title;
  final String openingText;
  final String closingText;
  final String responsible;
  final String currencySymbol;
  final List<TpvSessionCashBreakdown> breakdown;
  final int closingCashCents;
  final int currentSalesCents;
  final VoidCallback onPrimaryAction;

  String _money(int cents) {
    return '$currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _denominationLabel(int cents) {
    final double value = cents / 100;
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFD8DEE9);
    final Color panelColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F7FC);

    final int breakdownTotal = breakdown.fold<int>(
      0,
      (int sum, TpvSessionCashBreakdown row) => sum + row.subtotalCents,
    );
    final int displayClosingCents =
        breakdownTotal > 0 ? breakdownTotal : closingCashCents;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFFD1FAE5)
                                  : (isDark
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFFEFF3F9)),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              isOpen ? 'ABIERTA' : 'CERRADA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isOpen
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF334155),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            sessionCode,
                            style: TextStyle(
                              fontSize: 30 / 2,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 37 / 2,
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isOpen ? Icons.sync_rounded : Icons.verified_user_rounded,
                  size: 24,
                  color: isOpen
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1152D4),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: borderColor.withValues(alpha: 0.8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _MetaBlock(
                        label: 'APERTURA',
                        value: openingText,
                        italic: false,
                      ),
                    ),
                    Expanded(
                      child: _MetaBlock(
                        label: 'CIERRE',
                        value: closingText,
                        italic: isOpen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MetaBlock(
                  label: 'RESPONSABLE',
                  value: responsible,
                  italic: false,
                ),
                const SizedBox(height: 14),
                if (!isOpen) ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'DESGLOSE POR DENOMINACION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF94A3B8),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const Text(
                        'CASH OUT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1152D4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: <Widget>[
                        if (breakdown.isNotEmpty)
                          for (final TpvSessionCashBreakdown row in breakdown)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      '${_denominationLabel(row.denominationCents)} x ${row.unitCount}',
                                      style: TextStyle(
                                        fontSize: 30 / 2,
                                        color: isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _money(row.subtotalCents),
                                    style: TextStyle(
                                      fontSize: 30 / 2,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        if (breakdown.isNotEmpty)
                          Divider(
                            height: 14,
                            color: borderColor.withValues(alpha: 0.7),
                          ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Efectivo cierre',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              _money(displayClosingCents),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1152D4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF1152D4).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Ventas actuales:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          _money(currentSalesCents),
                          style: const TextStyle(
                            fontSize: 32 / 2,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1152D4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onPrimaryAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: isOpen
                          ? (isDark
                              ? const Color(0xFF374151)
                              : const Color(0xFFE2E8F0))
                          : const Color(0xFF1152D4),
                      foregroundColor: isOpen
                          ? (isDark
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF334155))
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isOpen ? 0 : 3,
                    ),
                    child: Text(
                      isOpen ? 'Monitorear Turno' : 'Ver detalles completos',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({
    required this.label,
    required this.value,
    required this.italic,
  });

  final String label;
  final String value;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            fontSize: 23 / 2,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: italic
                ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8))
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
