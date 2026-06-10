import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_searchable_select_field.dart';
import '../../data/pedidos_local_datasource.dart';

class WorkOrderAssignmentDialog extends StatefulWidget {
  const WorkOrderAssignmentDialog({
    super.key,
    required this.options,
    required this.roleOptions,
    this.initialItem,
    this.onManageRoles,
  });

  final List<WorkOrderEmployeeOption> options;
  final List<String> roleOptions;
  final WorkOrderAssignmentItem? initialItem;
  final Future<List<String>> Function()? onManageRoles;

  @override
  State<WorkOrderAssignmentDialog> createState() =>
      _WorkOrderAssignmentDialogState();
}

class _WorkOrderAssignmentDialogState extends State<WorkOrderAssignmentDialog> {
  static const String _none = '__none__';

  String _selectedEmployeeId = _none;
  String _selectedRole = '';
  String _error = '';
  List<String> _roleOptions = <String>[];

  List<String> get _availableRoles {
    final List<String> roles = _roleOptions
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList(growable: true);
    final String initialRole = widget.initialItem?.roleName.trim() ?? '';
    if (initialRole.isNotEmpty && !roles.contains(initialRole)) {
      roles.insert(0, initialRole);
    }
    return roles;
  }

  @override
  void initState() {
    super.initState();
    _roleOptions = List<String>.of(widget.roleOptions);
    _selectedEmployeeId = widget.initialItem?.employeeId ?? _none;
    _selectedRole = widget.initialItem?.roleName.trim() ?? '';
    final List<String> roles = _availableRoles;
    if (_selectedRole.isEmpty && roles.isNotEmpty) {
      _selectedRole = roles.first;
    }
  }

  Future<void> _manageRoles() async {
    final Future<List<String>> Function()? manage = widget.onManageRoles;
    if (manage == null) {
      return;
    }
    final List<String> refreshed = await manage();
    if (!mounted || refreshed.isEmpty) {
      return;
    }
    setState(() {
      _roleOptions = List<String>.of(refreshed);
      if (!_roleOptions.contains(_selectedRole)) {
        _selectedRole = _roleOptions.first;
      }
      _error = '';
    });
  }

  WorkOrderEmployeeOption? get _selectedEmployee {
    for (final WorkOrderEmployeeOption option in widget.options) {
      if (option.id == _selectedEmployeeId) {
        return option;
      }
    }
    return null;
  }

  void _submit() {
    final WorkOrderEmployeeOption? employee = _selectedEmployee;
    if (employee == null) {
      setState(() => _error = 'Selecciona un empleado.');
      return;
    }
    final String role = _selectedRole.trim();
    if (role.isEmpty) {
      setState(() => _error = 'Selecciona el rol que desempeñará.');
      return;
    }
    Navigator.of(context).pop(
      WorkOrderAssignmentItem(
        employeeId: employee.id,
        employeeName: employee.name,
        employeeCode: employee.code,
        roleName: role,
        employeeImagePath: employee.imagePath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> roleOptions = _availableRoles;
    return AlertDialog(
      title: Text(
        widget.initialItem == null ? 'Asignar empleado' : 'Editar asignacion',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSearchableSelectField<String>(
              label: 'Empleado',
              value: _selectedEmployeeId,
              hintText: 'Selecciona un empleado',
              options: <AppSearchableSelectOption<String>>[
                const AppSearchableSelectOption<String>(
                  value: _none,
                  label: 'Seleccionar',
                ),
                ...widget.options.map(
                  (WorkOrderEmployeeOption option) =>
                      AppSearchableSelectOption<String>(
                    value: option.id,
                    label: option.name,
                    subtitle: option.code,
                    searchText: '${option.name} ${option.code}',
                  ),
                ),
              ],
              onChanged: (String value) {
                setState(() {
                  _selectedEmployeeId = value;
                  _error = '';
                });
              },
            ),
            const SizedBox(height: 12),
            AppSearchableSelectField<String>(
              label: 'Rol en este pedido',
              value: _selectedRole.isEmpty ? null : _selectedRole,
              hintText: roleOptions.isEmpty
                  ? 'Primero configura los roles de trabajo'
                  : 'Selecciona el rol del empleado',
              options: roleOptions
                  .map(
                    (String role) => AppSearchableSelectOption<String>(
                      value: role,
                      label: role,
                      searchText: role,
                    ),
                  )
                  .toList(growable: false),
              onChanged: (String value) {
                setState(() {
                  _selectedRole = value;
                  _error = '';
                });
              },
            ),
            if (widget.onManageRoles != null) ...<Widget>[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _manageRoles,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Gestionar roles de trabajo'),
                ),
              ),
            ],
            if (roleOptions.isEmpty) ...<Widget>[
              const SizedBox(height: 8),
              const Text(
                'No hay roles activos disponibles. Configúralos desde Ajustes > Roles de trabajo.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (_error.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
