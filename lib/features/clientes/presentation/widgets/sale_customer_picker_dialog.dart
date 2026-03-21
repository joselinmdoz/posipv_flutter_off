import 'package:flutter/material.dart';

import '../../data/clientes_local_datasource.dart';
import 'client_avatar.dart';

class SaleCustomerPickerDialog extends StatefulWidget {
  const SaleCustomerPickerDialog({
    super.key,
    required this.customers,
    this.initialSelectedId,
  });

  final List<ClienteListItem> customers;
  final String? initialSelectedId;

  @override
  State<SaleCustomerPickerDialog> createState() =>
      _SaleCustomerPickerDialogState();
}

class _SaleCustomerPickerDialogState extends State<SaleCustomerPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClienteListItem> get _filteredCustomers {
    final String query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.customers;
    }
    return widget.customers.where((ClienteListItem customer) {
      return customer.fullName.toLowerCase().contains(query) ||
          (customer.phone ?? '').toLowerCase().contains(query) ||
          (customer.email ?? '').toLowerCase().contains(query) ||
          customer.code.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final List<ClienteListItem> filtered = _filteredCustomers;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 620),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Seleccionar cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: isDark ? const Color(0xFF111827) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron clientes.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final ClienteListItem customer = filtered[index];
                        final bool selected =
                            customer.id == widget.initialSelectedId;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.of(context).pop(customer),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF111827)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF1152D4)
                                      : (isDark
                                          ? const Color(0xFF1F2937)
                                          : const Color(0xFFE2E8F0)),
                                  width: selected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  ClientAvatar(
                                    name: customer.fullName,
                                    imagePath: customer.avatarPath,
                                    size: 48,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          customer.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          (customer.phone?.trim().isNotEmpty ??
                                                  false)
                                              ? customer.phone!
                                              : (customer.email
                                                          ?.trim()
                                                          .isNotEmpty ??
                                                      false)
                                                  ? customer.email!
                                                  : customer.code,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF1152D4),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
