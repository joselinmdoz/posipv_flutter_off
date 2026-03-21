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
    this.transactionId,
    this.sourceCurrencyCode,
    this.sourceAmountCents,
  });

  final String method;
  final int amountCents;
  final String? transactionId;
  final String? sourceCurrencyCode;
  final int? sourceAmountCents;
}

class CreateSaleInput {
  const CreateSaleInput({
    required this.warehouseId,
    required this.cashierId,
    this.customerId,
    this.terminalId,
    this.terminalSessionId,
    required this.items,
    required this.payments,
    this.discountCents = 0,
    this.allowNegativeStock = false,
    this.saleOrigin = 'pos',
  });

  final String warehouseId;
  final String cashierId;
  final String? customerId;
  final String? terminalId;
  final String? terminalSessionId;
  final List<SaleItemInput> items;
  final List<PaymentInput> payments;
  final int discountCents;
  final bool allowNegativeStock;
  final String saleOrigin;
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
