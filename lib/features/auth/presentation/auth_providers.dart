import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/security/local_auth_service.dart';
import '../../../shared/models/user_session.dart';
import '../data/auth_local_datasource.dart';

final Provider<AuthLocalDataSource> authLocalDataSourceProvider =
    Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource(ref.watch(appDatabaseProvider));
});

final Provider<LocalAuthService> localAuthServiceProvider =
    Provider<LocalAuthService>((ref) {
  return LocalAuthService(ref.watch(authLocalDataSourceProvider));
});

final StateProvider<UserSession?> currentSessionProvider =
    StateProvider<UserSession?>((_) => null);
