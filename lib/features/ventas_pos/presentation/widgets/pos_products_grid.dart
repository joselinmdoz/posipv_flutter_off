import 'package:flutter/material.dart';
import '../../../../core/db/app_database.dart';
import 'pos_product_card.dart';

class PosProductsGrid extends StatelessWidget {
  final List<Product> products;
  final Map<String, double> qtyByProductId;
  final Map<String, double> stockByProductId;
  final String currencySymbol;
  final bool isPosting;
  final void Function(String productId, double delta) onQtyChanged;

  const PosProductsGrid({
    super.key,
    required this.products,
    required this.qtyByProductId,
    required this.stockByProductId,
    required this.currencySymbol,
    required this.isPosting,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No hay productos que coincidan'),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: products.length,
      itemBuilder: (BuildContext context, int index) {
        final product = products[index];
        return PosProductCard(
          product: product,
          qty: qtyByProductId[product.id] ?? 0,
          stock: stockByProductId[product.id] ?? 0,
          currencySymbol: currencySymbol,
          isPosting: isPosting,
          onQtyChanged: (delta) => onQtyChanged(product.id, delta),
        );
      },
    );
  }
}
