import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/tpv_local_datasource.dart';

final Provider<TpvLocalDataSource> tpvLocalDataSourceProvider =
    Provider<TpvLocalDataSource>((ref) {
  return TpvLocalDataSource(ref.watch(appDatabaseProvider));
});
