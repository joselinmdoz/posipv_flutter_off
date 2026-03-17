import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database_provider.dart';
import 'device_identity_service.dart';
import 'license_local_datasource.dart';
import 'license_models.dart';
import 'license_service.dart';
import 'runtime_security_models.dart';
import 'runtime_security_service.dart';

final Provider<DeviceIdentityService> deviceIdentityServiceProvider =
    Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});

final Provider<LicenseLocalDataSource> licenseLocalDataSourceProvider =
    Provider<LicenseLocalDataSource>((ref) {
  return LicenseLocalDataSource(ref.watch(appDatabaseProvider));
});

final Provider<RuntimeSecurityService> runtimeSecurityServiceProvider =
    Provider<RuntimeSecurityService>((ref) {
  return RuntimeSecurityService();
});

final Provider<OfflineLicenseService> offlineLicenseServiceProvider =
    Provider<OfflineLicenseService>((ref) {
  return OfflineLicenseService(
    ref.watch(licenseLocalDataSourceProvider),
    ref.watch(deviceIdentityServiceProvider),
    ref.watch(runtimeSecurityServiceProvider),
  );
});

class LicenseController extends AsyncNotifier<LicenseStatus> {
  OfflineLicenseService get _service => ref.read(offlineLicenseServiceProvider);

  @override
  Future<LicenseStatus> build() {
    return _service.current();
  }

  Future<LicenseStatus> refresh() async {
    state = const AsyncLoading<LicenseStatus>();
    final AsyncValue<LicenseStatus> nextState =
        await AsyncValue.guard<LicenseStatus>(
      () => _service.current(forceRefresh: true),
    );
    state = nextState;
    return nextState.requireValue;
  }

  Future<LicenseStatus> activate(String rawCode) async {
    state = const AsyncLoading<LicenseStatus>();
    final AsyncValue<LicenseStatus> nextState =
        await AsyncValue.guard<LicenseStatus>(
      () => _service.activate(rawCode),
    );
    state = nextState;
    return nextState.requireValue;
  }

  Future<LicenseStatus> clearActivation() async {
    await _service.clearActivation();
    return refresh();
  }
}

final AsyncNotifierProvider<LicenseController, LicenseStatus>
    licenseControllerProvider =
    AsyncNotifierProvider<LicenseController, LicenseStatus>(
  LicenseController.new,
);

final Provider<LicenseStatus> currentLicenseStatusProvider =
    Provider<LicenseStatus>((ref) {
  return ref.watch(licenseControllerProvider).maybeWhen(
        data: (LicenseStatus status) => status,
        orElse: () => const LicenseStatus.loading(),
      );
});

class RuntimeSecurityController extends AsyncNotifier<RuntimeSecurityStatus> {
  RuntimeSecurityService get _service =>
      ref.read(runtimeSecurityServiceProvider);

  @override
  Future<RuntimeSecurityStatus> build() {
    return _service.inspect();
  }

  Future<RuntimeSecurityStatus> refresh() async {
    state = const AsyncLoading<RuntimeSecurityStatus>();
    final AsyncValue<RuntimeSecurityStatus> nextState =
        await AsyncValue.guard<RuntimeSecurityStatus>(
      () => _service.inspect(forceRefresh: true),
    );
    state = nextState;
    return nextState.requireValue;
  }
}

final AsyncNotifierProvider<RuntimeSecurityController, RuntimeSecurityStatus>
    runtimeSecurityControllerProvider =
    AsyncNotifierProvider<RuntimeSecurityController, RuntimeSecurityStatus>(
  RuntimeSecurityController.new,
);

final Provider<RuntimeSecurityStatus> currentRuntimeSecurityStatusProvider =
    Provider<RuntimeSecurityStatus>((ref) {
  return ref.watch(runtimeSecurityControllerProvider).maybeWhen(
        data: (RuntimeSecurityStatus status) => status,
        orElse: () => const RuntimeSecurityStatus.unsupported(),
      );
});
