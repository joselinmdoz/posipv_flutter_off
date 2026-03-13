import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/configuracion_local_datasource.dart';

final Provider<ConfiguracionLocalDataSource>
    configuracionLocalDataSourceProvider =
    Provider<ConfiguracionLocalDataSource>((ref) {
  return ConfiguracionLocalDataSource(ref.watch(appDatabaseProvider));
});

class AppConfigController extends AsyncNotifier<AppConfig> {
  ConfiguracionLocalDataSource get _dataSource =>
      ref.read(configuracionLocalDataSourceProvider);

  @override
  Future<AppConfig> build() {
    return _dataSource.loadConfig();
  }

  Future<AppConfig> refresh() async {
    state = const AsyncLoading<AppConfig>();
    final AsyncValue<AppConfig> nextState =
        await AsyncValue.guard<AppConfig>(_dataSource.loadConfig);
    state = nextState;
    return nextState.requireValue;
  }

  Future<void> save(AppConfig config) async {
    final AppConfig previous = state.valueOrNull ?? AppConfig.defaults;
    state = AsyncData<AppConfig>(config);
    try {
      await _dataSource.saveConfig(config);
    } catch (error, stackTrace) {
      state = AsyncData<AppConfig>(previous);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

final AsyncNotifierProvider<AppConfigController, AppConfig>
    appConfigControllerProvider =
    AsyncNotifierProvider<AppConfigController, AppConfig>(
  AppConfigController.new,
);

final Provider<AppConfig> currentAppConfigProvider = Provider<AppConfig>((ref) {
  return ref.watch(appConfigControllerProvider).maybeWhen(
        data: (AppConfig config) => config,
        orElse: () => AppConfig.defaults,
      );
});

final Provider<ThemeMode> appThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(currentAppConfigProvider).themePreference.themeMode;
});
