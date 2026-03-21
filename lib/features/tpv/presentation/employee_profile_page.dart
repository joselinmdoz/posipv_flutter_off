import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user_session.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_employee_form_page.dart';
import 'tpv_providers.dart';

class EmployeeProfilePage extends ConsumerStatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  ConsumerState<EmployeeProfilePage> createState() =>
      _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends ConsumerState<EmployeeProfilePage> {
  bool _loading = true;
  TpvEmployee? _employee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final UserSession? session = ref.read(currentSessionProvider);
      if (session == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _employee = null;
          _loading = false;
        });
        return;
      }
      final TpvEmployee? employee = await ref
          .read(tpvLocalDataSourceProvider)
          .findActiveEmployeeByAssociatedUser(session.userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _employee = employee;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final TpvEmployee? employee = _employee;
    if (employee == null) {
      return;
    }
    final Object? saved = await Navigator.of(context).push<Object?>(
      MaterialPageRoute<Object?>(
        builder: (_) => TpvEmployeeFormPage(employee: employee),
        fullscreenDialog: true,
      ),
    );
    if (saved != null && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TpvEmployee? employee = _employee;
    final String imagePath = (employee?.imagePath ?? '').trim();
    final bool hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return AppScaffold(
      title: 'Perfil del empleado',
      currentRoute: '/perfil-empleado',
      showDrawer: false,
      showTopTabs: false,
      showBottomNavigationBar: false,
      useDefaultActions: false,
      appBarLeading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: employee == null
                        ? const Text(
                            'No tienes un perfil de empleado asociado a este usuario.',
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Center(
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  backgroundImage: hasImage
                                      ? FileImage(File(imagePath))
                                      : null,
                                  child: !hasImage
                                      ? const Icon(Icons.person, size: 56)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _info('Nombre', employee.name),
                              _info('Codigo', employee.code),
                              _info(
                                'Usuario',
                                (employee.associatedUsername ?? '')
                                        .trim()
                                        .isEmpty
                                    ? '-'
                                    : '@${employee.associatedUsername}',
                              ),
                              _info(
                                'CI',
                                (employee.identityNumber ?? '').trim().isEmpty
                                    ? '-'
                                    : employee.identityNumber!,
                              ),
                              _info(
                                'Direccion',
                                (employee.address ?? '').trim().isEmpty
                                    ? '-'
                                    : employee.address!,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _editProfile,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar perfil'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
