import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/tpv_local_datasource.dart';

final Provider<TpvLocalDataSource> tpvLocalDataSourceProvider =
    Provider<TpvLocalDataSource>((ref) {
  return TpvLocalDataSource(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});

final FutureProvider<List<TpvTerminalView>> tpvTerminalsProvider = 
    FutureProvider<List<TpvTerminalView>>((ref) async {
  return ref.watch(tpvLocalDataSourceProvider).listActiveTerminalViews();
});
