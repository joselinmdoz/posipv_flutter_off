import '../../../core/db/app_database.dart';
import '../data/productos_local_datasource.dart';
import 'product_qr_codec.dart';

class ProductScanResolver {
  const ProductScanResolver._();

  static Future<Product?> resolve({
    required ProductosLocalDataSource dataSource,
    required String scannedValue,
  }) async {
    final String raw = scannedValue.trim();
    if (raw.isEmpty) {
      return null;
    }

    final Set<String> tried = <String>{};

    Future<Product?> tryCandidate(String candidate) async {
      final String cleaned = candidate.trim();
      if (cleaned.isEmpty || !tried.add(cleaned)) {
        return null;
      }
      Product? product = await dataSource.findActiveProductByBarcode(cleaned);
      product ??= await dataSource.findActiveProductByCode(cleaned);
      product ??= await dataSource.findActiveProductById(cleaned);
      return product;
    }

    for (final String source in _payloadSources(raw)) {
      final ProductQrPayload? payload = ProductQrPayload.tryParse(source);
      if (payload == null) {
        continue;
      }
      Product? product = await tryCandidate(payload.id);
      product ??= await tryCandidate(payload.code);
      if (product != null) {
        return product;
      }
    }

    final List<String> candidates = _scanCandidates(raw);
    for (final String candidate in candidates) {
      final Product? product = await tryCandidate(candidate);
      if (product != null) {
        return product;
      }
    }
    return null;
  }

  static Iterable<String> _payloadSources(String raw) sync* {
    yield raw;
    final String decoded = _decodeUriComponentSafe(raw);
    if (decoded != raw) {
      yield decoded;
    }

    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || (!uri.hasQuery && uri.fragment.isEmpty)) {
      return;
    }
    final List<String> values = <String>[
      ...uri.queryParameters.values,
      if (uri.fragment.isNotEmpty) uri.fragment,
    ];
    for (final String value in values) {
      final String cleaned = value.trim();
      if (cleaned.isEmpty) {
        continue;
      }
      yield cleaned;
      final String decodedValue = _decodeUriComponentSafe(cleaned);
      if (decodedValue != cleaned) {
        yield decodedValue;
      }
    }
  }

  static List<String> _scanCandidates(String raw) {
    final Set<String> out = <String>{};

    void add(String value) {
      final String cleaned = value.trim();
      if (cleaned.isEmpty) {
        return;
      }
      out.add(cleaned);
    }

    add(raw);
    add(_decodeUriComponentSafe(raw));
    add(raw.replaceAll(RegExp(r'\s+'), ''));
    add(raw.replaceAll(RegExp(r'[-\s]'), ''));

    final String compact = raw.replaceAll(RegExp(r'[-\s]'), '');
    final String digitsOnly = compact.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isNotEmpty && digitsOnly.length == compact.length) {
      add(digitsOnly);
      if (digitsOnly.length == 12) {
        add('0$digitsOnly');
      }
      if (digitsOnly.length == 13 && digitsOnly.startsWith('0')) {
        add(digitsOnly.substring(1));
      }
    }

    return out.toList(growable: false);
  }

  static String _decodeUriComponentSafe(String raw) {
    try {
      return Uri.decodeComponent(raw.trim());
    } catch (_) {
      return raw.trim();
    }
  }
}
