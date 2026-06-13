import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/database_provider.dart';
import '../../sync_cloud/presentation/cloud_sync_providers.dart';
import '../data/pedidos_local_datasource.dart';
import '../data/work_order_delivery_report_service.dart';
import '../data/work_orders_report_service.dart';

final Provider<PedidosLocalDataSource> pedidosLocalDataSourceProvider =
    Provider<PedidosLocalDataSource>((Ref ref) {
  return PedidosLocalDataSource(
    ref.watch(appDatabaseProvider),
    cloudSyncLocalDataSource: ref.watch(cloudSyncLocalDataSourceProvider),
  );
});

final Provider<WorkOrderDeliveryReportService>
    workOrderDeliveryReportServiceProvider =
    Provider<WorkOrderDeliveryReportService>((Ref ref) {
  return WorkOrderDeliveryReportService();
});

final Provider<WorkOrdersReportService> workOrdersReportServiceProvider =
    Provider<WorkOrdersReportService>((Ref ref) {
  return WorkOrdersReportService();
});
