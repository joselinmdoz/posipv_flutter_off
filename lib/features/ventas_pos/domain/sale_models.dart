class SaleItemInput {
  const SaleItemInput({
    required this.productId,
    required this.qty,
    required this.unitPriceCents,
    required this.taxRateBps,
  });

  final String productId;
  final double qty;
  final int unitPriceCents;
  final int taxRateBps;
}

class PaymentInput {
  const PaymentInput({
    required this.method,
    required this.amountCents,
  });

  final String method;
  final int amountCents;
}

class CreateSaleInput {
  const CreateSaleInput({
    required this.warehouseId,
    required this.cashierId,
    required this.items,
    required this.payments,
    this.allowNegativeStock = false,
  });

  final String warehouseId;
  final String cashierId;
  final List<SaleItemInput> items;
  final List<PaymentInput> payments;
  final bool allowNegativeStock;
}

class CreateSaleResult {
  const CreateSaleResult({
    required this.saleId,
    required this.folio,
    required this.totalCents,
  });

  final String saleId;
  final String folio;
  final int totalCents;
}
