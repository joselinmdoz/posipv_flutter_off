import '../../../core/utils/app_result.dart';
import 'sale_models.dart';

abstract class VentasPosRepository {
  Future<AppResult<CreateSaleResult>> createSale(CreateSaleInput input);
}
