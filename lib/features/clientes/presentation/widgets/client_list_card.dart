import 'package:flutter/material.dart';

import '../../data/clientes_local_datasource.dart';
import 'client_avatar.dart';

class ClientListCard extends StatelessWidget {
  const ClientListCard({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onTap,
  });

  final ClienteListItem item;
  final String currencySymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _CardVisual visual = _CardVisual.from(item);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE3E8EF)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClientAvatar(
                  name: item.fullName,
                  imagePath: item.avatarPath,
                  size: 48,
                  showOnlineDot: item.isFrequent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: visual.badgeBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        visual.badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: visual.badgeForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.fullName,
              style: const TextStyle(
                fontSize: 28 / 2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF11141A),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                const Icon(Icons.call_rounded,
                    size: 15, color: Color(0xFF374151)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    (item.phone ?? '').trim().isEmpty
                        ? 'Sin telefono'
                        : item.phone!,
                    style: const TextStyle(
                      color: Color(0xFF48546A),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE6EAF0)),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _footerText(visual),
                    style: const TextStyle(
                      color: Color(0xFF6B7486),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF3FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    visual.actionIcon,
                    size: 18,
                    color: const Color(0xFF1152D4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _footerText(_CardVisual visual) {
    if (item.isFrequent) {
      if (item.lastPurchaseAt == null) {
        return 'Ultima compra: sin registro';
      }
      return 'Ultima compra: ${_dateShort(item.lastPurchaseAt!)}';
    }
    if (item.isWholesale) {
      return 'Credito disponible: ${_money(item.creditAvailableCents)}';
    }
    if (item.isNew) {
      return 'Registrado: ${_relativeSince(item.createdAt)}';
    }
    if (item.discountBps > 0) {
      return 'Descuento global: ${(item.discountBps / 100).toStringAsFixed(0)}%';
    }
    return 'Cliente registrado';
  }

  String _money(int cents) {
    return '$currencySymbol${(cents / 100).toStringAsFixed(2)}';
  }

  String _dateShort(DateTime date) {
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
    final DateTime d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }

  String _relativeSince(DateTime date) {
    final DateTime now = DateTime.now();
    final int days = now.difference(date.toLocal()).inDays;
    if (days <= 0) {
      return 'hoy';
    }
    if (days == 1) {
      return 'hace 1 dia';
    }
    return 'hace $days dias';
  }
}

class _CardVisual {
  const _CardVisual({
    required this.badgeText,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.actionIcon,
  });

  final String badgeText;
  final Color badgeBackground;
  final Color badgeForeground;
  final IconData actionIcon;

  factory _CardVisual.from(ClienteListItem item) {
    if (item.isVip) {
      return const _CardVisual(
        badgeText: 'VIP',
        badgeBackground: Color(0xFFDDE6FF),
        badgeForeground: Color(0xFF2047A5),
        actionIcon: Icons.arrow_forward_rounded,
      );
    }
    if (item.isFrequent) {
      return const _CardVisual(
        badgeText: 'FRECUENTE',
        badgeBackground: Color(0xFFDDE6FF),
        badgeForeground: Color(0xFF2047A5),
        actionIcon: Icons.arrow_forward_rounded,
      );
    }
    if (item.isWholesale) {
      return const _CardVisual(
        badgeText: 'MAYORISTA',
        badgeBackground: Color(0xFFFFDDCF),
        badgeForeground: Color(0xFF93370E),
        actionIcon: Icons.more_vert_rounded,
      );
    }
    if (item.isNew) {
      return const _CardVisual(
        badgeText: 'NUEVO',
        badgeBackground: Color(0xFFDDE6FF),
        badgeForeground: Color(0xFF3A56B3),
        actionIcon: Icons.add_shopping_cart_rounded,
      );
    }
    return const _CardVisual(
      badgeText: 'GENERAL',
      badgeBackground: Color(0xFFE9EDF3),
      badgeForeground: Color(0xFF475569),
      actionIcon: Icons.analytics_outlined,
    );
  }
}
