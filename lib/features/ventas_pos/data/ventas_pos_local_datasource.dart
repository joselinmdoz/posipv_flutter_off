import '../../../core/utils/app_result.dart';
import '../domain/sale_models.dart';
import 'sale_service.dart';

class VentasPosLocalDataSource {
  VentasPosLocalDataSource(this._saleService);

  final SaleService _saleService;

  Future<AppResult<CreateSaleResult>> createSale(CreateSaleInput input) {
    return _saleService.createSale(input);
  }
}
