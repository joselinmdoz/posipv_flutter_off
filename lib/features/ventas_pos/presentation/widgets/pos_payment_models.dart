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
    required this.isConsignmentSale,
    this.cancelOrderRequested = false,
    this.selectedCustomer,
    this.discountCents = 0,
    this.receivedCents = 0,
    this.changeCents = 0,
    this.changeReturned = true,
  });

  final Map<String, int> paymentByMethod;
  final List<PosPaymentLine> paymentLines;
  final List<PosCartLine> cartLines;
  final bool isConsignmentSale;
  final bool cancelOrderRequested;
  final PosSelectedCustomer? selectedCustomer;
  final int discountCents;
  final int receivedCents;
  final int changeCents;
  final bool changeReturned;
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
