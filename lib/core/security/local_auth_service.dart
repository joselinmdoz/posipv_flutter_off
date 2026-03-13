import 'dart:convert';

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

  static const String _rememberedSessionKey = 'remembered_user_session_v1';

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
}
