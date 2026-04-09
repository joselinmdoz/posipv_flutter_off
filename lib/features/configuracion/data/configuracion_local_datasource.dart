import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../../../shared/models/dashboard_widget_config.dart';

enum AppThemePreference {
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  String get storageValue => switch (this) {
        AppThemePreference.light => 'light',
        AppThemePreference.dark => 'dark',
      };

  static AppThemePreference fromStorage(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'dark':
        return AppThemePreference.dark;
      case 'light':
      default:
        return AppThemePreference.light;
    }
  }
}

class AppExchangeRateHistoryEntry {
  const AppExchangeRateHistoryEntry({
    required this.currencyCode,
    required this.baseCurrencyCode,
    required this.rateToBase,
    required this.changedAt,
  });

  final String currencyCode;
  final String baseCurrencyCode;
  final double rateToBase;
  final DateTime changedAt;

  factory AppExchangeRateHistoryEntry.fromJson(Map<String, Object?> json) {
    final String currencyCode = (json['currencyCode'] as String? ?? '').trim();
    final String baseCurrencyCode =
        (json['baseCurrencyCode'] as String? ?? '').trim();
    final double rateToBase = _asDouble(json['rateToBase']) ?? 1;
    final DateTime changedAt =
        DateTime.tryParse((json['changedAt'] as String? ?? '').trim()) ??
            DateTime.now().toUtc();
    return AppExchangeRateHistoryEntry(
      currencyCode: currencyCode,
      baseCurrencyCode: baseCurrencyCode,
      rateToBase: rateToBase,
      changedAt: changedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'currencyCode': currencyCode,
      'baseCurrencyCode': baseCurrencyCode,
      'rateToBase': rateToBase,
      'changedAt': changedAt.toUtc().toIso8601String(),
    };
  }
}

class AppCurrencySetting {
  const AppCurrencySetting({
    required this.code,
    required this.symbol,
    required this.rateToPrimary,
  });

  final String code;
  final String symbol;
  final double rateToPrimary;

  factory AppCurrencySetting.fromJson(Map<String, Object?> json) {
    return AppCurrencySetting(
      code: (json['code'] as String? ?? '').trim(),
      symbol: (json['symbol'] as String? ?? '').trim(),
      rateToPrimary: _asDouble(json['rateToPrimary']) ?? 1,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code,
      'symbol': symbol,
      'rateToPrimary': rateToPrimary,
    };
  }

  AppCurrencySetting copyWith({
    String? code,
    String? symbol,
    double? rateToPrimary,
  }) {
    return AppCurrencySetting(
      code: code ?? this.code,
      symbol: symbol ?? this.symbol,
      rateToPrimary: rateToPrimary ?? this.rateToPrimary,
    );
  }
}

class AppCurrencyConfig {
  const AppCurrencyConfig({
    required this.primaryCurrencyCode,
    required this.currencies,
    required this.rateHistory,
  });

  static const AppCurrencyConfig defaults = AppCurrencyConfig(
    primaryCurrencyCode: 'CUP',
    currencies: <AppCurrencySetting>[
      AppCurrencySetting(code: 'CUP', symbol: '₱', rateToPrimary: 1),
      AppCurrencySetting(code: 'USD', symbol: r'$', rateToPrimary: 1),
    ],
    rateHistory: <AppExchangeRateHistoryEntry>[],
  );

  final String primaryCurrencyCode;
  final List<AppCurrencySetting> currencies;
  final List<AppExchangeRateHistoryEntry> rateHistory;

