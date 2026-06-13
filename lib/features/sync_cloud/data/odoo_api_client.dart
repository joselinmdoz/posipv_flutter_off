import 'dart:convert';
import 'dart:io';

import 'cloud_sync_models.dart';

class OdooApiClient {
  OdooApiClient();

  final Map<String, List<Cookie>> _cookieJar = <String, List<Cookie>>{};

  Future<OdooPingResult> ping({
    required String serverUrl,
    required String databaseName,
  }) async {
    final Map<String, Object?> data = await _post(
      serverUrl: serverUrl,
      databaseName: databaseName,
      path: '/posipv/api/v1/ping',
      payload: <String, Object?>{
        'db': databaseName,
      },
    );
    return OdooPingResult(
      ok: data['ok'] == true,
      message: (data['message'] as String? ?? 'Sin respuesta').trim(),
      serverVersion: (data['server_version'] as String?)?.trim(),
      serverTime: _parseDate(data['server_time']),
      databaseName: (data['database'] as String?)?.trim(),
    );
  }

  Future<OdooDeviceRegistrationResult> registerDevice({
    required String serverUrl,
    required String databaseName,
    required String bootstrapToken,
    required String deviceUuid,
    required String deviceLabel,
    required String appVersion,
  }) async {
    final Map<String, Object?> data = await _post(
      serverUrl: serverUrl,
      databaseName: databaseName,
      path: '/posipv/api/v1/device/register',
      payload: <String, Object?>{
        'db': databaseName,
        'bootstrap_token': bootstrapToken,
        'device_uuid': deviceUuid,
        'device_label': deviceLabel,
        'app_version': appVersion,
      },
    );
    return OdooDeviceRegistrationResult(
      deviceUuid: (data['device_uuid'] as String? ?? '').trim(),
      apiKey: (data['api_key'] as String? ?? '').trim(),
      message: (data['message'] as String? ?? 'Registro completado').trim(),
    );
  }

  Future<OdooPushBatchResult> pushBatch({
    required String serverUrl,
    required String databaseName,
    required String deviceUuid,
    required String apiKey,
    required Map<String, Object?> payload,
  }) async {
    final Map<String, Object?> data = await _post(
      serverUrl: serverUrl,
      databaseName: databaseName,
      path: '/posipv/api/v1/push/batch',
      payload: <String, Object?>{
        'db': databaseName,
        ...payload,
      },
      deviceUuid: deviceUuid,
      apiKey: apiKey,
    );
    return OdooPushBatchResult(
      ok: data['ok'] == true,
      message: (data['message'] as String? ?? 'Sin respuesta').trim(),
      acceptedRecords: (data['accepted_records'] as num?)?.toInt() ?? 0,
      failedRecords: (data['failed_records'] as num?)?.toInt() ?? 0,
    );
  }

  Future<OdooMasterDataSnapshot> pullMasterData({
    required String serverUrl,
    required String databaseName,
    required String deviceUuid,
    required String apiKey,
  }) async {
    final Map<String, Object?> data = await _post(
      serverUrl: serverUrl,
      databaseName: databaseName,
      path: '/posipv/api/v1/pull/master-data',
      payload: <String, Object?>{
        'db': databaseName,
      },
      deviceUuid: deviceUuid,
      apiKey: apiKey,
    );
    List<Map<String, Object?>> listOf(String key) {
      final Object? raw = data[key];
      if (raw is! List) {
        return const <Map<String, Object?>>[];
      }
      return raw
          .whereType<Map>()
          .map(
            (Map value) => <String, Object?>{
              for (final MapEntry entry in value.entries)
                entry.key.toString(): entry.value,
            },
          )
          .toList(growable: false);
    }

    return OdooMasterDataSnapshot(
      products: listOf('products'),
      customers: listOf('customers'),
      employees: listOf('employees'),
      warehouses: listOf('warehouses'),
      terminals: listOf('terminals'),
      message: (data['message'] as String?)?.trim(),
    );
  }

  Future<OdooWorkOrdersSnapshot> pullWorkOrders({
    required String serverUrl,
    required String databaseName,
    required String deviceUuid,
    required String apiKey,
  }) async {
    final Map<String, Object?> data = await _post(
      serverUrl: serverUrl,
      databaseName: databaseName,
      path: '/posipv/api/v1/pull/work-orders',
      payload: <String, Object?>{
        'db': databaseName,
      },
      deviceUuid: deviceUuid,
      apiKey: apiKey,
    );

    final Object? raw = data['work_orders'];
    final List<Map<String, Object?>> workOrders = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (Map value) => <String, Object?>{
                for (final MapEntry entry in value.entries)
                  entry.key.toString(): entry.value,
              },
            )
            .toList(growable: false)
        : const <Map<String, Object?>>[];

