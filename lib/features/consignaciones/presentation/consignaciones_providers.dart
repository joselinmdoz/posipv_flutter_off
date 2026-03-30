import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../data/consignaciones_local_datasource.dart';

final Provider<ConsignacionesLocalDataSource>
    consignacionesLocalDataSourceProvider =
    Provider<ConsignacionesLocalDataSource>((Ref ref) {
  return ConsignacionesLocalDataSource(
    ref.watch(appDatabaseProvider),
    ConfiguracionLocalDataSource(ref.watch(appDatabaseProvider)),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});
