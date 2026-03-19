import 'package:flutter/material.dart';

import '../../data/inventario_local_datasource.dart';

class InventoryStockByWarehouseSection extends StatelessWidget {
  const InventoryStockByWarehouseSection({
    super.key,
    required this.rows,
    required this.formatQty,
  });

  final List<InventoryWarehouseStockView> rows;
  final String Function(double qty) formatQty;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.warehouse_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Stock por almacenes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'No hay almacenes configurados.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...rows.map(
              (InventoryWarehouseStockView row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        row.warehouseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: row.qty > 0
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        formatQty(row.qty),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: row.qty > 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
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
}
