import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/app_database.dart';
import 'license_models.dart';

class LicenseLocalDataSource {
  LicenseLocalDataSource(
    this._db, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AppDatabase _db;
  final FlutterSecureStorage _secureStorage;

  static const String _licenseTokenKey = 'offline_license_token_v1';
  static const String _trialStartedAtKey = 'offline_trial_started_at_v1';
  static const String _trialExpiresAtKey = 'offline_trial_expires_at_v1';
  static const String _trialStartedSecureKey =
      'offline_trial_started_at_secure_v1';
  static const String _trialExpiresSecureKey =
      'offline_trial_expires_at_secure_v1';
  static const String _lastSeenDbKey = 'offline_license_last_seen_v1';
  static const String _lastSeenSecureKey =
      'offline_license_last_seen_secure_v1';

  Future<String?> readLicenseToken() async {
    return _readSetting(_licenseTokenKey);
  }

  Future<void> writeLicenseToken(String value) {
    return _upsert(_licenseTokenKey, value.trim());
  }

  Future<void> clearLicenseToken() {
    return (_db.delete(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(_licenseTokenKey)))
        .go();
  }

  Future<StoredTrialState?> readTrialState() async {
    final Map<String, String> values = await _readSettings(<String>[
      _trialStartedAtKey,
      _trialExpiresAtKey,
    ]);
    final StoredTrialState? dbState = _parseTrialState(
      startedRaw: values[_trialStartedAtKey],
      expiresRaw: values[_trialExpiresAtKey],
    );

    final String? secureStartedRaw =
        await _secureStorage.read(key: _trialStartedSecureKey);
    final String? secureExpiresRaw =
        await _secureStorage.read(key: _trialExpiresSecureKey);
    final StoredTrialState? secureState = _parseTrialState(
      startedRaw: secureStartedRaw,
      expiresRaw: secureExpiresRaw,
    );

    if (dbState == null && secureState == null) {
      return null;
    }

    if (dbState != null && secureState == null) {
      return dbState;
    }
    if (dbState == null && secureState != null) {
      return secureState;
    }

    final DateTime startedAt =
        dbState!.startedAt.isBefore(secureState!.startedAt)
            ? dbState.startedAt
            : secureState.startedAt;
    final DateTime expiresAt = dbState.expiresAt.isBefore(secureState.expiresAt)
        ? dbState.expiresAt
        : secureState.expiresAt;
    if (!expiresAt.isAfter(startedAt)) {
      return dbState.expiresAt.isBefore(secureState.expiresAt)
          ? dbState
          : secureState;
    }
    return StoredTrialState(startedAt: startedAt, expiresAt: expiresAt);
  }

  Future<void> writeTrialState(StoredTrialState value) async {
    final String startedAt = value.startedAt.toIso8601String();
    final String expiresAt = value.expiresAt.toIso8601String();
    await _db.transaction(() async {
      await _upsert(_trialStartedAtKey, startedAt);
      await _upsert(_trialExpiresAtKey, expiresAt);
    });
    await _secureStorage.write(key: _trialStartedSecureKey, value: startedAt);
    await _secureStorage.write(key: _trialExpiresSecureKey, value: expiresAt);
  }

  Future<DateTime?> readLastSeenAt() async {
    final String? dbValue = await _readSetting(_lastSeenDbKey);
    final String? secureValue =
        await _secureStorage.read(key: _lastSeenSecureKey);
    final List<DateTime> parsed = <DateTime>[];
    final DateTime? parsedDbValue =
        dbValue == null ? null : DateTime.tryParse(dbValue);
    final DateTime? parsedSecureValue =
        secureValue == null ? null : DateTime.tryParse(secureValue);
    if (parsedDbValue != null) {
      parsed.add(parsedDbValue);
    }
    if (parsedSecureValue != null) {
      parsed.add(parsedSecureValue);
    }
    if (parsed.isEmpty) {
      return null;
    }
    parsed.sort();
    return parsed.last;
  }

  Future<void> writeLastSeenAt(DateTime value) async {
    final String encoded = value.toIso8601String();
    await _db.transaction(() async {
      await _upsert(_lastSeenDbKey, encoded);
    });
    await _secureStorage.write(key: _lastSeenSecureKey, value: encoded);
  }

  Future<void> clearPersistedActivation() async {
    await clearLicenseToken();
  }

  Future<Map<String, String>> _readSettings(List<String> keys) async {
    final List<AppSetting> rows = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.isIn(keys)))
        .get();
    return <String, String>{
      for (final AppSetting row in rows) row.key: row.value,
    };
  }

  Future<String?> _readSetting(String key) async {
    final AppSetting? row = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> _upsert(String key, String value) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  StoredTrialState? _parseTrialState({
    required String? startedRaw,
    required String? expiresRaw,
  }) {
    if (startedRaw == null || expiresRaw == null) {
      return null;
    }
    final DateTime? startedAt = DateTime.tryParse(startedRaw);
    final DateTime? expiresAt = DateTime.tryParse(expiresRaw);
    if (startedAt == null || expiresAt == null) {
      return null;
    }
    if (!expiresAt.isAfter(startedAt)) {
      return null;
    }
    return StoredTrialState(startedAt: startedAt, expiresAt: expiresAt);
  }
}
