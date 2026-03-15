import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import 'license_models.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    FlutterSecureStorage? secureStorage,
    Uuid? uuid,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _uuid = uuid ?? const Uuid();

  static const MethodChannel _channel =
      MethodChannel('com.example.posipv/device_identity');
  static const String _fallbackInstallIdKey = 'license_installation_id_v1';

  final FlutterSecureStorage _secureStorage;
  final Uuid _uuid;
  DeviceIdentity? _cachedIdentity;
  Future<DeviceIdentity>? _identityInFlight;

  Future<DeviceIdentity> getIdentity() {
    final DeviceIdentity? cached = _cachedIdentity;
    if (cached != null) {
      return Future<DeviceIdentity>.value(cached);
    }

    final Future<DeviceIdentity>? inFlight = _identityInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<DeviceIdentity> future = _loadIdentity();
    _identityInFlight = future;
    return future;
  }

  Future<DeviceIdentity> _loadIdentity() async {
    Map<Object?, Object?>? response;
    try {
      try {
        response = await _channel
            .invokeMethod<Map<Object?, Object?>>('getDeviceIdentity');
      } on MissingPluginException {
        response = null;
      }
      final Map<String, Object?> nativeData = <String, Object?>{
        for (final MapEntry<Object?, Object?> entry
            in (response ?? <Object?, Object?>{}).entries)
          entry.key.toString(): entry.value,
      };

      final String nativeHardwareId =
          (nativeData['hardwareId'] ?? '').toString().trim();
      final String displayName = _resolveDisplayName(nativeData);
      final String fallbackInstallId = await _loadOrCreateInstallId();
      final String rawId = nativeHardwareId.isNotEmpty
          ? 'android:$nativeHardwareId'
          : 'install:$fallbackInstallId';

      final String fingerprintHash = _sha256Hex('posipv|license|$rawId');
      final DeviceIdentity identity = DeviceIdentity(
        rawId: rawId,
        displayName: displayName,
        fingerprintHash: fingerprintHash,
      );
      _cachedIdentity = identity;
      return identity;
    } finally {
      _identityInFlight = null;
    }
  }

  String buildRequestCode(
    DeviceIdentity identity, {
    DateTime? requestedExpiry,
  }) {
    final Map<String, Object?> requestPayload = <String, Object?>{
      'ver': 1,
      'device': identity.fingerprintHash,
      'platform': Platform.operatingSystem,
      'label': identity.displayName,
      'generatedAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (requestedExpiry != null)
        'requestedExpiry': requestedExpiry.millisecondsSinceEpoch ~/ 1000,
    };
    return 'POSREQ1.${base64Url.encode(utf8.encode(jsonEncode(requestPayload))).replaceAll('=', '')}';
  }

  Future<bool> verifySignature({
    required String payloadSegment,
    required String signatureSegment,
  }) async {
    try {
      final bool? verified = await _channel.invokeMethod<bool>(
        'verifyLicenseSignature',
        <String, Object?>{
          'payload': payloadSegment,
          'signature': signatureSegment,
        },
      );
      return verified ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      final bool? shared = await _channel.invokeMethod<bool>(
        'shareText',
        <String, Object?>{
          'text': text,
          'subject': subject?.trim(),
        },
      );
      return shared ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<String> _loadOrCreateInstallId() async {
    final String? stored =
        await _secureStorage.read(key: _fallbackInstallIdKey);
    if (stored != null && stored.trim().isNotEmpty) {
      return stored.trim();
    }

    final String created = _uuid.v4();
    await _secureStorage.write(key: _fallbackInstallIdKey, value: created);
    return created;
  }

  String _resolveDisplayName(Map<String, Object?> nativeData) {
    final String manufacturer =
        (nativeData['manufacturer'] ?? '').toString().trim();
    final String model = (nativeData['model'] ?? '').toString().trim();
    final String joined = <String>[manufacturer, model]
        .where((String item) => item.isNotEmpty)
        .join(' ');
    if (joined.isNotEmpty) {
      return joined;
    }
    return Platform.operatingSystem;
  }

  String _sha256Hex(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
