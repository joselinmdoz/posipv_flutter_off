import '../../../configuracion/data/configuracion_local_datasource.dart';
import '../../data/pedidos_local_datasource.dart';

List<WorkOrderPaymentValue> buildWorkOrderPaymentVariants({
  required List<WorkOrderCostTotal> totals,
  required AppCurrencyConfig currencyConfig,
  required WorkOrderPaymentDisplayConfig paymentDisplayConfig,
}) {
  if (totals.isEmpty) {
    return const <WorkOrderPaymentValue>[];
  }

  final String localCode = paymentDisplayConfig.localCurrencyCode;
  final String foreignCode = paymentDisplayConfig.foreignCurrencyCode;
  final int foreignTotal = _convertTotalsToCurrency(
    totals: totals,
    targetCurrencyCode: foreignCode,
    currencyConfig: currencyConfig,
    paymentDisplayConfig: paymentDisplayConfig,
  );
  final int localCash = _convertTotalsToCurrency(
    totals: totals,
    targetCurrencyCode: localCode,
    currencyConfig: currencyConfig,
    paymentDisplayConfig: paymentDisplayConfig,
    useLocalCashRate: true,
  );
  final int localTransfer = (localCash *
          (1 + paymentDisplayConfig.localTransferPercentSurcharge / 100))
      .round();

  return <WorkOrderPaymentValue>[
    WorkOrderPaymentValue(
      label: foreignCode,
      currencyCode: foreignCode,
      amountCents: foreignTotal,
    ),
    WorkOrderPaymentValue(
      label: '$localCode Efectivo',
      currencyCode: localCode,
      amountCents: localCash,
    ),
    WorkOrderPaymentValue(
      label: '$localCode Transfer.',
      currencyCode: localCode,
      amountCents: localTransfer,
    ),
  ];
}

List<WorkOrderPaymentValue> buildWorkOrderPaymentVariantsFromSnapshot({
  required List<WorkOrderCostTotal> totals,
  required WorkOrderPricingSnapshot pricingSnapshot,
}) {
  if (totals.isEmpty) {
    return const <WorkOrderPaymentValue>[];
  }
  final String localCode =
      pricingSnapshot.localCurrencyCode.trim().toUpperCase();
  final String foreignCode =
      pricingSnapshot.foreignCurrencyCode.trim().toUpperCase();
  final int foreignTotal = _convertTotalsToCurrencyWithSnapshot(
    totals: totals,
    targetCurrencyCode: foreignCode,
    pricingSnapshot: pricingSnapshot,
  );
  final int localCash = _convertTotalsToCurrencyWithSnapshot(
    totals: totals,
    targetCurrencyCode: localCode,
    pricingSnapshot: pricingSnapshot,
    useLocalCashRate: true,
  );
  final int localTransfer =
      (localCash * (1 + pricingSnapshot.localTransferPercentSurcharge / 100))
          .round();
  return <WorkOrderPaymentValue>[
    WorkOrderPaymentValue(
      label: foreignCode,
      currencyCode: foreignCode,
      amountCents: foreignTotal,
    ),
    WorkOrderPaymentValue(
      label: '$localCode Efectivo',
      currencyCode: localCode,
      amountCents: localCash,
    ),
    WorkOrderPaymentValue(
      label: '$localCode Transfer.',
      currencyCode: localCode,
      amountCents: localTransfer,
    ),
  ];
}

int _convertTotalsToCurrency({
  required List<WorkOrderCostTotal> totals,
  required String targetCurrencyCode,
  required AppCurrencyConfig currencyConfig,
  required WorkOrderPaymentDisplayConfig paymentDisplayConfig,
  bool useLocalCashRate = false,
}) {
  int total = 0;
  for (final WorkOrderCostTotal row in totals) {
    total += _convertCents(
      amountCents: row.totalCostCents,
      sourceCurrencyCode: row.currencyCode,
      targetCurrencyCode: targetCurrencyCode,
      currencyConfig: currencyConfig,
      paymentDisplayConfig: paymentDisplayConfig,
      useLocalCashRate: useLocalCashRate,
    );
  }
  return total;
}

