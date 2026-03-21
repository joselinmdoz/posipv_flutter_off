import 'package:flutter/material.dart';

class PosBottomFooter extends StatelessWidget {
  final int itemCount;
  final double total;
  final String currencySymbol;
  final VoidCallback? onPayTap;

  const PosBottomFooter({
    super.key,
    required this.itemCount,
    required this.total,
    required this.currencySymbol,
    required this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF101622) : const Color(0xFFF6F6F8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    isDark ? const Color(0x50000000) : const Color(0x18000000),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'TOTAL ($itemCount PRODUCTOS)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$currencySymbol${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: onPayTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1152D4),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor:
                          const Color(0xFF1152D4).withValues(alpha: 0.35),
                    ),
                    icon: const Icon(Icons.shopping_cart_checkout_rounded),
                    label: const Text(
                      'PAGAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: -6,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white, width: 1.4),
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
