import '../../../../core/db/app_database.dart';

class PosCartLine {
  const PosCartLine({
    required this.product,
    required this.qty,
  });

  final Product product;
  final double qty;

  PosCartLine copyWith({
    Product? product,
    double? qty,
  }) {
    return PosCartLine(
      product: product ?? this.product,
      qty: qty ?? this.qty,
    );
  }
}

class PosPaymentResult {
  const PosPaymentResult({
    required this.paymentByMethod,
    required this.cartLines,
  });

  final Map<String, int> paymentByMethod;
  final List<PosCartLine> cartLines;
}
