import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_local_datasource.dart';
import 'user_access_bottom_nav.dart';

class UserRoleFormResult {
  const UserRoleFormResult({
    required this.name,
    required this.description,
    required this.permissionKeys,
  });

  final String name;
  final String? description;
  final Set<String> permissionKeys;
}

class UserRoleFormDialog extends StatefulWidget {
  const UserRoleFormDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialPermissionKeys = const <String>{},
    required this.permissions,
    required this.title,
  });

  final String? initialName;
  final String? initialDescription;
  final Set<String> initialPermissionKeys;
  final List<AuthPermissionSummary> permissions;
  final String title;

  @override
  State<UserRoleFormDialog> createState() => _UserRoleFormDialogState();
}

class _UserRoleFormDialogState extends State<UserRoleFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late Set<String> _selectedPermissions;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _descriptionCtrl =
        TextEditingController(text: widget.initialDescription ?? '');
    _selectedPermissions = widget.initialPermissionKeys.toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'El nombre del rol es obligatorio.');
      return;
    }
    if (_selectedPermissions.isEmpty) {
      setState(() => _error = 'Selecciona al menos un permiso.');
      return;
    }
    Navigator.of(context).pop(
      UserRoleFormResult(
        name: name,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        permissionKeys: _selectedPermissions,
      ),
    );
  }

  Map<String, List<AuthPermissionSummary>> _permissionsByDisplayModule() {
    final LinkedHashMap<String, List<AuthPermissionSummary>> grouped =
        LinkedHashMap<String, List<AuthPermissionSummary>>();
    for (final AuthPermissionSummary permission in widget.permissions) {
      final String module = _displayModuleFor(permission);
      grouped
          .putIfAbsent(module, () => <AuthPermissionSummary>[])
          .add(permission);
    }
    return grouped;
  }

  String _displayModuleFor(AuthPermissionSummary permission) {
    final String key = permission.key;
    if (key == 'users.manage' || key.startsWith('settings.security')) {
      return 'Seguridad';
    }
    if (key.startsWith('settings.data')) {
      return 'Datos';
    }
    if (key.startsWith('settings.license')) {
      return 'Licencia';
    }
    if (key.startsWith('warehouses.')) {
      return 'Almacenes';
    }
    if (key.startsWith('settings.')) {
      return 'Ajustes';
    }
    return permission.module;
  }

  void _togglePermission(String permissionKey, bool value) {
    setState(() {
      if (value) {
        _selectedPermissions.add(permissionKey);
      } else {
        _selectedPermissions.remove(permissionKey);
      }
    });
  }

  void _toggleAllPermissions() {
    final Set<String> allKeys =
        widget.permissions.map((AuthPermissionSummary p) => p.key).toSet();
    setState(() {
      if (_selectedPermissions.length == allKeys.length) {
        _selectedPermissions.clear();
      } else {
        _selectedPermissions = allKeys;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<AuthPermissionSummary>> byModule =
        _permissionsByDisplayModule();
    final int totalPermissions = widget.permissions.length;
    final bool allSelected =
        totalPermissions > 0 && _selectedPermissions.length == totalPermissions;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      bottomNavigationBar: UserAccessBottomNav(
        activeTab: UserAccessBottomTab.roles,
        onUsersTap: () => context.go('/configuracion-usuarios'),
        onRolesTap: () {},
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF1152D4),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 40 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF11141A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _RoleFormSectionCard(
                      title: 'Identidad del Rol',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _FieldLabel('Nombre del rol'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            decoration: _inputDecoration(
                              'Ej. Administrador de Almacen',
                            ),
                          ),
                          const SizedBox(height: 18),
                          const _FieldLabel('Descripcion (opcional)'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionCtrl,
                            minLines: 3,
                            maxLines: 4,
                            decoration: _inputDecoration(
                              'Describe brevemente las responsabilidades de este rol...',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.info_rounded,
                              size: 20,
                              color: Color(0xFF1152D4),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Los permisos definen que acciones puede realizar el usuario. Asegurese de asignar solo lo necesario para mantener la seguridad del sistema.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: Color(0xFF1152D4),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EDF2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Permisos por modulo',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF11141A),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Seleccione las capacidades para este rol',
                                      style: TextStyle(
                                        color: Color(0xFF5D667A),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _toggleAllPermissions,
                                child: Text(
                                  allSelected ? 'Quitar todos' : 'Marcar todos',
                                  style: const TextStyle(
                                    color: Color(0xFF1152D4),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints c) {
                              final bool useTwoColumns = c.maxWidth >= 760;
                              const double spacing = 12;
                              final double itemWidth = useTwoColumns
                                  ? (c.maxWidth - spacing) / 2
                                  : c.maxWidth;
                              final List<Widget> cards = byModule.entries
                                  .map(
                                    (MapEntry<String,
                                                List<AuthPermissionSummary>>
                                            entry) =>
                                        SizedBox(
                                      width: itemWidth,
                                      child: _RolePermissionModuleCard(
                                        module: entry.key,
                                        permissions: entry.value,
                                        selectedPermissionKeys:
                                            _selectedPermissions,
                                        onPermissionChanged: _togglePermission,
                                      ),
                                    ),
                                  )
                                  .toList(growable: true);
                              cards.add(
                                SizedBox(
                                  width: itemWidth,
                                  child: const _RolePermissionComingSoonCard(),
                                ),
                              );
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: cards,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF11141A),
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1152D4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7486),
        fontSize: 17,
      ),
      filled: true,
      fillColor: const Color(0xFFE1E5EA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF9FB4E8)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

class _RoleFormSectionCard extends StatelessWidget {
  const _RoleFormSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF11141A),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B3446),
      ),
    );
  }
}

class _RolePermissionModuleCard extends StatelessWidget {
  const _RolePermissionModuleCard({
    required this.module,
    required this.permissions,
    required this.selectedPermissionKeys,
    required this.onPermissionChanged,
  });

  final String module;
  final List<AuthPermissionSummary> permissions;
  final Set<String> selectedPermissionKeys;
  final void Function(String permissionKey, bool selected) onPermissionChanged;

  IconData _iconForModule() {
    final String normalized = module.trim().toLowerCase();
    if (normalized == 'ajustes') {
      return Icons.settings_rounded;
    }
    if (normalized == 'seguridad' || normalized == 'usuarios') {
      return Icons.shield_rounded;
    }
    if (normalized == 'datos') {
      return Icons.storage_rounded;
    }
    if (normalized == 'almacenes') {
      return Icons.inventory_2_rounded;
    }
    if (normalized == 'licencia') {
      return Icons.badge_rounded;
    }
    if (normalized == 'reportes') {
      return Icons.bar_chart_rounded;
    }
    if (normalized == 'ventas') {
      return Icons.point_of_sale_rounded;
    }
    if (normalized == 'inventario') {
      return Icons.inventory_rounded;
    }
    if (normalized == 'tpv') {
      return Icons.storefront_rounded;
    }
    if (normalized == 'productos') {
      return Icons.category_rounded;
    }
    return Icons.widgets_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5EA)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9E3FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForModule(),
                  color: const Color(0xFF5D667A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  module,
                  style: const TextStyle(
                    fontSize: 29 / 2,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF11141A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...permissions.map((AuthPermissionSummary permission) {
            final bool checked =
                selectedPermissionKeys.contains(permission.key);
            return InkWell(
              onTap: () => onPermissionChanged(permission.key, !checked),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: checked,
                        onChanged: (bool? value) {
                          onPermissionChanged(permission.key, value ?? false);
                        },
                        side: const BorderSide(color: Color(0xFFB3BCCC)),
                        activeColor: const Color(0xFF1152D4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          permission.label,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2D3748),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RolePermissionComingSoonCard extends StatelessWidget {
  const _RolePermissionComingSoonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFCDD3DC),
          style: BorderStyle.solid,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.add_circle_rounded,
            size: 24,
            color: Color(0xFF6C7384),
          ),
          SizedBox(height: 8),
          Text(
            'Mas modulos proximamente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6C7384),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
