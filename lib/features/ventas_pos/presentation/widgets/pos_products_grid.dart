import 'package:flutter/material.dart';
import '../../../../core/db/app_database.dart';
import 'pos_product_card.dart';

class PosProductsGrid extends StatelessWidget {
  final List<Product> products;
  final Map<String, double> qtyByProductId;
  final Map<String, double> stockByProductId;
  final String currencySymbol;
  final String emptyMessage;
  final bool isPosting;
  final void Function(String productId, double delta) onQtyChanged;
  final void Function(String productId, double qty) onQtySet;

  const PosProductsGrid({
    super.key,
    required this.products,
    required this.qtyByProductId,
    required this.stockByProductId,
    required this.currencySymbol,
    required this.emptyMessage,
    required this.isPosting,
    required this.onQtyChanged,
    required this.onQtySet,
  });

  static const double _kGridSpacing = 12;

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
            Text(emptyMessage),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final int preferredColumns = _gridColumnsForWidth(width);
        final int columns = preferredColumns > products.length
            ? products.length
            : preferredColumns;
        final double tileWidth =
            (width - (_kGridSpacing * (columns - 1)) - 32) / columns;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns < 1 ? 1 : columns,
            crossAxisSpacing: _kGridSpacing,
            mainAxisSpacing: _kGridSpacing,
            mainAxisExtent: _gridMainAxisExtent(tileWidth),
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
              onQtySet: (double qty) => onQtySet(product.id, qty),
            );
          },
        );
      },
    );
  }

  int _gridColumnsForWidth(double width) {
    if (width >= 1400) {
      return 6;
    }
    if (width >= 1100) {
      return 5;
    }
    if (width >= 860) {
      return 4;
    }
    if (width >= 640) {
      return 3;
    }
    return 2;
  }

  double _gridMainAxisExtent(double tileWidth) {
    if (tileWidth >= 280) {
      return 232;
    }
    if (tileWidth >= 220) {
      return 214;
    }
    return 198;
  }
}
