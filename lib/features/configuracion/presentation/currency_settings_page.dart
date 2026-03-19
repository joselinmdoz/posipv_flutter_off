import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/configuracion_local_datasource.dart';
import 'configuracion_providers.dart';
import 'widgets/config_section_label.dart';
import 'widgets/currency_editor_dialog.dart';
import 'widgets/currency_rate_editor_panel.dart';
import 'widgets/currency_rate_history_list.dart';
import 'widgets/currency_rate_tile.dart';

class CurrencySettingsPage extends ConsumerStatefulWidget {
  const CurrencySettingsPage({super.key});

  @override
  ConsumerState<CurrencySettingsPage> createState() =>
      _CurrencySettingsPageState();
}

class _CurrencySettingsPageState extends ConsumerState<CurrencySettingsPage> {
  AppConfig _config = AppConfig.defaults;
  AppCurrencyConfig _initialCurrencyConfig = AppCurrencyConfig.defaults;
  AppCurrencyConfig _draftCurrencyConfig = AppCurrencyConfig.defaults;
  final TextEditingController _rateValueCtrl = TextEditingController();
  String? _rateFromCurrencyCode;
  String? _rateToCurrencyCode;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  @override
  void dispose() {
    _rateValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final AppConfig config =
          await ref.read(configuracionLocalDataSourceProvider).loadConfig();
      if (!mounted) {
        return;
      }
      setState(() {
        _config = config;
        _initialCurrencyConfig = config.currencyConfig.normalized();
        _draftCurrencyConfig = config.currencyConfig.normalized();
        _syncRateSelection(resetValue: true);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar la configuracion de monedas: $error');
    }
  }

  Future<void> _addCurrency() async {
    final AppCurrencySetting? created = await showDialog<AppCurrencySetting>(
      context: context,
      builder: (BuildContext context) {
        return CurrencyEditorDialog(
          existingCodes: _draftCurrencyConfig.currencies
              .map((AppCurrencySetting c) => c.code)
              .toSet(),
        );
      },
    );
    if (created == null) {
      return;
    }

    setState(() {
      _draftCurrencyConfig = _draftCurrencyConfig.copyWith(
        currencies: <AppCurrencySetting>[
          ..._draftCurrencyConfig.currencies,
          created,
        ],
      );
      _syncRateSelection(resetValue: true);
    });
  }

  Future<void> _editCurrency(AppCurrencySetting currency) async {
    final AppCurrencySetting? edited = await showDialog<AppCurrencySetting>(
      context: context,
      builder: (BuildContext context) {
        return CurrencyEditorDialog(
          initialCurrency: currency,
          existingCodes: _draftCurrencyConfig.currencies
              .where((AppCurrencySetting c) => c.code != currency.code)
              .map((AppCurrencySetting c) => c.code)
              .toSet(),
        );
      },
    );
    if (edited == null) {
      return;
    }

    final List<AppCurrencySetting> updated =
        _draftCurrencyConfig.currencies.map((AppCurrencySetting current) {
      if (current.code != currency.code) {
        return current;
      }
      if (current.code == _draftCurrencyConfig.primaryCurrencyCode) {
        return edited.copyWith(rateToPrimary: 1);
      }
      return edited;
    }).toList();

    setState(() {
      _draftCurrencyConfig = _draftCurrencyConfig.copyWith(currencies: updated);
      _syncRateSelection(resetValue: true);
    });
  }

  Future<void> _removeCurrency(AppCurrencySetting currency) async {
    if (currency.code == _draftCurrencyConfig.primaryCurrencyCode) {
      _show('No puedes eliminar la moneda principal.');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar moneda'),
          content: Text(
            'Se eliminara ${currency.code} de la lista de monedas activas.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    setState(() {
      _draftCurrencyConfig = _draftCurrencyConfig.copyWith(
        currencies: _draftCurrencyConfig.currencies
            .where((AppCurrencySetting item) => item.code != currency.code)
            .toList(),
      );
      _syncRateSelection(resetValue: true);
    });
  }

  void _setPrimaryCurrency(String newPrimaryCode) {
    final String currentPrimary = _draftCurrencyConfig.primaryCurrencyCode;
    if (newPrimaryCode == currentPrimary) {
      return;
    }

    final Map<String, double> oldRateByCode = <String, double>{
      for (final AppCurrencySetting currency in _draftCurrencyConfig.currencies)
        currency.code: currency.rateToPrimary,
    };
    final double newPrimaryOldRate = oldRateByCode[newPrimaryCode] ?? 1;
    if (!newPrimaryOldRate.isFinite || newPrimaryOldRate <= 0) {
      return;
    }

    final List<AppCurrencySetting> converted =
        _draftCurrencyConfig.currencies.map((AppCurrencySetting currency) {
      final double oldRate = oldRateByCode[currency.code] ?? 1;
      if (currency.code == newPrimaryCode) {
        return currency.copyWith(rateToPrimary: 1);
      }
      return currency.copyWith(rateToPrimary: oldRate / newPrimaryOldRate);
    }).toList();

    setState(() {
      _draftCurrencyConfig = _draftCurrencyConfig.copyWith(
        primaryCurrencyCode: newPrimaryCode,
        currencies: converted,
      );
      _syncRateSelection(resetValue: true);
    });
  }

  List<AppCurrencySetting> _allCurrencies(AppCurrencyConfig config) {
    return config.normalized().currencies;
  }

  bool _hasCurrencyCode(
    List<AppCurrencySetting> currencies,
    String code,
  ) {
    for (final AppCurrencySetting currency in currencies) {
      if (currency.code == code) {
        return true;
      }
    }
    return false;
  }

  ({String from, String to}) _normalizedRatePair({
    required List<AppCurrencySetting> currencies,
    required String fromCode,
    required String toCode,
  }) {
    String from = fromCode;
    String to = toCode;

    if (from == to || !_hasCurrencyCode(currencies, from)) {
      from = currencies.first.code;
    }
    if (to == from || !_hasCurrencyCode(currencies, to)) {
      to = currencies.firstWhere((AppCurrencySetting c) => c.code != from).code;
    }

    // Prefer user-friendly orientation when CUP is present: 1 XXX = N CUP.
    if (from == 'CUP' && to != 'CUP') {
      final String next = to;
      to = from;
      from = next;
    }

    return (from: from, to: to);
  }

  double _rateToPrimaryFor(String code) {
    final AppCurrencyConfig normalized = _draftCurrencyConfig.normalized();
    if (code == normalized.primaryCurrencyCode) {
      return 1;
    }
    final AppCurrencySetting? currency = normalized.currencyByCode(code);
    if (currency == null ||
        !currency.rateToPrimary.isFinite ||
        currency.rateToPrimary <= 0) {
      return 1;
    }
    return currency.rateToPrimary;
  }

  double _pairRate({
    required String fromCode,
    required String toCode,
  }) {
    final double fromRate = _rateToPrimaryFor(fromCode);
    final double toRate = _rateToPrimaryFor(toCode);
    if (fromRate <= 0) {
      return 1;
    }
    return toRate / fromRate;
  }

  void _syncRateSelection({bool resetValue = false}) {
    final List<AppCurrencySetting> all = _allCurrencies(_draftCurrencyConfig);
    if (all.length < 2) {
      _rateFromCurrencyCode = null;
      _rateToCurrencyCode = null;
      _rateValueCtrl.text = '';
      return;
    }

    final ({String from, String to}) pair = _normalizedRatePair(
      currencies: all,
      fromCode: _rateFromCurrencyCode ?? all.first.code,
      toCode: _rateToCurrencyCode ??
          all
              .firstWhere((AppCurrencySetting c) => c.code != all.first.code)
              .code,
    );
    _rateFromCurrencyCode = pair.from;
    _rateToCurrencyCode = pair.to;

    if (resetValue) {
      _rateValueCtrl.text = _pairRate(
        fromCode: pair.from,
        toCode: pair.to,
      ).toStringAsFixed(2);
    }
  }

  void _changeRateFromCurrency(String? code) {
    if (code == null || code == _rateFromCurrencyCode) {
      return;
    }
    final List<AppCurrencySetting> all = _allCurrencies(_draftCurrencyConfig);
    if (all.every((AppCurrencySetting c) => c.code != code)) {
      return;
    }
    setState(() {
      _rateFromCurrencyCode = code;
      _syncRateSelection(resetValue: true);
    });
  }

  void _changeRateToCurrency(String? code) {
    if (code == null || code == _rateToCurrencyCode) {
      return;
    }
    final List<AppCurrencySetting> all = _allCurrencies(_draftCurrencyConfig);
    if (all.every((AppCurrencySetting c) => c.code != code)) {
      return;
    }
    if (code == _rateFromCurrencyCode) {
      return;
    }
    setState(() {
      _rateToCurrencyCode = code;
      _syncRateSelection(resetValue: true);
    });
  }

  void _applyRateValue() {
    final String? fromCode = _rateFromCurrencyCode;
    final String? toCode = _rateToCurrencyCode;
    if (fromCode == null || toCode == null) {
      _show('Primero agrega al menos dos monedas.');
      return;
    }
    if (fromCode == toCode) {
      _show('Selecciona dos monedas distintas.');
      return;
    }

    final double? value =
        double.tryParse(_rateValueCtrl.text.trim().replaceAll(',', '.'));
    if (value == null || !value.isFinite || value <= 0) {
      _show('La tasa debe ser un numero mayor que 0.');
      return;
    }
    final double normalizedValue = (value * 100).round() / 100;

    setState(() {
      final AppCurrencyConfig normalized = _draftCurrencyConfig.normalized();
      final String primary = normalized.primaryCurrencyCode;
      final double fromRate = _rateToPrimaryFor(fromCode);
      _draftCurrencyConfig = _draftCurrencyConfig.copyWith(
        currencies:
            _draftCurrencyConfig.currencies.map((AppCurrencySetting currency) {
          if (toCode == primary) {
            if (currency.code != fromCode) {
              return currency;
            }
            return currency.copyWith(rateToPrimary: 1 / normalizedValue);
          }
          if (currency.code != toCode) {
            return currency;
          }
          return currency.copyWith(rateToPrimary: normalizedValue * fromRate);
        }).toList(),
      );
      _syncRateSelection(resetValue: true);
    });
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final AppCurrencyConfig draft = _draftCurrencyConfig.normalized();
    if (draft.currencies.isEmpty) {
      _show('Debes tener al menos una moneda activa.');
      return;
    }

    setState(() => _saving = true);
    try {
      final bool primaryChanged = _initialCurrencyConfig.primaryCurrencyCode !=
          draft.primaryCurrencyCode;
      final Map<String, double> previousRateByCode = <String, double>{
        for (final AppCurrencySetting currency
            in _initialCurrencyConfig.currencies)
          currency.code: currency.rateToPrimary,
      };
      final DateTime now = DateTime.now().toUtc();
      final List<AppExchangeRateHistoryEntry> newHistory =
          <AppExchangeRateHistoryEntry>[];

      for (final AppCurrencySetting currency in draft.currencies) {
        if (currency.code == draft.primaryCurrencyCode) {
          continue;
        }
        final bool shouldRegister;
        if (primaryChanged) {
          shouldRegister = true;
        } else {
          final double? previous = previousRateByCode[currency.code];
          shouldRegister = previous == null ||
              (previous - currency.rateToPrimary).abs() > 0.0000001;
        }

        if (shouldRegister) {
          newHistory.add(
            AppExchangeRateHistoryEntry(
              currencyCode: currency.code,
              baseCurrencyCode: draft.primaryCurrencyCode,
              rateToBase: currency.rateToPrimary,
              changedAt: now,
            ),
          );
        }
      }

      final AppCurrencyConfig nextCurrencyConfig = draft.copyWith(
        rateHistory: <AppExchangeRateHistoryEntry>[
          ...newHistory,
          ..._initialCurrencyConfig.rateHistory,
        ],
      );

      final AppConfig nextConfig = _config.copyWith(
        currencyConfig: nextCurrencyConfig,
        currencySymbol: nextCurrencyConfig.primaryCurrency.symbol,
      );

      await ref.read(appConfigControllerProvider.notifier).save(nextConfig);
      if (!mounted) {
        return;
      }

      setState(() {
        _config = nextConfig;
        _initialCurrencyConfig = nextCurrencyConfig;
        _draftCurrencyConfig = nextCurrencyConfig;
        _syncRateSelection(resetValue: true);
      });
      _show('Configuracion de monedas guardada.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar la configuracion de monedas: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final AppCurrencyConfig currencies = _draftCurrencyConfig.normalized();
    final String primaryCode = currencies.primaryCurrencyCode;
    final List<AppCurrencySetting> allCurrencies = _allCurrencies(currencies);

    return AppScaffold(
      title: 'Monedas y tasas',
      currentRoute: '/configuracion',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                const ConfigSectionLabel(text: 'Moneda principal y activas'),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Define la moneda principal y las secundarias con las que trabajara la app.',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final AppCurrencySetting currency in currencies.currencies)
                  CurrencyRateTile(
                    currency: currency,
                    primaryCode: primaryCode,
                    onEdit: () => _editCurrency(currency),
                    onSetPrimary: () => _setPrimaryCurrency(currency.code),
                    onRemove: () => _removeCurrency(currency),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _addCurrency,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar moneda'),
                ),
                const SizedBox(height: 16),
                const ConfigSectionLabel(text: 'Tasas de cambio'),
                CurrencyRateEditorPanel(
                  enabled: !_saving,
                  primaryCode: primaryCode,
                  currencies: allCurrencies,
                  fromCurrencyCode: _rateFromCurrencyCode,
                  toCurrencyCode: _rateToCurrencyCode,
                  rateController: _rateValueCtrl,
                  onFromCurrencyChanged: _changeRateFromCurrency,
                  onToCurrencyChanged: _changeRateToCurrency,
                  onApplyRate: _applyRateValue,
                ),
                const SizedBox(height: 16),
                const ConfigSectionLabel(text: 'Historial de tasas'),
                CurrencyRateHistoryList(history: currencies.rateHistory),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
    );
  }
}
