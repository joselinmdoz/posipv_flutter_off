import 'dart:convert';

enum LicenseMode { trial, full, blocked }

enum LicenseBlockReason {
  trialExpired,
  licenseExpired,
  invalidCode,
  deviceMismatch,
  clockRollback,
  corruptedState,
  unsafeRuntime,
}

class LicenseException implements Exception {
  const LicenseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DeviceIdentity {
  const DeviceIdentity({
    required this.rawId,
    required this.displayName,
    required this.fingerprintHash,
  });

  final String rawId;
  final String displayName;
  final String fingerprintHash;
}

class StoredTrialState {
  const StoredTrialState({
    required this.startedAt,
    required this.expiresAt,
  });

  final DateTime startedAt;
  final DateTime expiresAt;
}

class ParsedLicenseToken {
  const ParsedLicenseToken({
    required this.raw,
    required this.payloadSegment,
    required this.signatureSegment,
    required this.payloadJson,
    required this.version,
    required this.licenseId,
    required this.customerName,
    required this.deviceFingerprint,
    required this.issuedAt,
    required this.expiresAt,
  });

  final String raw;
  final String payloadSegment;
  final String signatureSegment;
  final Map<String, Object?> payloadJson;
  final int version;
  final String licenseId;
  final String? customerName;
  final String deviceFingerprint;
  final DateTime issuedAt;
  final DateTime expiresAt;

  factory ParsedLicenseToken.parse(String raw) {
    final String normalized = raw.replaceAll(RegExp(r'\s+'), '');
    final List<String> parts = normalized.split('.');
    if (parts.length != 3 || parts.first != 'POSIPV1') {
      throw const LicenseException(
          'El codigo de licencia no tiene un formato valido.');
    }

    final Map<String, Object?> payloadJson =
        _decodeJsonSegment(parts[1]).cast<String, Object?>();
    final int version = _readInt(payloadJson['ver']) ?? 0;
    if (version != 1) {
      throw const LicenseException(
          'La version de la licencia no es compatible.');
    }

    final String licenseId = _readString(payloadJson['licenseId']);
    final String deviceFingerprint = _readString(payloadJson['device']);
    final DateTime issuedAt = _readDate(payloadJson['iat']);
    final DateTime expiresAt = _readDate(payloadJson['exp']);
    if (licenseId.isEmpty || deviceFingerprint.isEmpty) {
      throw const LicenseException(
          'La licencia no contiene todos los datos requeridos.');
    }

    return ParsedLicenseToken(
      raw: normalized,
      payloadSegment: parts[1],
      signatureSegment: parts[2],
      payloadJson: payloadJson,
      version: version,
      licenseId: licenseId,
      customerName: _readNullableString(payloadJson['customer']),
      deviceFingerprint: deviceFingerprint,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }
}

class LicenseStatus {
  const LicenseStatus({
    required this.mode,
    required this.isLoading,
    required this.deviceIdentity,
    required this.message,
    required this.checkedAt,
    this.blockReason,
    this.startedAt,
    this.expiresAt,
    this.licenseId,
    this.customerName,
  });

  const LicenseStatus.loading()
      : mode = LicenseMode.blocked,
        isLoading = true,
        deviceIdentity = null,
        message = 'Validando licencia...',
        checkedAt = null,
        blockReason = null,
        startedAt = null,
        expiresAt = null,
        licenseId = null,
        customerName = null;

  final LicenseMode mode;
  final bool isLoading;
  final DeviceIdentity? deviceIdentity;
  final String message;
  final DateTime? checkedAt;
  final LicenseBlockReason? blockReason;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final String? licenseId;
  final String? customerName;

  bool get isActive => !isLoading && mode != LicenseMode.blocked;
  bool get canWrite => isActive;
  bool get canSell => isActive;
  bool get isTrial => mode == LicenseMode.trial;
  bool get isFull => mode == LicenseMode.full;
  bool get isBlocked => !isLoading && mode == LicenseMode.blocked;

  int? get daysRemaining {
    if (expiresAt == null || checkedAt == null) {
      return null;
    }
    final Duration delta = expiresAt!.difference(checkedAt!);
    if (delta.isNegative) {
      return 0;
    }
    return delta.inDays +
        (delta.inHours % 24 == 0 && delta.inMinutes % 60 == 0 ? 0 : 1);
  }