  factory AppCurrencyConfig.fromJson(Map<String, Object?> json) {
    final List<AppCurrencySetting> currencies = <AppCurrencySetting>[];
    final Object? rawCurrencies = json['currencies'];
    if (rawCurrencies is List) {
      for (final Object? item in rawCurrencies) {
        if (item is Map) {
          currencies.add(
            AppCurrencySetting.fromJson(item.cast<String, Object?>()),
          );
        }
      }
    }

    final List<AppExchangeRateHistoryEntry> history =
        <AppExchangeRateHistoryEntry>[];
    final Object? rawHistory = json['rateHistory'];
    if (rawHistory is List) {
      for (final Object? item in rawHistory) {
        if (item is Map) {
          history.add(
            AppExchangeRateHistoryEntry.fromJson(
              item.cast<String, Object?>(),
            ),
          );
        }
      }
    }

    return AppCurrencyConfig(
      primaryCurrencyCode:
          (json['primaryCurrencyCode'] as String? ?? '').trim(),
      currencies: currencies,
      rateHistory: history,
    ).normalized();
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primaryCurrencyCode': primaryCurrencyCode,
      'currencies':
          currencies.map((AppCurrencySetting c) => c.toJson()).toList(),
      'rateHistory': rateHistory
          .map((AppExchangeRateHistoryEntry h) => h.toJson())
          .toList(),
    };
  }

  AppCurrencyConfig copyWith({
    String? primaryCurrencyCode,
    List<AppCurrencySetting>? currencies,
    List<AppExchangeRateHistoryEntry>? rateHistory,
  }) {
    return AppCurrencyConfig(
      primaryCurrencyCode: primaryCurrencyCode ?? this.primaryCurrencyCode,
      currencies: currencies ?? this.currencies,
      rateHistory: rateHistory ?? this.rateHistory,
    ).normalized();
  }

  AppCurrencySetting get primaryCurrency {
    return currencyByCode(primaryCurrencyCode) ??
        const AppCurrencySetting(
          code: 'CUP',
          symbol: '₱',
          rateToPrimary: 1,
        );
  }

  AppCurrencySetting? currencyByCode(String code) {
    final String target = _sanitizeCurrencyCode(code);
    for (final AppCurrencySetting currency in currencies) {
      if (_sanitizeCurrencyCode(currency.code) == target) {
        return currency;
      }
    }
    return null;
  }

  String symbolForCode(String code) {
    return currencyByCode(code)?.symbol ?? _defaultSymbolForCode(code);
  }

  AppCurrencyConfig normalized() {
    final Map<String, AppCurrencySetting> byCode =
        <String, AppCurrencySetting>{};

    for (final AppCurrencySetting raw in currencies) {
      final String code = _sanitizeCurrencyCode(raw.code);
      if (code.isEmpty || byCode.containsKey(code)) {
        continue;
      }
      final String symbol = _sanitizeCurrencySymbol(
        raw.symbol,
        fallback: _defaultSymbolForCode(code),
      );
      final double rate = raw.rateToPrimary.isFinite && raw.rateToPrimary > 0
          ? raw.rateToPrimary
          : 1;
      byCode[code] = AppCurrencySetting(
        code: code,
        symbol: symbol,
        rateToPrimary: rate,
      );
    }

    String normalizedPrimary = _sanitizeCurrencyCode(primaryCurrencyCode);
    if (normalizedPrimary.isEmpty) {
      normalizedPrimary = 'CUP';
    }

    if (!byCode.containsKey(normalizedPrimary)) {
      byCode[normalizedPrimary] = AppCurrencySetting(
        code: normalizedPrimary,
        symbol: _defaultSymbolForCode(normalizedPrimary),
        rateToPrimary: 1,
      );
    }

    byCode[normalizedPrimary] = byCode[normalizedPrimary]!.copyWith(
      rateToPrimary: 1,
      symbol: _sanitizeCurrencySymbol(
        byCode[normalizedPrimary]!.symbol,
        fallback: _defaultSymbolForCode(normalizedPrimary),
      ),
    );

    final List<AppCurrencySetting> normalizedCurrencies = byCode.values.toList()
      ..sort((AppCurrencySetting a, AppCurrencySetting b) {
        if (a.code == normalizedPrimary) {
          return -1;
        }
        if (b.code == normalizedPrimary) {
          return 1;
        }
        return a.code.compareTo(b.code);
      });

    final List<AppExchangeRateHistoryEntry> normalizedHistory =
        rateHistory.where((AppExchangeRateHistoryEntry entry) {
      final String code = _sanitizeCurrencyCode(entry.currencyCode);
      final String base = _sanitizeCurrencyCode(entry.baseCurrencyCode);
      return code.isNotEmpty &&
          base.isNotEmpty &&
          entry.rateToBase.isFinite &&
          entry.rateToBase > 0;
    }).toList()
          ..sort(
            (AppExchangeRateHistoryEntry a, AppExchangeRateHistoryEntry b) =>
                b.changedAt.compareTo(a.changedAt),
          );

    final List<AppExchangeRateHistoryEntry> boundedHistory =
        normalizedHistory.length <= 200
            ? normalizedHistory
            : normalizedHistory.sublist(0, 200);

    return AppCurrencyConfig(
      primaryCurrencyCode: normalizedPrimary,
      currencies: normalizedCurrencies,
      rateHistory: boundedHistory,
    );
  }
}

