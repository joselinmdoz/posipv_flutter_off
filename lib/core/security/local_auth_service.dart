import '../../features/auth/data/auth_local_datasource.dart';
import '../../shared/models/user_session.dart';

class LocalAuthService {
  LocalAuthService(this._authLocalDataSource);

  final AuthLocalDataSource _authLocalDataSource;

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
}