  String get statusLabel {
    if (isLoading) {
      return 'Validando';
    }
    switch (mode) {
      case LicenseMode.trial:
        return 'Prueba activa';
      case LicenseMode.full:
        return 'Licencia activa';
      case LicenseMode.blocked:
        return 'Bloqueada';
    }
  }

  factory LicenseStatus.trial({
    required DeviceIdentity deviceIdentity,
    required DateTime checkedAt,
    required DateTime startedAt,
    required DateTime expiresAt,
  }) {
    final int remainingDays = expiresAt.isBefore(checkedAt)
        ? 0
        : expiresAt.difference(checkedAt).inDays + 1;
    return LicenseStatus(
      mode: LicenseMode.trial,
      isLoading: false,
      deviceIdentity: deviceIdentity,
      message: 'Licencia de prueba activa. Restan $remainingDays dia(s).',
      checkedAt: checkedAt,
      startedAt: startedAt,
      expiresAt: expiresAt,
    );
  }

  factory LicenseStatus.full({
    required DeviceIdentity deviceIdentity,
    required DateTime checkedAt,
    required DateTime expiresAt,
    required String licenseId,
    String? customerName,
  }) {
    return LicenseStatus(
      mode: LicenseMode.full,
      isLoading: false,
      deviceIdentity: deviceIdentity,
      message: 'Licencia activa para este dispositivo.',
      checkedAt: checkedAt,
      expiresAt: expiresAt,
      licenseId: licenseId,
      customerName: customerName,
    );
  }

  factory LicenseStatus.blocked({
    required DeviceIdentity deviceIdentity,
    required DateTime checkedAt,
    required LicenseBlockReason reason,
    String? messageOverride,
    DateTime? startedAt,
    DateTime? expiresAt,
  }) {
    return LicenseStatus(
      mode: LicenseMode.blocked,
      isLoading: false,
      deviceIdentity: deviceIdentity,
      message: messageOverride ?? _blockedMessage(reason),
      checkedAt: checkedAt,
      blockReason: reason,
      startedAt: startedAt,
      expiresAt: expiresAt,
    );
  }

  static String _blockedMessage(LicenseBlockReason reason) {
    switch (reason) {
      case LicenseBlockReason.trialExpired:
        return 'La prueba gratis de 10 dias ya expiro. Activa una licencia valida para continuar.';
      case LicenseBlockReason.licenseExpired:
        return 'La licencia cargada ya expiro.';
      case LicenseBlockReason.invalidCode:
        return 'La licencia no es valida para esta app.';
      case LicenseBlockReason.deviceMismatch:
        return 'La licencia pertenece a otro dispositivo.';
      case LicenseBlockReason.clockRollback:
        return 'Se detecto un cambio sospechoso en la fecha del dispositivo.';
      case LicenseBlockReason.corruptedState:
        return 'El estado local de la licencia esta corrupto o incompleto.';
      case LicenseBlockReason.unsafeRuntime:
        return 'Se detecto un entorno inseguro en el dispositivo. La aplicacion se bloqueo para proteger la licencia.';
    }
  }
}

Map<String, Object?> decodeRequestCode(String raw) {
  final String normalized = raw.replaceAll(RegExp(r'\s+'), '');
  final List<String> parts = normalized.split('.');
  if (parts.length != 2 || parts.first != 'POSREQ1') {
    throw const LicenseException(
        'El codigo de solicitud del dispositivo no es valido.');
  }
  return _decodeJsonSegment(parts[1]).cast<String, Object?>();
}

DateTime? readRequestedExpiryFromRequest(Map<String, Object?> payload) {
  final int? seconds = _readInt(payload['requestedExpiry']);
  if (seconds == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

Map<String, Object?> _decodeJsonSegment(String value) {
  final String normalized = base64Url.normalize(value);
  final Object? decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
  if (decoded is! Map) {
    throw const LicenseException(
        'No se pudo leer el contenido de la licencia.');
  }
  return decoded.cast<String, Object?>();
}

String _readString(Object? value) {
  return (value ?? '').toString().trim();
}

String? _readNullableString(Object? value) {
  final String resolved = _readString(value);
  return resolved.isEmpty ? null : resolved;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse((value ?? '').toString());
}

DateTime _readDate(Object? value) {
  final int? seconds = _readInt(value);
  if (seconds == null) {
    throw const LicenseException('La licencia no contiene una fecha valida.');
  }
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}
