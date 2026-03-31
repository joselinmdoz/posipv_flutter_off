import '../../../core/utils/app_result.dart';
import '../domain/sale_models.dart';
import 'sale_service.dart';

class VentasPosLocalDataSource {
  VentasPosLocalDataSource(this._saleService);

  final SaleService _saleService;

  Future<AppResult<CreateSaleResult>> createSale(CreateSaleInput input) {
    return _saleService.createSale(input);
  }

  Future<void> updateSale(UpdateSaleInput input) {
    return _saleService.updateSale(input);
  }

  Future<List<ArchivedSaleView>> listArchivedSales({
    String? search,
    int limit = 250,
  }) {
    return _saleService.listArchivedSales(
      search: search,
      limit: limit,
    );
  }

  Future<void> archiveSale({
    required String saleId,
    required String userId,
    String? note,
  }) {
    return _saleService.archiveSale(
      saleId: saleId,
      userId: userId,
      note: note,
    );
  }

  Future<void> restoreArchivedSale({
    required String saleId,
    required String userId,
    bool allowNegativeResult = false,
  }) {
    return _saleService.restoreArchivedSale(
      saleId: saleId,
      userId: userId,
      allowNegativeResult: allowNegativeResult,
    );
  }

  Future<void> permanentlyDeleteArchivedSale({
    required String saleId,
    required String userId,
  }) {
    return _saleService.permanentlyDeleteArchivedSale(
      saleId: saleId,
      userId: userId,
    );
  }
}