class AppPaymentMethodSetting {
  const AppPaymentMethodSetting({
    required this.code,
    required this.isOnline,
    this.displayName,
  });

  final String code;
  final bool isOnline;
  final String? displayName;

  factory AppPaymentMethodSetting.fromJson(Map<String, Object?> json) {
    final String rawCode = (json['code'] as String? ?? '').trim().toLowerCase();
    final String? rawDisplayName =
        (json['displayName'] as String? ?? json['name'] as String?)?.trim();
    return AppPaymentMethodSetting(
      code: rawCode,
      isOnline: json['isOnline'] == true,
      displayName: (rawDisplayName == null || rawDisplayName.isEmpty)
          ? null
          : rawDisplayName,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code,
      'isOnline': isOnline,
      'displayName': displayName,
    };
  }

  AppPaymentMethodSetting copyWith({
    String? code,
    bool? isOnline,
    String? displayName,
    bool clearDisplayName = false,
  }) {
    return AppPaymentMethodSetting(
      code: code ?? this.code,
      isOnline: isOnline ?? this.isOnline,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    );
  }

  String get label {
    final String explicit = (displayName ?? '').trim();
    if (explicit.isNotEmpty) {
      return explicit;
    }
    return defaultPaymentMethodLabel(code);
  }
}

class AppConfig {
  const AppConfig({
    required this.businessName,
    required this.currencySymbol,
    required this.allowNegativeStock,
    required this.themePreference,
    required this.currencyConfig,
  });

  static const String defaultBusinessName = 'Mi Negocio';
  static const String defaultCurrencySymbol = '₱';

  static const AppConfig defaults = AppConfig(
    businessName: defaultBusinessName,
    currencySymbol: defaultCurrencySymbol,
    allowNegativeStock: false,
    themePreference: AppThemePreference.light,
    currencyConfig: AppCurrencyConfig.defaults,
  );

  final String businessName;
  final String currencySymbol;
  final bool allowNegativeStock;
  final AppThemePreference themePreference;
  final AppCurrencyConfig currencyConfig;

  AppConfig copyWith({
    String? businessName,
    String? currencySymbol,
    bool? allowNegativeStock,
    AppThemePreference? themePreference,
    AppCurrencyConfig? currencyConfig,
  }) {
    final AppCurrencyConfig nextCurrencyConfig =
        (currencyConfig ?? this.currencyConfig).normalized();
    return AppConfig(
      businessName: businessName ?? this.businessName,
      currencySymbol:
          currencySymbol ?? nextCurrencyConfig.primaryCurrency.symbol,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
      themePreference: themePreference ?? this.themePreference,
      currencyConfig: nextCurrencyConfig,
    );
  }
}

class ConfiguracionLocalDataSource {
  ConfiguracionLocalDataSource(this._db);

  final AppDatabase _db;

