class ProductOrderCostingModeCatalog {
  const ProductOrderCostingModeCatalog._();

  static const String orderedQty = 'ordered_qty';
  static const String consumedArea = 'consumed_area';

  static const List<String> all = <String>[
    orderedQty,
    consumedArea,
  ];

  static String normalize(String? value) {
    final String clean = (value ?? '').trim();
    if (all.contains(clean)) {
      return clean;
    }
    return orderedQty;
  }

  static String label(String value) {
    switch (normalize(value)) {
      case consumedArea:
        return 'Por consumo util';
      case orderedQty:
      default:
        return 'Por cantidad solicitada';
    }
  }

  static String description(String value) {
    switch (normalize(value)) {
      case consumedArea:
        return 'El costo del pedido se calcula segun el consumo util registrado en produccion.';
      case orderedQty:
      default:
        return 'El costo del pedido se calcula por la cantidad solicitada por el cliente.';
    }
  }
}
