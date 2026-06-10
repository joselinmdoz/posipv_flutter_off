import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_searchable_select_field.dart';
import '../../data/pedidos_local_datasource.dart';

class WorkOrderTaskWorkerDialog extends StatefulWidget {
  const WorkOrderTaskWorkerDialog({
    super.key,
    required this.options,
    required this.roleOptions,
    this.initialItem,
  });

  final List<WorkOrderEmployeeOption> options;
  final List<String> roleOptions;
  final WorkOrderTaskWorkerItem? initialItem;

  @override
  State<WorkOrderTaskWorkerDialog> createState() =>
      _WorkOrderTaskWorkerDialogState();
}

class _WorkOrderTaskWorkerDialogState extends State<WorkOrderTaskWorkerDialog> {
  static const String _none = '__none__';

  String _selectedEmployeeId = _none;
  String _selectedRole = '';
  String _error = '';

  List<String> get _availableRoles {
    final List<String> roles = widget.roleOptions
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
    _selectedEmployeeId = widget.initialItem?.employeeId ?? _none;
    _selectedRole = widget.initialItem?.roleName.trim() ?? '';
    final List<String> roles = _availableRoles;
    if (_selectedRole.isEmpty && roles.isNotEmpty) {
      _selectedRole = roles.first;
    }
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
      setState(() => _error = 'Selecciona un trabajador.');
      return;
    }
    final String role = _selectedRole.trim();
    if (role.isEmpty) {
      setState(() => _error = 'Selecciona el rol que cumplio.');
      return;
    }
    Navigator.of(context).pop(
      WorkOrderTaskWorkerItem(
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
        widget.initialItem == null ? 'Agregar trabajador' : 'Editar trabajador',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppSearchableSelectField<String>(
              label: 'Trabajador',
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
              label: 'Rol ejecutado',
              value: _selectedRole.isEmpty ? null : _selectedRole,
              hintText: roleOptions.isEmpty
                  ? 'Primero configura los roles de trabajo'
                  : 'Selecciona el rol del trabajador',
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
