import '../../../../core/db/app_database.dart';

class PosSelectedCustomer {
  const PosSelectedCustomer({
    required this.id,
    required this.fullName,
    this.code,
    this.phone,
    this.email,
    this.avatarPath,
  });

  final String id;
  final String fullName;
  final String? code;
  final String? phone;
  final String? email;
  final String? avatarPath;
}

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
    required this.paymentLines,
    required this.cartLines,
    this.selectedCustomer,
  });

  final Map<String, int> paymentByMethod;
  final List<PosPaymentLine> paymentLines;
  final List<PosCartLine> cartLines;
  final PosSelectedCustomer? selectedCustomer;
}

class PosPaymentLine {
  const PosPaymentLine({
    required this.method,
    required this.amountCents,
    this.transactionId,
  });

  final String method;
  final int amountCents;
  final String? transactionId;
}
