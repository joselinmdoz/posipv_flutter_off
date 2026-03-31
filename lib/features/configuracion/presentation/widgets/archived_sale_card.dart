import 'package:flutter/material.dart';

import '../../../ventas_pos/data/sale_service.dart';

class ArchivedSaleCard extends StatelessWidget {
  const ArchivedSaleCard({
    super.key,
    required this.sale,
    required this.createdAtLabel,
    required this.archivedAtLabel,
    required this.totalLabel,
    this.onRestore,
    this.onDeletePermanently,
  });

  final ArchivedSaleView sale;
  final String createdAtLabel;
  final String archivedAtLabel;
  final String totalLabel;
  final VoidCallback? onRestore;
  final VoidCallback? onDeletePermanently;

  @override
  Widget build(BuildContext context) {
    final bool isPos = sale.channel.trim().toLowerCase() == 'pos';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        sale.folio,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sale.customerName == null
                            ? 'Cliente: Sin cliente'
                            : 'Cliente: ${sale.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPos
                        ? const Color(0xFFE0EBFF)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isPos ? 'POS' : 'DIRECTA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isPos
                          ? const Color(0xFF1152D4)
                          : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: <Widget>[
                _chip('Dependiente: ${sale.cashierName}'),
                _chip('Almacén: ${sale.warehouseName}'),
                _chip('Total: $totalLabel'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Venta: $createdAtLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Archivada: $archivedAtLabel',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            if (onRestore != null) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Restaurar venta'),
                ),
              ),
            ],
            if (onDeletePermanently != null) ...<Widget>[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDeletePermanently,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB91C1C),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Eliminar definitivo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}