    return OdooWorkOrdersSnapshot(
      workOrders: workOrders,
      message: (data['message'] as String?)?.trim(),
    );
  }

  Future<Map<String, Object?>> _post({
    required String serverUrl,
    required String databaseName,
    required String path,
    required Map<String, Object?> payload,
    String? deviceUuid,
    String? apiKey,
  }) async {
    final Uri uri = _buildUri(serverUrl, databaseName, path);
    final String sessionKey = _sessionKey(serverUrl, databaseName);
    final HttpClient client = HttpClient();
    try {
      await _ensureDatabaseContext(
        client: client,
        serverUrl: serverUrl,
        databaseName: databaseName,
      );
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      _applyCookies(request, sessionKey);
      if ((deviceUuid ?? '').trim().isNotEmpty) {
        request.headers.set('X-POSIPV-Device', deviceUuid!.trim());
      }
      if ((apiKey ?? '').trim().isNotEmpty) {
        request.headers.set('X-POSIPV-Key', apiKey!.trim());
      }
      request.write(jsonEncode(payload));
      final HttpClientResponse response = await request.close();
      _storeCookies(sessionKey, response.cookies);
      final String body = await utf8.decodeStream(response);
      dynamic decoded;
      try {
        decoded = body.trim().isEmpty ? <String, Object?>{} : jsonDecode(body);
      } on FormatException {
        decoded = <String, Object?>{
          'message': body.trim().isEmpty
              ? 'Respuesta vacía del servidor Odoo.'
              : body.trim(),
        };
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Servidor Odoo respondió ${response.statusCode}: ${_extractMessage(decoded)}',
        );
      }
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return <String, Object?>{
          for (final MapEntry entry in decoded.entries)
            entry.key.toString(): entry.value,
        };
      }
      throw Exception('Respuesta inválida del servidor Odoo.');
    } on SocketException catch (e) {
      throw Exception('No se pudo conectar con Odoo: $e');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _ensureDatabaseContext({
    required HttpClient client,
    required String serverUrl,
    required String databaseName,
  }) async {
    final Uri uri = Uri.parse(
      serverUrl.trim().endsWith('/')
          ? serverUrl.trim()
          : '${serverUrl.trim()}/',
    ).resolve('/web').replace(
      queryParameters: <String, String>{
        'db': databaseName.trim(),
      },
    );
    final String sessionKey = _sessionKey(serverUrl, databaseName);
    final HttpClientRequest request = await client.getUrl(uri);
    request.followRedirects = false;
    request.maxRedirects = 0;
    _applyCookies(request, sessionKey);
    final HttpClientResponse response = await request.close();
    _storeCookies(sessionKey, response.cookies);
    await response.drain<void>();
  }

  void _applyCookies(HttpClientRequest request, String sessionKey) {
    final List<Cookie>? cookies = _cookieJar[sessionKey];
    if (cookies == null || cookies.isEmpty) {
      return;
    }
    request.cookies.addAll(cookies);
  }

  void _storeCookies(String sessionKey, List<Cookie> cookies) {
    if (cookies.isEmpty) {
      return;
    }
    _cookieJar[sessionKey] = cookies
        .map(
          (Cookie cookie) => Cookie(cookie.name, cookie.value)
            ..domain = cookie.domain
            ..path = cookie.path
            ..expires = cookie.expires
            ..httpOnly = cookie.httpOnly
            ..secure = cookie.secure,
        )
        .toList(growable: false);
  }

  String _sessionKey(String serverUrl, String databaseName) =>
      '${serverUrl.trim()}|${databaseName.trim()}';

  Uri _buildUri(String serverUrl, String databaseName, String path) {
    final String normalizedServer = serverUrl.trim().endsWith('/')
        ? serverUrl.trim()
        : '${serverUrl.trim()}/';
    final Uri base = Uri.parse(normalizedServer);
    return base.resolve(path).replace(
      queryParameters: <String, String>{
        'db': databaseName.trim(),
      },
    );
  }

  DateTime? _parseDate(Object? raw) {
    final String clean = (raw ?? '').toString().trim();
    if (clean.isEmpty) {
      return null;
    }
    return DateTime.tryParse(clean);
  }

  String _extractMessage(Object? decoded) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return 'Error desconocido.';
  }
}
