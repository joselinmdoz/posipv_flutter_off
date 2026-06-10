import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_employee_form_page.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_employee_list_card.dart';

class TpvEmployeesPage extends ConsumerStatefulWidget {
  const TpvEmployeesPage({
    super.key,
    this.openCreateOnLoad = false,
  });

  final bool openCreateOnLoad;

  @override
  ConsumerState<TpvEmployeesPage> createState() => _TpvEmployeesPageState();
}

class _TpvEmployeesPageState extends ConsumerState<TpvEmployeesPage> {
  List<TpvEmployee> _employees = <TpvEmployee>[];
  bool _loading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.openCreateOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _openForm();
      });
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final List<TpvEmployee> rows = await ref
          .read(tpvLocalDataSourceProvider)
          .listEmployees(includeInactive: true);
      if (!mounted) {
        return;
      }
      setState(() {
        _employees = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _show('No se pudieron cargar empleados: $e');
    }
  }

  Future<void> _openForm({TpvEmployee? employee}) async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => TpvEmployeeFormPage(employee: employee),
        fullscreenDialog: true,
      ),
    );
    if (result != 'saved') {
      return;
    }
    await _load();
  }

  Future<void> _toggleEmployee(TpvEmployee employee) async {
    try {
      await ref.read(tpvLocalDataSourceProvider).updateEmployee(
            employeeId: employee.id,
            name: employee.name,
            code: employee.code,
            sex: employee.sex,
            identityNumber: employee.identityNumber,
            address: employee.address,
            imagePath: employee.imagePath,
            associatedUserId: employee.associatedUserId,
            isActive: !employee.isActive,
          );
      await _load();
    } catch (e) {
      _show('No se pudo actualizar empleado: $e');
    }
  }

  Future<void> _deleteEmployee(TpvEmployee employee) async {
    final session = ref.read(currentSessionProvider);
    if (session == null) {
      _show('Debes iniciar sesión.');
      return;
    }
    if (employee.isActive) {
      _show('Primero desactiva el empleado.');
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar empleado'),
          content: Text(
            'Se eliminará definitivamente a "${employee.name}".\n\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB91C1C),
              ),
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

    try {
      await ref.read(tpvLocalDataSourceProvider).permanentlyDeleteEmployee(
            employeeId: employee.id,
            userId: session.userId,
          );
      await _load();
      _show('Empleado eliminado definitivamente.');
    } catch (e) {
      _show('No se pudo eliminar el empleado: $e');
    }
  }

  void _show(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _goBack() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/home');
  }

  List<TpvEmployee> _getFilteredEmployees() {
    final String query = _searchCtrl.text.trim().toLowerCase();
    return _employees.where((TpvEmployee emp) {
      if (_selectedFilter == 'active' && !emp.isActive) return false;
      if (_selectedFilter == 'inactive' && emp.isActive) return false;
      if (query.isEmpty) return true;
      return emp.name.toLowerCase().contains(query) ||
          (emp.code.toLowerCase().contains(query)) ||
          ((emp.associatedUsername ?? '').toLowerCase().contains(query)) ||
          ((emp.identityNumber ?? '').toLowerCase().contains(query));
    }).toList();
  }

  Widget _buildFilterTab({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    final bool selected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF1152D4) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF1152D4)
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(currentLicenseStatusProvider);
    final ThemeData theme = Theme.of(context);
    final List<TpvEmployee> filteredEmployees = _getFilteredEmployees();
    return AppScaffold(
      title: 'Gestión de Empleados',
      currentRoute: '/tpv-empleados',
      onRefresh: _load,
      useDefaultActions: false,
      showDrawer: false,
      appBarLeading: IconButton(
        onPressed: _goBack,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      appBarActions: const <Widget>[],
      floatingActionButton: license.canWrite
          ? AppAddActionButton(
              currentRoute: '/tpv-empleados',
              onPressed: () => _openForm(),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Row(
                      children: <Widget>[
                        _buildFilterTab(
                            label: 'Todos', value: 'all', theme: theme),
                        const SizedBox(width: 24),
                        _buildFilterTab(
                            label: 'Activos', value: 'active', theme: theme),
                        const SizedBox(width: 24),
                        _buildFilterTab(
                            label: 'Inactivos',
                            value: 'inactive',
                            theme: theme),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.18),
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Buscar empleado...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide:
                              const BorderSide(color: Color(0xFF1152D4)),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.14),
                              ),
                            ),
                            child: Text(
                              'No hay empleados para mostrar con los filtros actuales.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          key: const PageStorageKey<String>(
                              'tpv-employees-list'),
                          cacheExtent: 360,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (_, int index) =>
                              _employeeCard(filteredEmployees[index], theme),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _employeeCard(TpvEmployee employee, ThemeData theme) {
    return TpvEmployeeListCard(
      employee: employee,
      onTap: () => _openForm(employee: employee),
      onActionSelected: (TpvEmployeeCardAction action) {
        switch (action) {
          case TpvEmployeeCardAction.edit:
            _openForm(employee: employee);
            break;
          case TpvEmployeeCardAction.toggleActive:
            _toggleEmployee(employee);
            break;
          case TpvEmployeeCardAction.delete:
            if (employee.isActive) {
              _show('Primero desactiva el empleado.');
              return;
            }
            _deleteEmployee(employee);
            break;
        }
      },
    );
  }
}
