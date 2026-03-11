import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../data/sale_service.dart';
import '../data/ventas_pos_local_datasource.dart';

final Provider<SaleService> saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(ref.watch(appDatabaseProvider));
});

final Provider<VentasPosLocalDataSource> ventasPosLocalDataSourceProvider =
    Provider<VentasPosLocalDataSource>((ref) {
  return VentasPosLocalDataSource(ref.watch(saleServiceProvider));
});
