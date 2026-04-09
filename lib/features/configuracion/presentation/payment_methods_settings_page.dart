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
      final List<AppPaymentMethodSetting> rows =
          await ds.loadPaymentMethodSettings();
      if (!mounted) {
        return;
      }
      setState(() {
        _methods = rows;
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
