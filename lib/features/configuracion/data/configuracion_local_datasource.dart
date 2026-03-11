import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';

class AppConfig {
  const AppConfig({
    required this.businessName,
    required this.currencySymbol,
    required this.allowNegativeStock,
  });

  static const String defaultBusinessName = 'Mi Negocio';
  static const String defaultCurrencySymbol = r'$';

  static const AppConfig defaults = AppConfig(
    businessName: defaultBusinessName,
    currencySymbol: defaultCurrencySymbol,
    allowNegativeStock: false,
  );

  final String businessName;
  final String currencySymbol;
  final bool allowNegativeStock;
}

class ConfiguracionLocalDataSource {
  ConfiguracionLocalDataSource(this._db);

  final AppDatabase _db;

  static const String _kBusinessName = 'business_name';
  static const String _kCurrencySymbol = 'currency_symbol';
  static const String _kAllowNegativeStock = 'allow_negative_stock';

  Future<AppConfig> loadConfig() async {
    final List<AppSetting> rows = await (_db.select(_db.appSettings)
          ..where(
            (AppSettings tbl) =>
                tbl.key.isIn(<String>[
                  _kBusinessName,
                  _kCurrencySymbol,
                  _kAllowNegativeStock
                ]) &
                tbl.key.isNotNull() &
                tbl.value.isNotNull(),
          ))
        .get();

    final Map<String, String> values = <String, String>{
      for (final AppSetting row in rows) row.key: row.value,
    };

    return AppConfig(
      businessName: values[_kBusinessName] ?? AppConfig.defaultBusinessName,
      currencySymbol: _sanitizeCurrency(values[_kCurrencySymbol]),
      allowNegativeStock: values[_kAllowNegativeStock] == '1',
    );
  }

  Future<void> saveConfig(AppConfig config) async {
    await _db.transaction(() async {
      await _upsert(_kBusinessName, config.businessName.trim());
      await _upsert(_kCurrencySymbol, _sanitizeCurrency(config.currencySymbol));
      await _upsert(
          _kAllowNegativeStock, config.allowNegativeStock ? '1' : '0');
    });
  }

  Future<bool> isNegativeStockAllowed() async {
    final AppConfig config = await loadConfig();
    return config.allowNegativeStock;
  }

  Future<String> currencySymbol() async {
    final AppConfig config = await loadConfig();
    return config.currencySymbol;
  }

  Future<void> _upsert(String key, String value) {
    return _db.into(_db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  String _sanitizeCurrency(String? value) {
    final String v = (value ?? AppConfig.defaultCurrencySymbol).trim();
    if (v.isEmpty) {
      return AppConfig.defaultCurrencySymbol;
    }
    if (v.length > 3) {
      return v.substring(0, 3);
    }
    return v;
  }
}
