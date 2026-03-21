import 'package:flutter/material.dart';

import '../../data/inventario_local_datasource.dart';

class InventoryMovementCard extends StatelessWidget {
  const InventoryMovementCard({
    super.key,
    required this.movement,
    required this.timeLabel,
  });

  final InventoryMovementView movement;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final _MovementVisual visual = _resolveVisual(movement);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: visual.accent,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: visual.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(visual.icon, color: visual.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              movement.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 38 / 2,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'SKU: ${movement.sku} • Almacén ${movement.warehouseName}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4B5563),
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
                            visual.amountLabel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: visual.accent,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _ReasonBadge(
                            text: movement.reasonLabel.toUpperCase(),
                            background: visual.badgeBg,
                            color: visual.badgeText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: Color(0xFF374151),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Operador: ${movement.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17 / 1.2,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.access_time_filled_rounded,
                        size: 17,
                        color: Color(0xFF374151),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _MovementVisual _resolveVisual(InventoryMovementView movement) {
    final bool isIn = movement.movementType == 'in';
    final String reason = movement.reasonCode.toLowerCase();
    final String reasonLabel = movement.reasonLabel.toLowerCase();
    final bool isLoss = reason == 'breakage' ||
        reason == 'shrinkage' ||
        reasonLabel.contains('rotura') ||
        reasonLabel.contains('merma');
    final bool isSale = reason == 'sale' ||
        movement.movementSource == 'pos' ||
        movement.movementSource == 'direct_sale';

    if (isIn) {
      return _MovementVisual(
        icon: isSale ? Icons.point_of_sale_rounded : Icons.inventory_2_rounded,
        accent: const Color(0xFF059669),
        soft: const Color(0xFFDFF6EC),
        badgeBg: const Color(0xFFCFF2DD),
        badgeText: const Color(0xFF047857),
        amountLabel: '+${_formatQty(movement.qty)}',
      );
    }

    if (isLoss) {
      return _MovementVisual(
        icon: Icons.bolt_rounded,
        accent: const Color(0xFFD97706),
        soft: const Color(0xFFFFF4D8),
        badgeBg: const Color(0xFFFDE7B0),
        badgeText: const Color(0xFFB45309),
        amountLabel: '-${_formatQty(movement.qty)}',
      );
    }

    return _MovementVisual(
      icon: isSale ? Icons.shopping_cart_rounded : Icons.swap_vert_rounded,
      accent: const Color(0xFFB91C1C),
      soft: const Color(0xFFFDE7E7),
      badgeBg: const Color(0xFFFCD9D9),
      badgeText: const Color(0xFFB91C1C),
      amountLabel: '-${_formatQty(movement.qty)}',
    );
  }

  String _formatQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(2);
    }
    return qty.toStringAsFixed(2);
  }
}

class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({
    required this.text,
    required this.background,
    required this.color,
  });

  final String text;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: color,
        ),
      ),
    );
  }
}

class _MovementVisual {
  const _MovementVisual({
    required this.icon,
    required this.accent,
    required this.soft,
    required this.badgeBg,
    required this.badgeText,
    required this.amountLabel,
  });

  final IconData icon;
  final Color accent;
  final Color soft;
  final Color badgeBg;
  final Color badgeText;
  final String amountLabel;
}
