import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/app_permissions.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/configuracion_local_datasource.dart';
import 'configuracion_providers.dart';

class PaymentMethodsSettingsPage extends ConsumerStatefulWidget {
  const PaymentMethodsSettingsPage({super.key});

  @override
  ConsumerState<PaymentMethodsSettingsPage> createState() =>
      _PaymentMethodsSettingsPageState();
}

class _PaymentMethodsSettingsPageState
    extends ConsumerState<PaymentMethodsSettingsPage> {
  List<AppPaymentMethodSetting> _methods = <AppPaymentMethodSetting>[];
  AppCurrencyConfig _currencyConfig = AppCurrencyConfig.defaults;
  WorkOrderPaymentDisplayConfig _workOrderPaymentConfig =
      WorkOrderPaymentDisplayConfig.defaults;
  bool _loading = true;
  bool _saving = false;

  bool get _canManage {
    final session = ref.read(currentSessionProvider);
    return session?.hasPermission(AppPermissionKeys.settingsData) ?? false;
  }

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

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ConfiguracionLocalDataSource ds =
          ref.read(configuracionLocalDataSourceProvider);
      final List<dynamic> results =
          await Future.wait<dynamic>(<Future<dynamic>>[
        ds.loadPaymentMethodSettings(),
        ds.loadCurrencyConfig(),
        ds.loadWorkOrderPaymentDisplayConfig(),
      ]);
      final List<AppPaymentMethodSetting> rows =
          results[0] as List<AppPaymentMethodSetting>;
      final AppCurrencyConfig currencyConfig = results[1] as AppCurrencyConfig;
      final WorkOrderPaymentDisplayConfig paymentConfig =
          results[2] as WorkOrderPaymentDisplayConfig;
      if (!mounted) {
        return;
      }
      setState(() {
        _methods = rows;
        _currencyConfig = currencyConfig;
        _workOrderPaymentConfig = paymentConfig;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo cargar metodos de pago: $e');
    }
  }

  Future<void> _saveMethods(
    List<AppPaymentMethodSetting> methods, {
    String? okMessage,
  }) async {
    if (!_canManage || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ConfiguracionLocalDataSource ds =
          ref.read(configuracionLocalDataSourceProvider);
      await ds.savePaymentMethodSettings(methods);
      if (!mounted) {
        return;
      }
      setState(() => _methods = methods);
      if (okMessage != null && okMessage.trim().isNotEmpty) {
        _show(okMessage);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar metodos de pago: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveWorkOrderPaymentConfig(
    WorkOrderPaymentDisplayConfig config,
  ) async {
    if (!_canManage || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      final ConfiguracionLocalDataSource ds =
          ref.read(configuracionLocalDataSourceProvider);
      await ds.saveWorkOrderPaymentDisplayConfig(config);
      if (!mounted) {
        return;
      }
      setState(() => _workOrderPaymentConfig = config.normalized());
      _show('Reglas de cobro para pedidos actualizadas.');
    } catch (e) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar la configuración de pedidos: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openEditor({
    required AppPaymentMethodSetting? initial,
    required int? index,
  }) async {
    if (!_canManage) {
      _show('No tienes permisos para gestionar metodos de pago.');
      return;
    }
    final AppPaymentMethodSetting? edited =
        await Navigator.of(context).push<AppPaymentMethodSetting>(
      MaterialPageRoute<AppPaymentMethodSetting>(
        fullscreenDialog: true,
        builder: (_) => _PaymentMethodFormPage(initial: initial),
      ),
    );
    if (edited == null || !mounted) {
      return;
    }

    final String editedCode = edited.code.trim().toLowerCase();
    final Iterable<AppPaymentMethodSetting> others = _methods
        .asMap()
        .entries
        .where((MapEntry<int, AppPaymentMethodSetting> row) {
      if (index != null && row.key == index) {
        return false;
      }
      return true;
    }).map((MapEntry<int, AppPaymentMethodSetting> row) => row.value);
    final bool duplicated = others.any(
      (AppPaymentMethodSetting row) =>
          row.code.trim().toLowerCase() == editedCode,
    );
    if (duplicated) {
      _show('Ya existe un metodo con ese codigo.');
      return;
    }

    final List<AppPaymentMethodSetting> next =
        List<AppPaymentMethodSetting>.from(
      _methods,
    );
    if (index == null) {
      next.add(edited);
      await _saveMethods(next, okMessage: 'Metodo de pago agregado.');
      return;
    }
    next[index] = edited;
    await _saveMethods(next, okMessage: 'Metodo de pago actualizado.');
  }

  Future<void> _askDelete(int index) async {
    if (!_canManage) {
      return;
    }
    final AppPaymentMethodSetting method = _methods[index];
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar metodo de pago'),
          content: Text(
            'Se eliminará "${method.label}". Esta acción no borra pagos históricos.',
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
    final List<AppPaymentMethodSetting> next =
        List<AppPaymentMethodSetting>.from(
      _methods,
    )..removeAt(index);
    await _saveMethods(next, okMessage: 'Metodo de pago eliminado.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return AppScaffold(
      title: 'Metodos de pago',
      currentRoute: '/configuracion-metodos-pago',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      appBarLeading: IconButton(
        tooltip: 'Atras',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      onRefresh: _load,
      floatingActionButton: _canManage
          ? FloatingActionButton(
              heroTag: 'fab-payment-method-add',
              onPressed: _saving
                  ? null
                  : () => _openEditor(initial: null, index: null),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: <Widget>[
                  if (_saving) const LinearProgressIndicator(minHeight: 3),
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFBFDBFE),
                      ),
                    ),
                    child: const Text(
                      'Administra los metodos de pago disponibles, su codigo y si solicitan ID de transaccion.',
                    ),
                  ),
                  _WorkOrderPaymentConfigCard(
                    config: _workOrderPaymentConfig,
                    currencyConfig: _currencyConfig,
                    enabled: _canManage && !_saving,
                    onChanged: (WorkOrderPaymentDisplayConfig value) {
                      _saveWorkOrderPaymentConfig(value);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (_methods.isEmpty)
                    _EmptyPaymentMethods(
                      canManage: _canManage,
                      onAdd: () => _openEditor(initial: null, index: null),
                    )
                  else
                    ..._methods.asMap().entries.map(
                          (MapEntry<int, AppPaymentMethodSetting> entry) =>
                              _PaymentMethodCard(
                            method: entry.value,
                            onTap: _canManage
                                ? () => _openEditor(
                                      initial: entry.value,
                                      index: entry.key,
                                    )
                                : null,
                            onDelete:
                                _canManage ? () => _askDelete(entry.key) : null,
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}

class _WorkOrderPaymentConfigCard extends StatefulWidget {
  const _WorkOrderPaymentConfigCard({
    required this.config,
    required this.currencyConfig,
    required this.enabled,
    required this.onChanged,
  });

  final WorkOrderPaymentDisplayConfig config;
  final AppCurrencyConfig currencyConfig;
  final bool enabled;
  final ValueChanged<WorkOrderPaymentDisplayConfig> onChanged;

  @override
  State<_WorkOrderPaymentConfigCard> createState() =>
      _WorkOrderPaymentConfigCardState();
}

class _WorkOrderPaymentConfigCardState
    extends State<_WorkOrderPaymentConfigCard> {
  late final TextEditingController _fixedCtrl;
  late final TextEditingController _transferCtrl;
  late String _localCurrencyCode;
  late String _foreignCurrencyCode;

  @override
  void initState() {
    super.initState();
    _fixedCtrl = TextEditingController();
    _transferCtrl = TextEditingController();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _WorkOrderPaymentConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    _fixedCtrl.text = widget.config.localCashFixedSurcharge.toStringAsFixed(2);
    _transferCtrl.text =
        widget.config.localTransferPercentSurcharge.toStringAsFixed(2);
    _localCurrencyCode = widget.config.localCurrencyCode;
    _foreignCurrencyCode = widget.config.foreignCurrencyCode;
  }

  @override
  void dispose() {
    _fixedCtrl.dispose();
    _transferCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_localCurrencyCode.trim().toUpperCase() ==
        _foreignCurrencyCode.trim().toUpperCase()) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'La moneda local y la moneda extranjera deben ser distintas.',
            ),
          ),
        );
      return;
    }
    final double fixed =
        double.tryParse(_fixedCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    final double percent =
        double.tryParse(_transferCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    widget.onChanged(
      WorkOrderPaymentDisplayConfig(
        localCurrencyCode: _localCurrencyCode,
        foreignCurrencyCode: _foreignCurrencyCode,
        localCashFixedSurcharge: fixed,
        localTransferPercentSurcharge: percent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<AppCurrencySetting> currencies =
        widget.currencyConfig.currencies.isEmpty
            ? AppCurrencyConfig.defaults.currencies
            : widget.currencyConfig.currencies;
    final List<String> availableCodes = currencies
        .map((AppCurrencySetting row) => row.code.trim().toUpperCase())
        .toSet()
        .toList(growable: false);
    final String fallbackCode =
        availableCodes.isNotEmpty ? availableCodes.first : 'CUP';
    final String localCurrencyCode = _resolveCurrencyCode(
      preferred: _localCurrencyCode,
      availableCodes: availableCodes,
      fallbackCode: fallbackCode,
    );
    final String foreignCurrencyCode = _resolveCurrencyCode(
      preferred: _foreignCurrencyCode,
      availableCodes: availableCodes,
      fallbackCode:
          availableCodes.length > 1 ? availableCodes[1] : fallbackCode,
    );
    if (localCurrencyCode != _localCurrencyCode ||
        foreignCurrencyCode != _foreignCurrencyCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _localCurrencyCode = localCurrencyCode;
          _foreignCurrencyCode = foreignCurrencyCode;
        });
      });
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Reglas de cobro para pedidos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Define cómo se muestran las variantes de cobro del pedido cuando el cliente paga en USD, CUP efectivo o CUP transferencia.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('local-$localCurrencyCode'),
            initialValue: localCurrencyCode,
            decoration: const InputDecoration(
              labelText: 'Moneda local',
            ),
            items: currencies
                .map(
                  (AppCurrencySetting row) => DropdownMenuItem<String>(
                    value: row.code,
                    child: Text('${row.code} (${row.symbol})'),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.enabled
                ? (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _localCurrencyCode = value);
                  }
                : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('foreign-$foreignCurrencyCode'),
            initialValue: foreignCurrencyCode,
            decoration: const InputDecoration(
              labelText: 'Moneda extranjera',
            ),
            items: currencies
                .map(
                  (AppCurrencySetting row) => DropdownMenuItem<String>(
                    value: row.code,
                    child: Text('${row.code} (${row.symbol})'),
                  ),
                )
                .toList(growable: false),
            onChanged: widget.enabled
                ? (String? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _foreignCurrencyCode = value);
                  }
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fixedCtrl,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Recargo fijo en efectivo local',
              helperText: 'Ejemplo: 5.00 CUP al convertir desde USD.',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _transferCtrl,
            enabled: widget.enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Recargo % para transferencia local',
              helperText: 'Ejemplo: 10.00 aplica un 10% sobre el total local.',
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.enabled ? _submit : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar reglas'),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveCurrencyCode({
    required String preferred,
    required List<String> availableCodes,
    required String fallbackCode,
  }) {
    final String normalized = preferred.trim().toUpperCase();
    if (availableCodes.contains(normalized)) {
      return normalized;
    }
    return fallbackCode;
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    this.onTap,
    this.onDelete,
  });

  final AppPaymentMethodSetting method;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1152D4).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF1152D4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      method.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Codigo: ${method.code}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: method.isOnline
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        method.isOnline
                            ? 'Solicita ID de transaccion'
                            : 'No solicita ID de transaccion',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: method.isOnline
                              ? const Color(0xFF166534)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPaymentMethods extends StatelessWidget {
  const _EmptyPaymentMethods({
    required this.canManage,
    required this.onAdd,
  });

  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.payments_outlined,
            size: 34,
            color: Color(0xFF64748B),
          ),
          const SizedBox(height: 10),
          const Text(
            'No hay metodos de pago configurados.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          if (canManage) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar metodo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodFormPage extends StatefulWidget {
  const _PaymentMethodFormPage({required this.initial});

  final AppPaymentMethodSetting? initial;

  @override
  State<_PaymentMethodFormPage> createState() => _PaymentMethodFormPageState();
}

class _PaymentMethodFormPageState extends State<_PaymentMethodFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late bool _isOnline;
  bool _submitting = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final AppPaymentMethodSetting? initial = widget.initial;
    _nameCtrl = TextEditingController(
      text: initial?.displayName ?? initial?.label ?? '',
    );
    _codeCtrl = TextEditingController(text: initial?.code ?? '');
    _isOnline = initial?.isOnline ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    final FormState? state = _formKey.currentState;
    if (state == null || !state.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final String code = _codeCtrl.text.trim().toLowerCase();
    final String name = _nameCtrl.text.trim();
    final AppPaymentMethodSetting result = AppPaymentMethodSetting(
      code: code,
      displayName: name,
      isOnline: _isOnline,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Editar metodo de pago' : 'Nuevo metodo de pago'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: <Widget>[
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nombre visible',
                hintText: 'Ej: Transferencia',
              ),
              validator: (String? value) {
                final String clean = (value ?? '').trim();
                if (clean.isEmpty) {
                  return 'Debes escribir el nombre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Codigo',
                hintText: 'Ej: transfer',
                helperText:
                    'Solo letras, numeros, guion o guion bajo. Se guarda en minusculas.',
              ),
              validator: (String? value) {
                final String clean = (value ?? '').trim().toLowerCase();
                if (clean.isEmpty) {
                  return 'Debes escribir el codigo.';
                }
                final RegExp validPattern = RegExp(r'^[a-z0-9_-]+$');
                if (!validPattern.hasMatch(clean)) {
                  return 'Codigo invalido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _isOnline,
              contentPadding: EdgeInsets.zero,
              title: const Text('Solicita ID de transaccion'),
              subtitle: const Text(
                'Activalo para pagos online o transferencias con referencia.',
              ),
              onChanged: (bool value) {
                setState(() => _isOnline = value);
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear metodo'),
            ),
          ],
        ),
      ),
    );
  }
}
