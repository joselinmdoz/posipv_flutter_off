import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/licensing/license_models.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../core/utils/perf_trace.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/configuracion_local_datasource.dart';
import 'configuracion_providers.dart';
import 'gestion_datos_page.dart';
import 'widgets/business_name_dialog.dart';
import 'widgets/config_option_tile.dart';
import 'widgets/config_section_label.dart';

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

  Future<void> _openBusinessDialog() async {
    final String? businessName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return BusinessNameDialog(
          initialName: _config.businessName,
        );
      },
    );
    if (businessName == null || !mounted) {
      return;
    }

    final AppConfig next = _config.copyWith(
      businessName: businessName.trim(),
    );
    await _save(next, okMessage: 'Informacion del negocio actualizada.');
  }

  Future<void> _openCurrencySettings() async {
    await context.push('/configuracion-monedas');
    if (!mounted) {
      return;
    }
    await _loadConfig();
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
    final AsyncValue<bool> appLockEnabledAsync =
        ref.watch(appLockEnabledProvider);
    final String securitySubtitle = appLockEnabledAsync.maybeWhen(
      data: (bool value) => value ? 'Contrasena activada' : 'Sin contrasena',
      orElse: () => 'Cargando estado...',
    );
    final AppCurrencyConfig currencyConfig =
        _config.currencyConfig.normalized();
    final int secondaryCount = currencyConfig.currencies.length > 1
        ? currencyConfig.currencies.length - 1
        : 0;
    final String currencySubtitle =
        '${currencyConfig.primaryCurrencyCode} principal • $secondaryCount secundarias';

    return AppScaffold(
      title: 'Ajustes',
      currentRoute: '/configuracion',
      showTopTabs: false,
      showBottomNavigationBar: true,
      onRefresh: _loadConfig,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                if (_saving) const LinearProgressIndicator(minHeight: 3),
                const ConfigSectionLabel(text: 'Negocio'),
                ConfigOptionTile(
                  icon: Icons.storefront_outlined,
                  title: 'Informacion del negocio',
                  subtitle: _config.businessName,
                  onTap: _saving ? null : _openBusinessDialog,
                ),
                const SizedBox(height: 14),
                const ConfigSectionLabel(text: 'Localizacion'),
                ConfigOptionTile(
                  icon: Icons.language_rounded,
                  title: 'Preferencia de idioma',
                  subtitle: 'Spanish (Español)',
                  onTap: _showSoon,
                ),
                ConfigOptionTile(
                  icon: Icons.currency_exchange_rounded,
                  title: 'Configuracion de moneda',
                  subtitle: currencySubtitle,
                  onTap: _saving ? null : _openCurrencySettings,
                ),
                ConfigOptionTile(
                  icon: Icons.date_range_rounded,
                  title: 'Ajustes de fecha',
                  onTap: _showSoon,
                ),
                const SizedBox(height: 14),
                const ConfigSectionLabel(text: 'General'),
                ConfigOptionTile(
                  icon: Icons.palette_outlined,
                  title: 'Personalizar apariencia',
                  subtitle: _config.themePreference == AppThemePreference.dark
                      ? 'Oscuro'
                      : 'Claro',
                  onTap: _saving ? null : _openThemeDialog,
                ),
                ConfigOptionTile(
                  icon: Icons.storage_outlined,
                  title: 'Gestión de datos',
                  subtitle: 'Copias de seguridad y CSV',
                  onTap: _openDataManagement,
                ),
                // ConfigOptionTile(
                //   icon: Icons.sync_rounded,
                //   title: 'Sincronización en línea',
                //   onTap: _showSoon,
                // ),
                ConfigOptionTile(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Configuración de transacciones',
                  subtitle: _config.allowNegativeStock
                      ? 'Stock negativo permitido'
                      : 'Stock negativo bloqueado',
                  onTap: _saving ? null : _openTransactionsDialog,
                ),
                ConfigOptionTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendario',
                  onTap: _showSoon,
                ),
                ConfigOptionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notificación por teléfono',
                  onTap: _showSoon,
                ),
                ConfigOptionTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Seguridad',
                  subtitle: securitySubtitle,
                  onTap: () async {
                    await context.push('/configuracion-seguridad');
                    ref.invalidate(appLockEnabledProvider);
                  },
                ),
                const SizedBox(height: 14),
                const ConfigSectionLabel(text: 'Acerca de'),
                ConfigOptionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Licencia',
                  subtitle: license.statusLabel,
                  onTap: () => context.go('/licencia'),
                ),
                ConfigOptionTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Soporte',
                  onTap: _showSoon,
                ),
              ],
            ),
    );
  }
}
