import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/auth_local_datasource.dart';
import 'user_access_bottom_nav.dart';

class UserFormResult {
  const UserFormResult({
    required this.username,
    required this.password,
    required this.roleIds,
    required this.isActive,
  });

  final String username;
  final String? password;
  final Set<String> roleIds;
  final bool isActive;
}

class UserFormDialog extends StatefulWidget {
  const UserFormDialog({
    super.key,
    required this.title,
    required this.roles,
    this.initialUsername,
    this.initialRoleIds = const <String>{},
    this.initialIsActive = true,
    this.usernameLocked = false,
    this.activeLocked = false,
    this.rolesLocked = false,
    this.requirePassword = true,
  });

  final String title;
  final List<AuthRoleSummary> roles;
  final String? initialUsername;
  final Set<String> initialRoleIds;
  final bool initialIsActive;
  final bool usernameLocked;
  final bool activeLocked;
  final bool rolesLocked;
  final bool requirePassword;

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late bool _isActive;
  late Set<String> _selectedRoleIds;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername ?? '');
    _passwordCtrl = TextEditingController();
    _isActive = widget.initialIsActive;
    _selectedRoleIds = widget.initialRoleIds.toSet();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final String username = _usernameCtrl.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'El usuario es obligatorio.');
      return;
    }
    final String password = _passwordCtrl.text.trim();
    if (widget.requirePassword && password.length < 4) {
      setState(
        () => _error = 'La contrasena debe tener al menos 4 caracteres.',
      );
      return;
    }
    if (_selectedRoleIds.isEmpty) {
      setState(() => _error = 'Debes asignar al menos un rol.');
      return;
    }

    Navigator.of(context).pop(
      UserFormResult(
        username: username,
        password: password.isEmpty ? null : password,
        roleIds: _selectedRoleIds,
        isActive: _isActive,
      ),
    );
  }

  String _roleDescription(AuthRoleSummary role) {
    final String? fromDb = role.description?.trim();
    if (fromDb != null && fromDb.isNotEmpty) {
      return fromDb;
    }
    final String normalized = role.name.trim().toLowerCase();
    if (normalized == 'administrador') {
      return 'Acceso total a reportes, finanzas y configuracion global del sistema.';
    }
    if (normalized == 'cajero') {
      return 'Gestion de ventas, apertura y cierre de caja, y devoluciones.';
    }
    if (normalized == 'subadmin') {
      return 'Supervision de inventarios y gestion de personal operativo.';
    }
    return 'Sin descripcion';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      bottomNavigationBar: UserAccessBottomNav(
        activeTab: UserAccessBottomTab.users,
        onUsersTap: () => Navigator.of(context).maybePop(),
        onRolesTap: () => context.go('/configuracion-roles'),
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
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 40 / 2,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF11141A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gestion de\nNegocio',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 40 / 2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1152D4),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _FormSectionCard(
                      title: 'Informacion de acceso',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const _FieldLabel('Usuario'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _usernameCtrl,
                            enabled: !widget.usernameLocked,
                            decoration: _inputDecoration('Ej. juan.perez'),
                          ),
                          const SizedBox(height: 18),
                          _FieldLabel(
                            widget.requirePassword
                                ? 'Contrasena'
                                : 'Contrasena (opcional)',
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration('••••••••').copyWith(
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFF6E778B),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECF1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Usuario activo',
                                        style: TextStyle(
                                          fontSize: 36 / 2,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF11141A),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Permitir que el usuario inicie sesion inmediatamente',
                                        style: TextStyle(
                                          fontSize: 28 / 2,
                                          color: Color(0xFF48546A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch.adaptive(
                                  value: _isActive,
                                  onChanged: widget.activeLocked
                                      ? null
                                      : (bool value) {
                                          setState(() => _isActive = value);
                                        },
                                  activeTrackColor: const Color(0xFF1152D4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSectionCard(
                      backgroundColor: const Color(0xFFE9EDF2),
                      titleWidget: const Row(
                        children: <Widget>[
                          Icon(
                            Icons.verified_user_rounded,
                            color: Color(0xFF1152D4),
                            size: 22,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Asignacion de Roles',
                            style: TextStyle(
                              fontSize: 42 / 2,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF30384A),
                            ),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          ...widget.roles.map((AuthRoleSummary role) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _RoleSelectionTile(
                                roleName: role.name,
                                description: _roleDescription(role),
                                selected: _selectedRoleIds.contains(role.id),
                                enabled: !widget.rolesLocked,
                                onChanged: (bool value) {
                                  setState(() {
                                    if (value) {
                                      _selectedRoleIds.add(role.id);
                                    } else {
                                      _selectedRoleIds.remove(role.id);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                          if (widget.rolesLocked)
                            const Padding(
                              padding: EdgeInsets.only(top: 2, bottom: 8),
                              child: Text(
                                'Los roles del admin por defecto no se pueden modificar.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDE6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(
                                  color: Color(0xFF1152D4),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(top: 1),
                                  child: Icon(
                                    Icons.info_rounded,
                                    color: Color(0xFF1152D4),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Los roles definen que secciones del panel de control podra visualizar este usuario. Puede asignar multiples roles.',
                                    style: TextStyle(
                                      color: Color(0xFF1152D4),
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1152D4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.title == 'Editar usuario'
                        ? 'Guardar cambios'
                        : 'Guardar Usuario',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
        fontSize: 34 / 2,
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

class _FormSectionCard extends StatelessWidget {
  const _FormSectionCard({
    required this.child,
    this.title,
    this.titleWidget,
    this.backgroundColor,
  });

  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (titleWidget != null)
            titleWidget!
          else if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Color(0xFF30384A),
              ),
            ),
          const SizedBox(height: 16),
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
        fontSize: 34 / 2,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2B3446),
      ),
    );
  }
}

class _RoleSelectionTile extends StatelessWidget {
  const _RoleSelectionTile({
    required this.roleName,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String roleName;
  final String description;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!selected) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFB9C9EE) : const Color(0xFFE1E5EA),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                height: 22,
                width: 22,
                child: Checkbox(
                  value: selected,
                  onChanged: enabled
                      ? (bool? value) => onChanged(value ?? false)
                      : null,
                  activeColor: const Color(0xFF1152D4),
                  side: const BorderSide(color: Color(0xFFB3BCCC)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    roleName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF11141A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF30384A),
                      height: 1.35,
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
