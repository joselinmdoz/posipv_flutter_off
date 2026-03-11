import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../data/configuracion_local_datasource.dart';
import 'configuracion_providers.dart';

class ConfiguracionPage extends ConsumerStatefulWidget {
  const ConfiguracionPage({super.key});

  @override
  ConsumerState<ConfiguracionPage> createState() => _ConfiguracionPageState();
}

class _ConfiguracionPageState extends ConsumerState<ConfiguracionPage> {
  final TextEditingController _businessCtrl = TextEditingController();
  final TextEditingController _currencyCtrl = TextEditingController();

  bool _allowNegativeStock = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _businessCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);

    try {
      final AppConfig config =
          await ref.read(configuracionLocalDataSourceProvider).loadConfig();
      if (!mounted) {
        return;
      }

      setState(() {
        _businessCtrl.text = config.businessName;
        _currencyCtrl.text = config.currencySymbol;
        _allowNegativeStock = config.allowNegativeStock;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _loading = false);
      _show('No se pudo cargar configuracion: $e');
    }
  }

  Future<void> _saveConfig() async {
    final String business = _businessCtrl.text.trim();
    final String currency = _currencyCtrl.text.trim();

    if (business.isEmpty) {
      _show('El nombre del negocio es requerido.');
      return;
    }
    if (currency.isEmpty) {
      _show('El simbolo de moneda es requerido.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(configuracionLocalDataSourceProvider).saveConfig(
            AppConfig(
              businessName: business,
              currencySymbol: currency,
              allowNegativeStock: _allowNegativeStock,
            ),
          );
      if (!mounted) {
        return;
      }
      _show('Configuracion guardada.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar la configuracion: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Configuracion',
      currentRoute: '/configuracion',
      onRefresh: _loadConfig,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConfig,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Negocio',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _businessCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nombre comercial',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _currencyCtrl,
                            maxLength: 3,
                            decoration: const InputDecoration(
                              labelText: 'Simbolo de moneda',
                              hintText: r'$, USD, CUP',
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title:
                                const Text('Permitir stock negativo en venta'),
                            subtitle: const Text(
                              'Si esta activo, la venta puede dejar inventario por debajo de 0.',
                            ),
                            value: _allowNegativeStock,
                            onChanged: (bool value) {
                              setState(() => _allowNegativeStock = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _saveConfig,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                _saving
                                    ? 'Guardando...'
                                    : 'Guardar configuracion',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
