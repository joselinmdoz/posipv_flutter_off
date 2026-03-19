import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/auth_local_datasource.dart';
import '../../shared/models/user_session.dart';

class LocalAuthService {
  LocalAuthService(
    this._authLocalDataSource, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final AuthLocalDataSource _authLocalDataSource;
  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();

  static const String _rememberedSessionKey = 'remembered_user_session_v1';
  static const String _appLockCredentialsKey = 'app_lock_credentials_v1';

  Future<void> ensureDefaultAdmin() {
    return _authLocalDataSource.ensureDefaultAdmin();
  }

  Future<UserSession?> login({
    required String username,
    required String password,
  }) async {
    final user = await _authLocalDataSource.validateCredentials(
      username: username,
      password: password,
    );
    if (user == null) {
      return null;
    }

    return UserSession(
      userId: user.id,
      username: user.username,
      role: user.role,
    );
  }

  Future<UserSession> createOfflineSession() async {
    await ensureDefaultAdmin();
    final user = await _authLocalDataSource.findPreferredActiveUser();
    if (user == null) {
      throw StateError('No hay usuarios activos para crear sesion.');
    }
    return UserSession(
      userId: user.id,
      username: user.username,
      role: user.role,
    );
  }

  Future<bool> isAppLockEnabled() async {
    final _AppLockCredentials? credentials = await _readAppLockCredentials();
    return credentials != null;
  }

  Future<void> setAppLockPassword(String password) async {
    final String normalized = password.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('La contrasena no puede estar vacia.');
    }
    final String salt = _newSalt();
    final String hash = _hashPassword(normalized, salt);
    final _AppLockCredentials credentials = _AppLockCredentials(
      salt: salt,
      hash: hash,
    );
    await _secureStorage.write(
      key: _appLockCredentialsKey,
      value: jsonEncode(credentials.toJson()),
    );
  }

  Future<void> clearAppLockPassword() {
    return _secureStorage.delete(key: _appLockCredentialsKey);
  }

  Future<bool> verifyAppLockPassword(String password) async {
    final _AppLockCredentials? credentials = await _readAppLockCredentials();
    if (credentials == null) {
      return true;
    }
    final String expectedHash =
        _hashPassword(password.trim(), credentials.salt);
    return expectedHash == credentials.hash;
  }

  Future<UserSession?> unlockWithAppPassword(String password) async {
    final bool canUnlock = await verifyAppLockPassword(password);
    if (!canUnlock) {
      return null;
    }
    return createOfflineSession();
  }

  Future<void> persistSession({
    required UserSession session,
    required bool rememberOnDevice,
  }) async {
    if (!rememberOnDevice) {
      await clearRememberedSession();
      return;
    }
    await _secureStorage.write(
      key: _rememberedSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<UserSession?> restoreRememberedSession() async {
    try {
      final String? raw = await _secureStorage.read(key: _rememberedSessionKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final UserSession session = UserSession.fromJson(
        decoded.cast<String, Object?>(),
      );
      if (session.userId.isEmpty ||
          session.username.isEmpty ||
          session.role.isEmpty) {
        return null;
      }
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearRememberedSession() {
    return _secureStorage.delete(key: _rememberedSessionKey);
  }

  Future<_AppLockCredentials?> _readAppLockCredentials() async {
    try {
      final String? raw =
          await _secureStorage.read(key: _appLockCredentialsKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final _AppLockCredentials credentials = _AppLockCredentials.fromJson(
        decoded.cast<String, Object?>(),
      );
      if (credentials.salt.isEmpty || credentials.hash.isEmpty) {
        return null;
      }
      return credentials;
    } catch (_) {
      return null;
    }
  }

  String _newSalt() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final List<int> bytes = utf8.encode('$password::$salt');
    return sha256.convert(bytes).toString();
  }
}

class _AppLockCredentials {
  const _AppLockCredentials({
    required this.salt,
    required this.hash,
  });

  final String salt;
  final String hash;

  factory _AppLockCredentials.fromJson(Map<String, Object?> json) {
    return _AppLockCredentials(
      salt: (json['salt'] as String? ?? '').trim(),
      hash: (json['hash'] as String? ?? '').trim(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'salt': salt,
      'hash': hash,
    };
  }
}
