// Data models for the sale receipt / ticket de venta.

class SaleReceipt {
  const SaleReceipt({
    required this.folio,
    required this.createdAt,
    required this.cashierUsername,
    required this.terminalName,
    required this.warehouseName,
    required this.lines,
    required this.subtotalCents,
    required this.taxCents,
    required this.discountCents,
    required this.totalCents,
    required this.payments,
    required this.paidCents,
    this.currencySymbol = r'$',
    this.isDemoMode = false,
  });

  final String folio;
  final DateTime createdAt;
  final String cashierUsername;
  final String terminalName;
  final String warehouseName;
  final List<SaleReceiptLine> lines;
  final int subtotalCents;
  final int taxCents;
  final int discountCents;
  final int totalCents;
  final List<ReceiptPayment> payments;
  final int paidCents;
  final String currencySymbol;
  final bool isDemoMode;
}

class ReceiptPayment {
  const ReceiptPayment({
    required this.method,
    required this.amountCents,
  });

  final String method;
  final int amountCents;
}

class SaleReceiptLine {
  const SaleReceiptLine({
    required this.name,
    required this.sku,
    required this.qty,
    required this.unitPriceCents,
    required this.taxRateBps,
    this.unitPriceDisplay,
    this.lineTotalDisplay,
  });

  final String name;
  final String sku;
  final double qty;
  final int unitPriceCents;
  final int taxRateBps;
  final String? unitPriceDisplay;
  final String? lineTotalDisplay;

  int get lineSubtotalCents => (qty * unitPriceCents).round();

  int get lineTaxCents => (lineSubtotalCents * taxRateBps / 10000).round();

  int get lineTotalCents => lineSubtotalCents + lineTaxCents;
}
