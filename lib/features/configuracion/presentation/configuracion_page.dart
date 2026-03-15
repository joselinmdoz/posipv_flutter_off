import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/configuracion_local_datasource.dart';
import 'configuracion_providers.dart';
import 'gestion_datos_page.dart';

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  AppConfig _config = AppConfig.defaults;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadConfig();
    });
  }

  Future<void> _loadConfig() async {
    final PerfTrace trace = PerfTrace('configuracion.load');
    if (mounted) {
      setState(() {
        _config = ref.read(currentAppConfigProvider);
        _loading = false;
      });
      trace.mark('cache aplicada');
    }

    try {
      final AppConfig config =
          await ref.read(configuracionLocalDataSourceProvider).loadConfig();
      if (!mounted) {
        trace.end('unmounted');
        return;
      }
      setState(() => _config = config);
      trace.end('ok');
    } catch (e) {
      if (!mounted) {
        return;
      }
      trace.end('error');
      _show('No se pudo cargar configuración: $e');
    }
  }

  Future<void> _save(AppConfig next, {String? okMessage}) async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(appConfigControllerProvider.notifier).save(next);
      if (!mounted) {
        return;
      }
      setState(() => _config = next);
      if (okMessage != null && okMessage.trim().isNotEmpty) {
        _show(okMessage);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openCurrencyDialog() async {
    final TextEditingController businessCtrl = TextEditingController(
      text: _config.businessName,
    );
    final TextEditingController currencyCtrl = TextEditingController(
      text: _config.currencySymbol,
    );
    final bool? apply = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuración de moneda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: businessCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre comercial',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: currencyCtrl,
                maxLength: 3,
                decoration: const InputDecoration(
                  labelText: 'Símbolo de moneda',
                  hintText: r'$, USD, CUP',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (apply != true || !mounted) {
      return;
    }
    final String business = businessCtrl.text.trim();
    final String currency = currencyCtrl.text.trim();
    if (business.isEmpty || currency.isEmpty) {
      _show('Nombre y símbolo de moneda son obligatorios.');
      return;
    }
    final AppConfig next = _config.copyWith(
      businessName: business,
      currencySymbol: currency,
    );
    await _save(next, okMessage: 'Moneda actualizada.');
  }

  Future<void> _openThemeDialog() async {
    AppThemePreference selected = _config.themePreference;
    final AppThemePreference? value = await showDialog<AppThemePreference>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Personalizar apariencia'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SegmentedButton<AppThemePreference>(
                segments: const <ButtonSegment<AppThemePreference>>[
                  ButtonSegment<AppThemePreference>(
                    value: AppThemePreference.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Claro'),
                  ),
                  ButtonSegment<AppThemePreference>(
                    value: AppThemePreference.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Oscuro'),
                  ),
                ],
                selected: <AppThemePreference>{selected},
                onSelectionChanged: (Set<AppThemePreference> value) {
                  if (value.isEmpty) {
                    return;
                  }
                  setDialogState(() => selected = value.first);
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
    if (value == null || !mounted) {
      return;
    }
    final AppConfig next = _config.copyWith(themePreference: value);
    await _save(next, okMessage: 'Tema actualizado.');
  }

  Future<void> _openTransactionsDialog() async {
    bool allowNegative = _config.allowNegativeStock;
    final bool? apply = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Configuración de transacciones'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
              return SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: allowNegative,
                title: const Text('Permitir stock negativo en venta'),
                subtitle: const Text(
                  'Si está activo, la venta puede dejar inventario por debajo de 0.',
                ),
                onChanged: (bool value) {
                  setDialogState(() => allowNegative = value);
                },
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
    if (apply != true || !mounted) {
      return;
    }
    final AppConfig next = _config.copyWith(allowNegativeStock: allowNegative);
    await _save(next, okMessage: 'Configuración de transacciones guardada.');
  }

  Future<void> _openDataManagement() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const GestionDatosPage(),
      ),
    );
  }

  void _showSoon() {
    _show('Próximamente.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final LicenseStatus license = ref.watch(currentLicenseStatusProvider);

    return AppScaffold(
      title: 'Ajustes',
      currentRoute: '/configuracion',
      showTopTabs: false,
      onRefresh: _loadConfig,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                _section('Localización'),
                _option(
                  icon: Icons.language_rounded,
                  title: 'Preferencia de idioma',
                  subtitle: 'Spanish (Español)',
                  onTap: _showSoon,
                ),
                _option(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Configuración de moneda',
                  subtitle:
                      '${_config.businessName} • ${_config.currencySymbol}',
                  onTap: _saving ? null : _openCurrencyDialog,
                ),
                _option(
                  icon: Icons.date_range_rounded,
                  title: 'Ajustes de fecha',
                  onTap: _showSoon,
                ),
                const SizedBox(height: 14),
                _section('General'),
                _option(
                  icon: Icons.palette_outlined,
                  title: 'Personalizar apariencia',
                  subtitle: _config.themePreference == AppThemePreference.dark
                      ? 'Oscuro'
                      : 'Claro',
                  onTap: _saving ? null : _openThemeDialog,
                ),
                _option(
                  icon: Icons.storage_outlined,
                  title: 'Gestión de datos',
                  subtitle: 'Copias de seguridad y CSV',
                  onTap: _openDataManagement,
                ),
                // _option(
                //   icon: Icons.sync_rounded,
                //   title: 'Sincronización en línea',
                //   onTap: _showSoon,
                // ),
                _option(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Configuración de transacciones',
                  subtitle: _config.allowNegativeStock
                      ? 'Stock negativo permitido'
                      : 'Stock negativo bloqueado',
                  onTap: _saving ? null : _openTransactionsDialog,
                ),
                _option(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendario',
                  onTap: _showSoon,
                ),
                _option(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificación por teléfono',
                  onTap: _showSoon,
                ),
                _option(
                  icon: Icons.fingerprint_rounded,
                  title: 'Contraseña y huella digital',
                  onTap: _showSoon,
                ),
                const SizedBox(height: 14),
                _section('Acerca de'),
                _option(
                  icon: Icons.verified_user_outlined,
                  title: 'Licencia',
                  subtitle: license.statusLabel,
                  onTap: () => context.go('/licencia'),
                ),
                _option(
                  icon: Icons.mail_outline_rounded,
                  title: 'Soporte',
                  onTap: _showSoon,
                ),
              ],
            ),
    );
  }

  Widget _section(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