  static const String _kBusinessName = 'business_name';
  static const String _kCurrencySymbol = 'currency_symbol';
  static const String _kCurrencyConfigJson = 'currency_config_json_v1';
  static const String _kAllowNegativeStock = 'allow_negative_stock';
  static const String _kThemePreference = 'theme_preference';
  static const String _kPaymentMethodsConfigJson =
      'payment_methods_config_json_v1';
  static const String _kDashboardWidgetsPrefix =
      'dashboard_widgets_visible_v1::';
  static const List<AppPaymentMethodSetting> _initialInstallPaymentMethods =
      <AppPaymentMethodSetting>[
    AppPaymentMethodSetting(
      code: 'cash',
      isOnline: false,
      displayName: 'Efectivo',
    ),
    AppPaymentMethodSetting(
      code: 'transfer',
      isOnline: true,
      displayName: 'Transferencia',
    ),
  ];

  Future<AppConfig> loadConfig() async {
    final List<AppSetting> rows = await (_db.select(_db.appSettings)
          ..where(
            (AppSettings tbl) =>
                tbl.key.isIn(<String>[
                  _kBusinessName,
                  _kCurrencySymbol,
                  _kCurrencyConfigJson,
                  _kAllowNegativeStock,
                  _kThemePreference,
                ]) &
                tbl.key.isNotNull() &
                tbl.value.isNotNull(),
          ))
        .get();

    final Map<String, String> values = <String, String>{
      for (final AppSetting row in rows) row.key: row.value,
    };

    final AppCurrencyConfig currencyConfig = _parseCurrencyConfig(values);
    final AppConfig config = AppConfig(
      businessName: values[_kBusinessName] ?? AppConfig.defaultBusinessName,
      currencySymbol: currencyConfig.primaryCurrency.symbol,
      allowNegativeStock: values[_kAllowNegativeStock] == '1',
      themePreference:
          AppThemePreference.fromStorage(values[_kThemePreference]),
      currencyConfig: currencyConfig,
    );
    await _seedFirstInstallSettings(
      existingValues: values,
      config: config,
    );
    return config;
  }

