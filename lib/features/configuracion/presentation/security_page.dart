import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import 'widgets/security_actions_panel.dart';
import 'widgets/security_password_dialog.dart';
import 'widgets/security_status_card.dart';

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});

  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  bool _loading = true;
  bool _saving = false;
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadStatus();
    });
  }

  Future<void> _loadStatus() async {
    try {
      final bool enabled =
          await ref.read(localAuthServiceProvider).isAppLockEnabled();
      if (!mounted) {
        return;
      }
      setState(() {
        _isEnabled = enabled;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudo leer la configuracion de seguridad: $error');
    }
  }

  Future<void> _setPassword({required bool changing}) async {
    if (_saving) {
      return;
    }
    final String? password = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SecurityPasswordDialog(
          title: changing ? 'Cambiar contrasena' : 'Activar contrasena',
          confirmLabel: changing ? 'Actualizar' : 'Activar',
        );
      },
    );
    if (password == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(localAuthServiceProvider).setAppLockPassword(password);
      ref.invalidate(appLockEnabledProvider);
      if (!mounted) {
        return;
      }
      setState(() => _isEnabled = true);
      _show(
        changing
            ? 'Contrasena de inicio actualizada.'
            : 'Contrasena de inicio activada.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo guardar la contrasena: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _disablePassword() async {
    if (_saving) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Desactivar contrasena'),
          content: const Text(
            'La app abrira directo sin pedir contrasena. Deseas continuar?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desactivar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(localAuthServiceProvider).clearAppLockPassword();
      ref.invalidate(appLockEnabledProvider);
      if (!mounted) {
        return;
      }
      setState(() => _isEnabled = false);
      _show('Contrasena de inicio desactivada.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _show('No se pudo desactivar la contrasena: $error');
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
    return AppScaffold(
      title: 'Seguridad',
      currentRoute: '/configuracion',
      showTopTabs: false,
      showDrawer: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: <Widget>[
                SecurityStatusCard(
                  isEnabled: _isEnabled,
                  isBusy: _saving,
                ),
                const SizedBox(height: 18),
                SecurityActionsPanel(
                  isEnabled: _isEnabled,
                  isBusy: _saving,
                  onEnable: () => _setPassword(changing: false),
                  onChange: () => _setPassword(changing: true),
                  onDisable: _disablePassword,
                ),
              ],
            ),
    );
  }
}
