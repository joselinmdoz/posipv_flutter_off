import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;
  final Random _random = Random.secure();

  Future<void> ensureDefaultAdmin({
    String username = 'admin',
    String password = 'admin123',
  }) async {
    final User? existing = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.username.equals(username)))
        .getSingleOrNull();
    if (existing != null) {
      return;
    }

    await createUser(
      username: username,
      password: password,
      role: 'admin',
    );
  }

  Future<String> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final String salt = _newSalt();
    final String hash = _hashPassword(password, salt);
    final String id = _uuid.v4();

    await _db.into(_db.users).insert(
          UsersCompanion.insert(
            id: id,
            username: username,
            passwordHash: hash,
            salt: salt,
            role: Value(role),
          ),
        );

    return id;
  }

  Future<User?> validateCredentials({
    required String username,
    required String password,
  }) async {
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.username.equals(username)))
        .getSingleOrNull();

    if (user == null || !user.isActive) {
      return null;
    }

    final String expectedHash = _hashPassword(password, user.salt);
    if (expectedHash != user.passwordHash) {
      return null;
    }

    return user;
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
