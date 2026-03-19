import 'package:flutter/foundation.dart';

import 'device_identity_service.dart';
import 'license_local_datasource.dart';
import 'license_models.dart';
import 'runtime_security_models.dart';
import 'runtime_security_service.dart';

class OfflineLicenseService {
  OfflineLicenseService(
    this._localDataSource,
    this._deviceIdentityService,
    this._runtimeSecurityService,
  );

  final LicenseLocalDataSource _localDataSource;
  final DeviceIdentityService _deviceIdentityService;
  final RuntimeSecurityService _runtimeSecurityService;

  static const Duration _trialDuration = Duration(days: 10);
  static const Duration _rollbackTolerance = Duration(minutes: 10);
  static const Duration _cacheLifetime = Duration(seconds: 20);

  LicenseStatus? _cachedStatus;
  DateTime? _cachedAt;

  Future<LicenseStatus> current({bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    if (!forceRefresh &&
        _cachedStatus != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) <= _cacheLifetime) {
      return _cachedStatus!;
    }

    final DeviceIdentity identity = await _deviceIdentityService.getIdentity();
    final DateTime? lastSeenAt = await _localDataSource.readLastSeenAt();
    final StoredTrialState? persistedTrialState =
        await _localDataSource.readTrialState();
    final StoredTrialState trialState;
    try {
      trialState = await _ensureTrialState(
        now,
        persistedTrialState: persistedTrialState,
        lastSeenAt: lastSeenAt,
      );
    } on LicenseException {
      return _cache(
        LicenseStatus.blocked(
          deviceIdentity: identity,
          checkedAt: now,
          reason: LicenseBlockReason.corruptedState,
        ),
        now,
      );
    }
    final RuntimeSecurityStatus runtimeSecurity = kDebugMode
        ? const RuntimeSecurityStatus.unsupported()
        : await _runtimeSecurityService.inspect(
            forceRefresh: forceRefresh,
          );

    if (runtimeSecurity.shouldBlock) {
      return _cache(
        LicenseStatus.blocked(
          deviceIdentity: identity,
          checkedAt: now,
          reason: LicenseBlockReason.unsafeRuntime,
          messageOverride: runtimeSecurity.summaryMessage,
          startedAt: trialState.startedAt,
          expiresAt: trialState.expiresAt,
        ),
        now,
      );
    }

    if (lastSeenAt != null &&
        now.isBefore(lastSeenAt.subtract(_rollbackTolerance))) {
      return _cache(
        LicenseStatus.blocked(
          deviceIdentity: identity,
          checkedAt: now,
          reason: LicenseBlockReason.clockRollback,
          startedAt: trialState.startedAt,
          expiresAt: trialState.expiresAt,
        ),
        now,
      );
    }

    final String? rawToken = await _localDataSource.readLicenseToken();
    if (rawToken != null && rawToken.trim().isNotEmpty) {
      final LicenseStatus? activatedStatus =
          await _validateActivatedToken(rawToken, identity, now);
      if (activatedStatus != null) {
        await _localDataSource.writeLastSeenAt(now);
        return _cache(activatedStatus, now);
      }
    }

    await _localDataSource.writeLastSeenAt(now);
    return _cache(
      LicenseStatus.trial(
        deviceIdentity: identity,
        checkedAt: now,
        startedAt: trialState.startedAt,
      ),
      now,
    );
  }

  Future<LicenseStatus> activate(String rawCode) async {
    final DateTime now = DateTime.now();
    final DeviceIdentity identity = await _deviceIdentityService.getIdentity();
    final ParsedLicenseToken token = ParsedLicenseToken.parse(rawCode.trim());
    final LicenseStatus status =
        await _validateTokenOrThrow(token, identity, now);
    await _localDataSource.writeLicenseToken(token.raw);
    await _localDataSource.writeLastSeenAt(now);
    return _cache(status, now);
  }

  Future<void> clearActivation() async {
    await _localDataSource.clearPersistedActivation();
    _cachedStatus = null;
    _cachedAt = null;
  }

  Future<DeviceIdentity> loadDeviceIdentity() {
    return _deviceIdentityService.getIdentity();
  }

  String buildRequestCode(
    DeviceIdentity identity, {
    DateTime? requestedExpiry,
  }) {
    return _deviceIdentityService.buildRequestCode(
      identity,
      requestedExpiry: requestedExpiry,
    );
  }

  Future<bool> shareRequestCode({
    required String requestCode,
    String? subject,
  }) {
    return _deviceIdentityService.shareText(
      text: requestCode,
      subject: subject,
    );
  }

  Future<RuntimeSecurityStatus> loadRuntimeSecurity({
    bool forceRefresh = false,
  }) {
    return _runtimeSecurityService.inspect(forceRefresh: forceRefresh);
  }

  Future<void> requireWriteAccess() async {
    final LicenseStatus status = await current();
    if (!status.canWrite) {
      throw LicenseException(status.message);
    }
  }

  Future<void> requireSalesAccess() async {
    final LicenseStatus status = await current();
    if (!status.canSell) {
      throw LicenseException(status.message);
    }
  }

  Future<StoredTrialState> _ensureTrialState(
    DateTime now, {
    required StoredTrialState? persistedTrialState,
    required DateTime? lastSeenAt,
  }) async {
    if (persistedTrialState != null) {
      return persistedTrialState;
    }
    if (lastSeenAt != null) {
      throw const LicenseException(
        'No se encontro el estado del trial en un dispositivo ya usado.',
      );
    }

    final StoredTrialState created = StoredTrialState(
      startedAt: now,
      expiresAt: now.add(_trialDuration),
    );
    await _localDataSource.writeTrialState(created);
    return created;
  }

  Future<LicenseStatus?> _validateActivatedToken(
    String rawToken,
    DeviceIdentity identity,
    DateTime now,
  ) async {
    try {
      final ParsedLicenseToken token = ParsedLicenseToken.parse(rawToken);
      return await _validateTokenOrThrow(token, identity, now);
    } on LicenseException catch (error) {
      debugPrint('Offline license validation failed: $error');
      return null;
    } catch (error) {
      debugPrint('Offline license validation failed: $error');
      return null;
    }
  }

  Future<LicenseStatus> _validateTokenOrThrow(
    ParsedLicenseToken token,
    DeviceIdentity identity,
    DateTime now,
  ) async {
    final bool signatureValid = await _deviceIdentityService.verifySignature(
      payloadSegment: token.payloadSegment,
      signatureSegment: token.signatureSegment,
    );
    if (!signatureValid) {
      throw const LicenseException('La firma de la licencia no es valida.');
    }

    if (token.deviceFingerprint != identity.fingerprintHash) {
      throw const LicenseException(
          'La licencia fue emitida para otro dispositivo.');
    }

    if (now.isAfter(token.expiresAt)) {
      throw const LicenseException('La licencia cargada ya expiro.');
    }

    return LicenseStatus.full(
      deviceIdentity: identity,
      checkedAt: now,
      expiresAt: token.expiresAt,
      licenseId: token.licenseId,
      customerName: token.customerName,
    );
  }

  LicenseStatus _cache(LicenseStatus status, DateTime cachedAt) {
    _cachedStatus = status;
    _cachedAt = cachedAt;
    return status;
  }
}