int _convertCents({
  required int amountCents,
  required String sourceCurrencyCode,
  required String targetCurrencyCode,
  required AppCurrencyConfig currencyConfig,
  required WorkOrderPaymentDisplayConfig paymentDisplayConfig,
  required bool useLocalCashRate,
}) {
  final String source = sourceCurrencyCode.trim().toUpperCase();
  final String target = targetCurrencyCode.trim().toUpperCase();
  if (source == target) {
    return amountCents;
  }

  final String primary =
      currencyConfig.primaryCurrencyCode.trim().toUpperCase();
  final AppCurrencySetting? sourceSetting =
      currencyConfig.currencyByCode(source);
  final AppCurrencySetting? targetSetting =
      currencyConfig.currencyByCode(target);
  if (sourceSetting == null || targetSetting == null) {
    return amountCents;
  }

  final double sourceAmount = amountCents / 100;
  final double amountInPrimary = source == primary
      ? sourceAmount
      : sourceAmount /
          (sourceSetting.rateToPrimary <= 0 ? 1 : sourceSetting.rateToPrimary);
  final bool applyLocalCashRate = useLocalCashRate &&
      source == paymentDisplayConfig.foreignCurrencyCode &&
      target == paymentDisplayConfig.localCurrencyCode &&
      source != target;
  final double targetRate = applyLocalCashRate
      ? ((targetSetting.rateToPrimary <= 0 ? 1 : targetSetting.rateToPrimary) +
          paymentDisplayConfig.localCashFixedSurcharge)
      : (targetSetting.rateToPrimary <= 0 ? 1 : targetSetting.rateToPrimary);
  final double targetAmount =
      target == primary ? amountInPrimary : amountInPrimary * targetRate;
  return (targetAmount * 100).round();
}

int _convertTotalsToCurrencyWithSnapshot({
  required List<WorkOrderCostTotal> totals,
  required String targetCurrencyCode,
  required WorkOrderPricingSnapshot pricingSnapshot,
  bool useLocalCashRate = false,
}) {
  int total = 0;
  for (final WorkOrderCostTotal row in totals) {
    total += _convertCentsWithSnapshot(
      amountCents: row.totalCostCents,
      sourceCurrencyCode: row.currencyCode,
      targetCurrencyCode: targetCurrencyCode,
      pricingSnapshot: pricingSnapshot,
      useLocalCashRate: useLocalCashRate,
    );
  }
  return total;
}

int _convertCentsWithSnapshot({
  required int amountCents,
  required String sourceCurrencyCode,
  required String targetCurrencyCode,
  required WorkOrderPricingSnapshot pricingSnapshot,
  required bool useLocalCashRate,
}) {
  final String source = sourceCurrencyCode.trim().toUpperCase();
  final String target = targetCurrencyCode.trim().toUpperCase();
  if (source == target) {
    return amountCents;
  }
  final String primary =
      pricingSnapshot.primaryCurrencyCode.trim().toUpperCase();
  final double sourceRate = pricingSnapshot.ratesByCode[source] ?? 1;
  final double targetRate = pricingSnapshot.ratesByCode[target] ?? 1;
  final double sourceAmount = amountCents / 100;
  final double amountInPrimary = source == primary
      ? sourceAmount
      : sourceAmount / (sourceRate <= 0 ? 1 : sourceRate);
  final bool applyLocalCashRate = useLocalCashRate &&
      source == pricingSnapshot.foreignCurrencyCode.trim().toUpperCase() &&
      target == pricingSnapshot.localCurrencyCode.trim().toUpperCase() &&
      source != target;
  final double resolvedTargetRate = applyLocalCashRate
      ? ((targetRate <= 0 ? 1 : targetRate) +
          pricingSnapshot.localCashFixedSurcharge)
      : (targetRate <= 0 ? 1 : targetRate);
  final double targetAmount = target == primary
      ? amountInPrimary
      : amountInPrimary * resolvedTargetRate;
  return (targetAmount * 100).round();
}