  Future<void> saveConfig(AppConfig config) async {
    final AppCurrencyConfig normalizedCurrencies =
        config.currencyConfig.normalized();
    await _db.transaction(() async {
      await _upsert(_kBusinessName, config.businessName.trim());
      await _upsert(
          _kCurrencySymbol, normalizedCurrencies.primaryCurrency.symbol);
      await _upsert(
          _kCurrencyConfigJson, jsonEncode(normalizedCurrencies.toJson()));
      await _upsert(
        _kAllowNegativeStock,
        config.allowNegativeStock ? '1' : '0',
      );
      await _upsert(_kThemePreference, config.themePreference.storageValue);
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

  Future<AppCurrencyConfig> loadCurrencyConfig() async {
    final AppConfig config = await loadConfig();
    return config.currencyConfig;
  }

  Future<List<AppPaymentMethodSetting>> loadPaymentMethodSettings() async {
    final AppSetting? row = await (_db.select(_db.appSettings)
          ..where(
              (AppSettings tbl) => tbl.key.equals(_kPaymentMethodsConfigJson)))
        .getSingleOrNull();
    if (row == null) {
      final List<AppPaymentMethodSetting> seeded =
          _normalizePaymentMethodSettings(
        _initialInstallPaymentMethods,
      );
      await _upsert(
        _kPaymentMethodsConfigJson,
        jsonEncode(
          seeded
              .map((AppPaymentMethodSetting method) => method.toJson())
              .toList(growable: false),
        ),
      );
      return seeded;
    }
    if (row.value.trim().isEmpty) {
      return const <AppPaymentMethodSetting>[];
    }
    try {
      final Object? decoded = jsonDecode(row.value);
      if (decoded is! List) {
        return const <AppPaymentMethodSetting>[];
      }
      final List<AppPaymentMethodSetting> parsed = <AppPaymentMethodSetting>[];
      for (final Object? item in decoded) {
        if (item is Map) {
          parsed.add(
            AppPaymentMethodSetting.fromJson(item.cast<String, Object?>()),
          );
          continue;
        }
        if (item is String) {
          final String code = item.trim().toLowerCase();
          if (code.isEmpty) {
            continue;
          }
          parsed.add(
            AppPaymentMethodSetting(
              code: code,
              isOnline: code == 'transfer' || code == 'wallet',
            ),
          );
        }
      }
      return _normalizePaymentMethodSettings(parsed);
    } catch (_) {
      return const <AppPaymentMethodSetting>[];
    }
  }

  Future<void> savePaymentMethodSettings(
    List<AppPaymentMethodSetting> methods,
  ) async {
    final List<AppPaymentMethodSetting> normalized =
        _normalizePaymentMethodSettings(methods);
    await _upsert(
      _kPaymentMethodsConfigJson,
      jsonEncode(
        normalized
            .map((AppPaymentMethodSetting method) => method.toJson())
            .toList(growable: false),
      ),
    );
  }

  Future<Set<String>> loadOnlinePaymentMethodCodes() async {
    final List<AppPaymentMethodSetting> settings =
        await loadPaymentMethodSettings();
    return settings
        .where((AppPaymentMethodSetting row) => row.isOnline)
        .map((AppPaymentMethodSetting row) => row.code.trim().toLowerCase())
        .where((String code) => code.isNotEmpty)
        .toSet();
  }

  Future<DashboardWidgetLayout> loadDashboardWidgetLayout({
    required String userId,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return DashboardWidgetLayout.defaults;
    }

    final String storageKey = '$_kDashboardWidgetsPrefix$cleanUserId';
    final AppSetting? row = await (_db.select(_db.appSettings)
          ..where((AppSettings tbl) => tbl.key.equals(storageKey)))
        .getSingleOrNull();
    if (row == null) {
      return DashboardWidgetLayout.defaults;
    }
    return _decodeDashboardWidgetLayout(row.value);
  }

  Future<Set<String>> loadDashboardVisibleWidgetKeys({
    required String userId,
  }) async {
    final DashboardWidgetLayout layout = await loadDashboardWidgetLayout(
      userId: userId,
    );
    return layout.visibleKeys;
  }

  Future<void> saveDashboardWidgetLayout({
    required String userId,
    required DashboardWidgetLayout layout,
  }) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      throw Exception('Usuario inválido para guardar widgets.');
    }
    final DashboardWidgetLayout normalized = layout.normalized();
    final Map<String, Object?> payload = <String, Object?>{
      'visible': normalized.visibleKeys.toList(growable: false)..sort(),
      'order': normalized.orderedKeys,
    };
    await _upsert(
      '$_kDashboardWidgetsPrefix$cleanUserId',
      jsonEncode(payload),
    );
  }

  Future<void> saveDashboardVisibleWidgetKeys({
    required String userId,
    required Set<String> visibleWidgetKeys,
  }) async {
    final DashboardWidgetLayout current = await loadDashboardWidgetLayout(
      userId: userId,
    );
    await saveDashboardWidgetLayout(
      userId: userId,
      layout: current.copyWith(visibleKeys: visibleWidgetKeys),
    );
  }

  AppCurrencyConfig _parseCurrencyConfig(Map<String, String> values) {
    final String? rawConfig = values[_kCurrencyConfigJson];
    if (rawConfig != null && rawConfig.trim().isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(rawConfig);
        if (decoded is Map) {
          return AppCurrencyConfig.fromJson(decoded.cast<String, Object?>())
              .normalized();
        }
      } catch (_) {}
    }

    final String? rawLegacySymbol = values[_kCurrencySymbol];
    if (rawLegacySymbol == null || rawLegacySymbol.trim().isEmpty) {
      return AppCurrencyConfig.defaults.normalized();
    }
    final String legacySymbol = _sanitizeCurrencySymbol(
      rawLegacySymbol,
      fallback: AppConfig.defaultCurrencySymbol,
    );
    final String legacyCode = _currencyCodeFromSymbol(legacySymbol);
    return AppCurrencyConfig(
      primaryCurrencyCode: legacyCode,
      currencies: <AppCurrencySetting>[
        AppCurrencySetting(
          code: legacyCode,
          symbol: legacySymbol,
          rateToPrimary: 1,
        ),
      ],
      rateHistory: const <AppExchangeRateHistoryEntry>[],
    ).normalized();
  }

