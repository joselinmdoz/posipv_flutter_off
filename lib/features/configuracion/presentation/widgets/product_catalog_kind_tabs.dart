import 'package:flutter/material.dart';

import '../../../productos/data/productos_local_datasource.dart';

class ProductCatalogKindTabs extends StatelessWidget {
  const ProductCatalogKindTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ProductCatalogKind selected;
  final ValueChanged<ProductCatalogKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _chip(
            label: 'Tipo de producto',
            value: ProductCatalogKind.type,
          ),
          const SizedBox(width: 10),
          _chip(
            label: 'Categoría',
            value: ProductCatalogKind.category,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required ProductCatalogKind value,
  }) {
    final bool isSelected = selected == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1152D4) : const Color(0xFFE6E9EE),
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x331152D4),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}
