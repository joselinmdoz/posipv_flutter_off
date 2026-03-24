import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/licensing/license_providers.dart';
import '../../../shared/widgets/app_add_action_button.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../data/tpv_local_datasource.dart';
import 'tpv_employee_form_page.dart';
import 'tpv_providers.dart';
import 'widgets/tpv_employee_avatar.dart';

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

  String _sexLabel(String sex) {
    switch (sex.trim().toUpperCase()) {
      case 'F':
        return 'Femenino';
      case 'M':
        return 'Masculino';
      case 'X':
        return 'Otro';
      default:
        return sex;
    }
  }

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
      appBarActions: <Widget>[
        IconButton(
          tooltip: 'Buscar',
          onPressed: () {},
          icon: const Icon(Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Filtrar',
          onPressed: () {},
          icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1152D4)),
        ),
      ],
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
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar empleado...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(
                          child: Text('No hay empleados.',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant)))
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
    final bool isActive = employee.isActive;
    final String genderLabel = employee.sex != null && employee.sex!.isNotEmpty
        ? 'Género: ${_sexLabel(employee.sex!)}'
        : '';
    final String ciLabel = (employee.identityNumber ?? '').isNotEmpty
        ? 'CI: ${employee.identityNumber}'
        : '';
    final String infoText = [
      if (genderLabel.isNotEmpty) genderLabel,
      if (ciLabel.isNotEmpty) ciLabel
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            child: TpvEmployeeAvatar(
              imagePath: employee.imagePath,
              radius: 32,
              backgroundColor: isActive
                  ? const Color(0xFF1152D4).withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              iconColor: isActive ? const Color(0xFF1152D4) : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Expanded(
                        child: Text(employee.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFDCFCE7)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text(isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? const Color(0xFF15803D)
                                  : theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                ),
                if (infoText.isNotEmpty)
                  Text(infoText,
                      style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant)),
                if ((employee.associatedUsername ?? '').isNotEmpty)
                  Text('@${employee.associatedUsername}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1152D4))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: <Widget>[
              IconButton(
                  tooltip: 'Editar',
                  onPressed: () => _openForm(employee: employee),
                  icon: Icon(Icons.edit_outlined,
                      color: theme.colorScheme.onSurfaceVariant, size: 20)),
              IconButton(
                  tooltip: isActive ? 'Desactivar' : 'Activar',
                  onPressed: () => _toggleEmployee(employee),
                  icon: Icon(
                      isActive
                          ? Icons.block_rounded
                          : Icons.check_circle_outline,
                      color: isActive
                          ? theme.colorScheme.onSurfaceVariant
                          : const Color(0xFF1152D4),
                      size: 20)),
            ],
          ),
        ],
      ),
    );
  }
}