  Future<void> _seedFirstInstallSettings({
    required Map<String, String> existingValues,
    required AppConfig config,
  }) async {
    final bool missingBusiness =
        !_hasStoredValue(existingValues, _kBusinessName);
    final bool missingCurrencySymbol =
        !_hasStoredValue(existingValues, _kCurrencySymbol);
    final bool missingCurrencyConfig =
        !_hasStoredValue(existingValues, _kCurrencyConfigJson);
    final bool missingAllowNegativeStock =
        !_hasStoredValue(existingValues, _kAllowNegativeStock);
    final bool missingThemePreference =
        !_hasStoredValue(existingValues, _kThemePreference);

    final AppSetting? paymentSetting = await (_db.select(_db.appSettings)
          ..where(
            (AppSettings tbl) => tbl.key.equals(_kPaymentMethodsConfigJson),
          )
          ..limit(1))
        .getSingleOrNull();
    final bool missingPaymentMethods = paymentSetting == null;

    if (!missingBusiness &&
        !missingCurrencySymbol &&
        !missingCurrencyConfig &&
        !missingAllowNegativeStock &&
        !missingThemePreference &&
        !missingPaymentMethods) {
      return;
    }

    final AppCurrencyConfig normalizedCurrencies =
        config.currencyConfig.normalized();
    await _db.transaction(() async {
      if (missingBusiness) {
        await _upsert(_kBusinessName, config.businessName.trim());
      }
      if (missingCurrencySymbol) {
        await _upsert(
          _kCurrencySymbol,
          normalizedCurrencies.primaryCurrency.symbol,
        );
      }
      if (missingCurrencyConfig) {
        await _upsert(
          _kCurrencyConfigJson,
          jsonEncode(normalizedCurrencies.toJson()),
        );
      }
      if (missingAllowNegativeStock) {
        await _upsert(
          _kAllowNegativeStock,
          config.allowNegativeStock ? '1' : '0',
        );
      }
      if (missingThemePreference) {
        await _upsert(_kThemePreference, config.themePreference.storageValue);
      }
      if (missingPaymentMethods) {
        await _upsert(
          _kPaymentMethodsConfigJson,
          jsonEncode(
            _initialInstallPaymentMethods
                .map((AppPaymentMethodSetting method) => method.toJson())
                .toList(growable: false),
          ),
        );
      }
    });
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

  List<AppPaymentMethodSetting> _normalizePaymentMethodSettings(
    List<AppPaymentMethodSetting> methods,
  ) {
    final Map<String, AppPaymentMethodSetting> byCode =
        <String, AppPaymentMethodSetting>{};
    for (final AppPaymentMethodSetting raw in methods) {
      final String code = raw.code.trim().toLowerCase();
      if (code.isEmpty || byCode.containsKey(code)) {
        continue;
      }
      byCode[code] = AppPaymentMethodSetting(
        code: code,
        isOnline: raw.isOnline,
        displayName: _normalizePaymentMethodDisplayName(raw.displayName),
      );
    }
    final List<AppPaymentMethodSetting> ordered = byCode.values.toList()
      ..sort((AppPaymentMethodSetting a, AppPaymentMethodSetting b) {
        final int ai = _initialInstallPaymentMethods
            .indexWhere((AppPaymentMethodSetting row) => row.code == a.code);
        final int bi = _initialInstallPaymentMethods
            .indexWhere((AppPaymentMethodSetting row) => row.code == b.code);
        final bool aIsDefault = ai >= 0;
        final bool bIsDefault = bi >= 0;
        if (aIsDefault && bIsDefault) {
          return ai.compareTo(bi);
        }
        if (aIsDefault) {
          return -1;
        }
        if (bIsDefault) {
          return 1;
        }
        return a.code.compareTo(b.code);
      });
    return ordered;
  }

  String? _normalizePaymentMethodDisplayName(String? value) {
    final String clean = (value ?? '').trim();
    if (clean.isEmpty) {
      return null;
    }
    return clean;
  }

  DashboardWidgetLayout _decodeDashboardWidgetLayout(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is List) {
        final Set<String> visible = decoded
            .map((Object? item) => (item as String? ?? '').trim())
            .where((String key) => key.isNotEmpty)
            .toSet();
        return DashboardWidgetLayout(
          visibleKeys: visible,
          orderedKeys: DashboardWidgetCatalog.defaultOrderKeys,
        ).normalized();
      }
      if (decoded is Map) {
        final Map<String, Object?> map = decoded.cast<String, Object?>();
        final Set<String> visible = _readDashboardKeySet(map['visible']);
        final List<String> ordered = _readDashboardKeyList(map['order']);
        return DashboardWidgetLayout(
          visibleKeys: visible,
          orderedKeys: ordered,
        ).normalized();
      }
    } catch (_) {}
    return DashboardWidgetLayout.defaults;
  }

  Set<String> _readDashboardKeySet(Object? raw) {
    if (raw is! List) {
      return DashboardWidgetCatalog.defaultVisibleKeys;
    }
    return raw
        .map((Object? item) => (item as String? ?? '').trim())
        .where((String key) => key.isNotEmpty)
        .toSet();
  }

  List<String> _readDashboardKeyList(Object? raw) {
    if (raw is! List) {
      return DashboardWidgetCatalog.defaultOrderKeys;
    }
    return raw
        .map((Object? item) => (item as String? ?? '').trim())
        .where((String key) => key.isNotEmpty)
        .toList(growable: false);
  }
}

