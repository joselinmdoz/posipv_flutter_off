import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../../core/licensing/license_providers.dart';
import '../data/sale_service.dart';
import '../data/ventas_pos_local_datasource.dart';
import '../../configuracion/data/configuracion_local_datasource.dart';
import '../../configuracion/presentation/configuracion_providers.dart';

final Provider<SaleService> saleServiceProvider = Provider<SaleService>((ref) {
  return SaleService(
    ref.watch(appDatabaseProvider),
    licenseService: ref.watch(offlineLicenseServiceProvider),
  );
});

final Provider<VentasPosLocalDataSource> ventasPosLocalDataSourceProvider =
    Provider<VentasPosLocalDataSource>((ref) {
  return VentasPosLocalDataSource(ref.watch(saleServiceProvider));
});

final FutureProvider<List<AppPaymentMethodSetting>>
    paymentMethodOptionsProvider =
    FutureProvider<List<AppPaymentMethodSetting>>((ref) async {
  return ref.watch(configuracionLocalDataSourceProvider).loadPaymentMethodSettings();
});
