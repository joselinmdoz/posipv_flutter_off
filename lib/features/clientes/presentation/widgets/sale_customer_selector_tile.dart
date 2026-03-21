import 'package:flutter/material.dart';

import '../../data/clientes_local_datasource.dart';
import 'client_avatar.dart';

class SaleCustomerSelectorTile extends StatelessWidget {
  const SaleCustomerSelectorTile({
    super.key,
    required this.selectedCustomer,
    required this.onSelect,
    required this.onClear,
    this.enabled = true,
  });

  final ClienteListItem? selectedCustomer;
  final VoidCallback onSelect;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final ClienteListItem? customer = selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101826) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF243246) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: <Widget>[
          if (customer != null)
            ClientAvatar(
              name: customer.fullName,
              imagePath: customer.avatarPath,
              size: 44,
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.groups_rounded, color: Color(0xFF1152D4)),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  customer?.fullName ?? 'Venta sin cliente',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer == null
                      ? 'Seleccion opcional para asociar la venta.'
                      : customer.phone?.trim().isNotEmpty == true
                          ? customer.phone!
                          : customer.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (customer != null)
            IconButton(
              tooltip: 'Quitar cliente',
              onPressed: enabled ? onClear : null,
              icon: const Icon(
                Icons.close_rounded,
                color: Color(0xFFDC2626),
              ),
            ),
          FilledButton.tonalIcon(
            onPressed: enabled ? onSelect : null,
            icon: const Icon(Icons.person_search_rounded),
            label: Text(customer == null ? 'Elegir' : 'Cambiar'),
          ),
        ],
      ),
    );
  }
}