bool _hasStoredValue(Map<String, String> values, String key) {
  final String? value = values[key];
  return value != null && value.trim().isNotEmpty;
}

double? _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }
  return null;
}

String _sanitizeCurrencyCode(String? value) {
  final String cleaned = (value ?? '').trim().toUpperCase();
  if (cleaned.isEmpty) {
    return '';
  }
  if (cleaned.length > 3) {
    return cleaned.substring(0, 3);
  }
  return cleaned;
}

String _sanitizeCurrencySymbol(
  String? value, {
  required String fallback,
}) {
  final String cleaned = (value ?? '').trim();
  if (cleaned.isEmpty) {
    return fallback;
  }
  return cleaned.length <= 3 ? cleaned : cleaned.substring(0, 3);
}

String _currencyCodeFromSymbol(String symbol) {
  switch (symbol.trim()) {
    case '€':
      return 'EUR';
    case '₱':
      return 'CUP';
    case r'$':
    default:
      return 'USD';
  }
}

String _defaultSymbolForCode(String code) {
  switch (_sanitizeCurrencyCode(code)) {
    case 'EUR':
      return '€';
    case 'CUP':
      return '₱';
    case 'MXN':
      return r'$';
    case 'USD':
    default:
      return r'$';
  }
}

String defaultPaymentMethodLabel(String methodCode) {
  switch (methodCode.trim().toLowerCase()) {
    case 'cash':
      return 'Efectivo';
    case 'card':
      return 'Tarjeta';
    case 'transfer':
      return 'Transferencia';
    case 'wallet':
      return 'Billetera';
    case 'consignment':
      return 'Consignacion';
    default:
      final String clean = methodCode.trim();
      return clean.isEmpty ? 'Metodo' : clean;
  }
}

Map<String, String> buildPaymentMethodLabelMap(
  Iterable<AppPaymentMethodSetting> methods,
) {
  final Map<String, String> out = <String, String>{};
  for (final AppPaymentMethodSetting row in methods) {
    final String code = row.code.trim().toLowerCase();
    if (code.isEmpty) {
      continue;
    }
    out[code] = row.label;
  }
  return out;
}
