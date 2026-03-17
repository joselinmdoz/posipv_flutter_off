import 'dart:convert';

import '../../../core/db/app_database.dart';

class ProductQrPayload {
  const ProductQrPayload({
    required this.id,
    required this.code,
    required this.name,
    required this.priceCents,
    required this.currencyCode,
  });

  final String id;
  final String code;
  final String name;
  final int priceCents;
  final String currencyCode;

  Map<String, Object> toJson() => <String, Object>{
        'kind': 'pos_product',
        'v': 1,
        'id': id,
        'code': code,
        'name': name,
        'priceCents': priceCents,
        'currencyCode': currencyCode,
      };

  static ProductQrPayload? tryParse(String raw) {
    final String cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return null;
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      return null;
    }

    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    if (decoded['kind'] != 'pos_product') {
      return null;
    }

    final String? id = decoded['id'] as String?;
    final String? code = decoded['code'] as String?;
    final String? name = decoded['name'] as String?;
    final int? priceCents = decoded['priceCents'] as int?;
    final String? currencyCode = decoded['currencyCode'] as String?;

    if (id == null ||
        code == null ||
        name == null ||
        priceCents == null ||
        currencyCode == null) {
      return null;
    }

    return ProductQrPayload(
      id: id,
      code: code,
      name: name,
      priceCents: priceCents,
      currencyCode: currencyCode,
    );
  }
}

String buildProductQrData(Product product) {
  final ProductQrPayload payload = ProductQrPayload(
    id: product.id,
    code: product.sku,
    name: product.name,
    priceCents: product.priceCents,
    currencyCode: product.currencyCode,
  );
  return jsonEncode(payload.toJson());
}
