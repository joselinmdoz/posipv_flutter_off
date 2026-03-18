import 'package:flutter/material.dart';
import '../../data/tpv_local_datasource.dart';
import 'tpv_employee_avatar.dart';

class TpvOpenSessionDialog extends StatefulWidget {
  final TpvTerminalView terminal;
  final List<TpvEmployee> employees;
  final VoidCallback onManageEmployees;

  const TpvOpenSessionDialog({
    super.key,
    required this.terminal,
    required this.employees,
    required this.onManageEmployees,
  });

  @override
  State<TpvOpenSessionDialog> createState() => _TpvOpenSessionDialogState();
}

class _TpvOpenSessionDialogState extends State<TpvOpenSessionDialog> {
  final Set<String> _selectedEmployeeIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.employees.isNotEmpty) {
      _selectedEmployeeIds.add(widget.employees.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101622) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Abrir turno',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer to balance back button
                ],
              ),
            ),

            const Divider(height: 32, thickness: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Abrir turno en ${widget.terminal.terminal.name}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona los responsables para iniciar la jornada.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'RESPONSABLES DE TURNO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.employees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final employee = widget.employees[index];
                        final isSelected = _selectedEmployeeIds.contains(employee.id);

                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                if (_selectedEmployeeIds.length > 1) {
                                  _selectedEmployeeIds.remove(employee.id);
                                }
                              } else {
                                _selectedEmployeeIds.add(employee.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected && !isDark
                                  ? const Color(0xFF1152D4).withValues(alpha: 0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF1152D4)
                                    : scheme.outline.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                TpvEmployeeAvatar(
                                  imagePath: employee.imagePath,
                                  radius: 24,
                                  backgroundColor: scheme.primaryContainer.withValues(alpha: 0.3),
                                  iconColor: scheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        employee.associatedUsername ?? 'Empleado',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1152D4)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1152D4)
                                          : scheme.outline.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: widget.onManageEmployees,
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: const Text(
                        'Agregar empleado',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1152D4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: scheme.outline.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedEmployeeIds.isEmpty
                          ? null
                          : () => Navigator.pop(context, _selectedEmployeeIds.toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1152D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Abrir',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
