import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/security/app_permissions.dart';

class AuthPermissionSummary {
  const AuthPermissionSummary({
    required this.key,
    required this.module,
    required this.label,
    required this.description,
  });

  final String key;
  final String module;
  final String label;
  final String description;
}

class AuthRoleSummary {
  const AuthRoleSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
    required this.permissionKeys,
  });

  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final Set<String> permissionKeys;
}

class AuthUserSummary {
  const AuthUserSummary({
    required this.id,
    required this.username,
    required this.isActive,
    required this.isDefaultAdmin,
    required this.roleIds,
    required this.roleNames,
    this.employeeName,
    this.employeeImagePath,
  });

  final String id;
  final String username;
  final bool isActive;
  final bool isDefaultAdmin;
  final List<String> roleIds;
  final List<String> roleNames;
  final String? employeeName;
  final String? employeeImagePath;
}

class AuthLoginProfile {
  const AuthLoginProfile({
    required this.user,
    required this.roleIds,
    required this.roleNames,
    required this.permissionKeys,
  });

  final User user;
  final List<String> roleIds;
  final List<String> roleNames;
  final Set<String> permissionKeys;
}

class AuthLocalDataSource {
  AuthLocalDataSource(this._db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final Uuid _uuid;
  final Random _random = Random.secure();

  Future<void> ensureDefaultAdmin({
    String username = 'admin',
    String password = 'admin123',
  }) async {
    await _ensureCoreAccessRecords();
    final User? existing = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.username.equals(username)))
        .getSingleOrNull();
    if (existing == null) {
      await createUserWithRoles(
        username: username,
        password: password,
        roleIds: <String>{AppRoleIds.admin},
        isActive: true,
      );
      return;
    }
    await _ensureUserHasRole(existing.id, AppRoleIds.admin);
    if (!existing.isActive) {
      await (_db.update(_db.users)
            ..where((Users tbl) => tbl.id.equals(existing.id)))
          .write(
        UsersCompanion(
          isActive: const Value(true),
          role: const Value('admin'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<String> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final String normalizedRole = role.trim().toLowerCase();
    final Set<String> roleIds = normalizedRole == 'admin'
        ? <String>{AppRoleIds.admin}
        : <String>{AppRoleIds.cashier};
    return createUserWithRoles(
      username: username,
      password: password,
      roleIds: roleIds,
      isActive: true,
    );
  }

  Future<User?> validateCredentials({
    required String username,
    required String password,
  }) async {
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.username.equals(username)))
        .getSingleOrNull();

    if (user == null || !user.isActive) {
      return null;
    }

    final String expectedHash = _hashPassword(password, user.salt);
    if (expectedHash != user.passwordHash) {
      return null;
    }

    return user;
  }

  Future<AuthLoginProfile?> validateCredentialsWithAccess({
    required String username,
    required String password,
  }) async {
    final User? user = await validateCredentials(
      username: username,
      password: password,
    );
    if (user == null) {
      return null;
    }
    final _UserAccessBundle access = await _loadAccessForUser(user);
    return AuthLoginProfile(
      user: user,
      roleIds: access.roleIds,
      roleNames: access.roleNames,
      permissionKeys: access.permissionKeys,
    );
  }

  Future<AuthLoginProfile?> loadActiveProfileByUserId(String userId) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return null;
    }
    final User? user = await (_db.select(_db.users)
          ..where(
            (Users tbl) =>
                tbl.id.equals(cleanUserId) & tbl.isActive.equals(true),
          ))
        .getSingleOrNull();
    if (user == null) {
      return null;
    }
    final _UserAccessBundle access = await _loadAccessForUser(user);
    return AuthLoginProfile(
      user: user,
      roleIds: access.roleIds,
      roleNames: access.roleNames,
      permissionKeys: access.permissionKeys,
    );
  }

  Future<User?> findPreferredActiveUser() async {
    final List<User> users = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.isActive.equals(true)))
        .get();
    if (users.isEmpty) {
      return null;
    }

    users.sort((User a, User b) {
      final bool aIsAdmin = _isDefaultAdmin(a) || a.role == 'admin';
      final bool bIsAdmin = _isDefaultAdmin(b) || b.role == 'admin';
      if (aIsAdmin != bIsAdmin) {
        return aIsAdmin ? -1 : 1;
      }
      return a.createdAt.compareTo(b.createdAt);
    });

    return users.first;
  }

  Future<List<AuthPermissionSummary>> listPermissions() async {
    await _ensureCoreAccessRecords();
    final List<Permission> rows = await (_db.select(_db.permissions)
          ..orderBy(<OrderingTerm Function(Permissions)>[
            (Permissions tbl) => OrderingTerm.asc(tbl.module),
            (Permissions tbl) => OrderingTerm.asc(tbl.label),
          ]))
        .get();
    return rows
        .map(
          (Permission row) => AuthPermissionSummary(
            key: row.key,
            module: row.module,
            label: row.label,
            description: (row.description ?? '').trim(),
          ),
        )
        .toList(growable: false);
  }

  Future<List<AuthRoleSummary>> listRolesWithPermissions() async {
    await _ensureCoreAccessRecords();
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        r.id AS role_id,
        r.name AS role_name,
        r.description AS role_description,
        r.is_system AS role_is_system,
        r.is_active AS role_is_active,
        rp.permission_key AS permission_key
      FROM roles r
      LEFT JOIN role_permissions rp
        ON rp.role_id = r.id
      ORDER BY r.is_system DESC, r.name ASC, rp.permission_key ASC
      ''',
    ).get();

    final Map<String, _RoleBuilder> map = <String, _RoleBuilder>{};
    for (final QueryRow row in rows) {
      final String id = (row.read<String>('role_id')).trim();
      if (id.isEmpty) {
        continue;
      }
      final _RoleBuilder builder = map.putIfAbsent(
        id,
        () => _RoleBuilder(
          id: id,
          name: row.read<String>('role_name'),
          description: row.readNullable<String>('role_description'),
          isSystem: row.read<bool>('role_is_system'),
          isActive: row.read<bool>('role_is_active'),
        ),
      );
      final String permissionKey =
          (row.readNullable<String>('permission_key') ?? '').trim();
      if (permissionKey.isNotEmpty) {
        builder.permissionKeys.add(permissionKey);
      }
    }

    return map.values
        .map(
          (_RoleBuilder builder) => AuthRoleSummary(
            id: builder.id,
            name: builder.name,
            description: builder.description,
            isSystem: builder.isSystem,
            isActive: builder.isActive,
            permissionKeys: builder.permissionKeys,
          ),
        )
        .toList(growable: false);
  }

  Future<String> createRole({
    required String name,
    String? description,
    required Set<String> permissionKeys,
  }) async {
    await _ensureCoreAccessRecords();
    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del rol es obligatorio.');
    }
    final Set<String> normalizedPermissions =
        _normalizePermissionKeys(permissionKeys);
    if (normalizedPermissions.isEmpty) {
      throw Exception('Debes seleccionar al menos un permiso para el rol.');
    }

    final String roleId = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.roles).insert(
            RolesCompanion.insert(
              id: roleId,
              name: cleanName,
              description: Value(_normalizeOptional(description)),
              isSystem: const Value(false),
            ),
          );
      for (final String permissionKey in normalizedPermissions) {
        await _db.into(_db.rolePermissions).insert(
              RolePermissionsCompanion.insert(
                roleId: roleId,
                permissionKey: permissionKey,
              ),
            );
      }
    });
    return roleId;
  }

  Future<void> updateRole({
    required String roleId,
    required String name,
    String? description,
    required Set<String> permissionKeys,
  }) async {
    await _ensureCoreAccessRecords();
    final Role? role = await (_db.select(_db.roles)
          ..where((Roles tbl) => tbl.id.equals(roleId)))
        .getSingleOrNull();
    if (role == null) {
      throw Exception('El rol no existe.');
    }
    if (role.id == AppRoleIds.admin) {
      throw Exception('El rol Administrador no se puede editar.');
    }

    final String cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nombre del rol es obligatorio.');
    }
    final Set<String> normalizedPermissions =
        _normalizePermissionKeys(permissionKeys);
    if (normalizedPermissions.isEmpty) {
      throw Exception('Debes seleccionar al menos un permiso para el rol.');
    }

    await _db.transaction(() async {
      await (_db.update(_db.roles)..where((Roles tbl) => tbl.id.equals(roleId)))
          .write(
        RolesCompanion(
          name: Value(cleanName),
          description: Value(_normalizeOptional(description)),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.rolePermissions)
            ..where((RolePermissions tbl) => tbl.roleId.equals(roleId)))
          .go();

      for (final String permissionKey in normalizedPermissions) {
        await _db.into(_db.rolePermissions).insert(
              RolePermissionsCompanion.insert(
                roleId: roleId,
                permissionKey: permissionKey,
              ),
            );
      }
    });
  }

  Future<void> deleteRole(String roleId) async {
    final Role? role = await (_db.select(_db.roles)
          ..where((Roles tbl) => tbl.id.equals(roleId)))
        .getSingleOrNull();
    if (role == null) {
      return;
    }
    if (role.id == AppRoleIds.admin) {
      throw Exception('El rol Administrador no se puede eliminar.');
    }

    final List<UserRole> assigned = await (_db.select(_db.userRoles)
          ..where((UserRoles tbl) => tbl.roleId.equals(roleId))
          ..limit(1))
        .get();
    if (assigned.isNotEmpty) {
      throw Exception(
        'No puedes eliminar un rol que esta asignado a usuarios.',
      );
    }

    await _db.transaction(() async {
      await (_db.delete(_db.rolePermissions)
            ..where((RolePermissions tbl) => tbl.roleId.equals(roleId)))
          .go();
      await (_db.delete(_db.roles)..where((Roles tbl) => tbl.id.equals(roleId)))
          .go();
    });
  }

  Future<List<AuthUserSummary>> listUsersWithRoles() async {
    await _ensureCoreAccessRecords();
    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        u.id AS user_id,
        u.username AS username,
        u.is_active AS is_active,
        ur.role_id AS role_id,
        r.name AS role_name,
        (
          SELECT e.name
          FROM employees e
          WHERE e.associated_user_id = u.id
            AND e.is_active = 1
          ORDER BY COALESCE(e.updated_at, e.created_at) DESC, e.created_at DESC
          LIMIT 1
        ) AS employee_name,
        (
          SELECT e.image_path
          FROM employees e
          WHERE e.associated_user_id = u.id
            AND e.is_active = 1
          ORDER BY COALESCE(e.updated_at, e.created_at) DESC, e.created_at DESC
          LIMIT 1
        ) AS employee_image_path
      FROM users u
      LEFT JOIN user_roles ur
        ON ur.user_id = u.id
      LEFT JOIN roles r
        ON r.id = ur.role_id
      ORDER BY u.username ASC, r.name ASC
      ''',
    ).get();

    final Map<String, _UserBuilder> users = <String, _UserBuilder>{};
    for (final QueryRow row in rows) {
      final String userId = row.read<String>('user_id');
      final _UserBuilder builder = users.putIfAbsent(
        userId,
        () => _UserBuilder(
          id: userId,
          username: row.read<String>('username'),
          isActive: row.read<bool>('is_active'),
          employeeName: _normalizeOptional(
            row.readNullable<String>('employee_name'),
          ),
          employeeImagePath: _normalizeOptional(
            row.readNullable<String>('employee_image_path'),
          ),
        ),
      );
      builder.employeeName ??= _normalizeOptional(
        row.readNullable<String>('employee_name'),
      );
      builder.employeeImagePath ??= _normalizeOptional(
        row.readNullable<String>('employee_image_path'),
      );
      final String roleId = (row.readNullable<String>('role_id') ?? '').trim();
      final String roleName =
          (row.readNullable<String>('role_name') ?? '').trim();
      if (roleId.isNotEmpty) {
        builder.roleIds.add(roleId);
      }
      if (roleName.isNotEmpty) {
        builder.roleNames.add(roleName);
      }
    }

    return users.values
        .map(
          (_UserBuilder row) => AuthUserSummary(
            id: row.id,
            username: row.username,
            isActive: row.isActive,
            isDefaultAdmin: row.username.toLowerCase() == 'admin',
            roleIds: row.roleIds.toList(growable: false),
            roleNames: row.roleNames.toList(growable: false),
            employeeName: row.employeeName,
            employeeImagePath: row.employeeImagePath,
          ),
        )
        .toList(growable: false);
  }

  Future<AuthUserSummary?> getUserSummaryById(String userId) async {
    final String cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) {
      return null;
    }
    await _ensureCoreAccessRecords();
    final User? user = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(cleanUserId)))
        .getSingleOrNull();
    if (user == null) {
      return null;
    }

    final List<QueryRow> roleRows = await _db.customSelect(
      '''
      SELECT
        ur.role_id AS role_id,
        r.name AS role_name
      FROM user_roles ur
      LEFT JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = ?
      ORDER BY r.name ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanUserId)],
    ).get();
    final Set<String> roleIds = <String>{};
    final Set<String> roleNames = <String>{};
    for (final QueryRow row in roleRows) {
      final String roleId = (row.readNullable<String>('role_id') ?? '').trim();
      final String roleName =
          (row.readNullable<String>('role_name') ?? '').trim();
      if (roleId.isNotEmpty) {
        roleIds.add(roleId);
      }
      if (roleName.isNotEmpty) {
        roleNames.add(roleName);
      }
    }

    final QueryRow? employeeRow = await _db.customSelect(
      '''
      SELECT
        e.name AS employee_name,
        e.image_path AS employee_image_path
      FROM employees e
      WHERE e.associated_user_id = ?
        AND e.is_active = 1
      ORDER BY COALESCE(e.updated_at, e.created_at) DESC, e.created_at DESC
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(cleanUserId)],
    ).getSingleOrNull();

    return AuthUserSummary(
      id: user.id,
      username: user.username,
      isActive: user.isActive,
      isDefaultAdmin: user.username.toLowerCase() == 'admin',
      roleIds: roleIds.toList(growable: false),
      roleNames: roleNames.toList(growable: false),
      employeeName: _normalizeOptional(
        employeeRow?.readNullable<String>('employee_name'),
      ),
      employeeImagePath: _normalizeOptional(
        employeeRow?.readNullable<String>('employee_image_path'),
      ),
    );
  }

  Future<String> createUserWithRoles({
    required String username,
    required String password,
    required Set<String> roleIds,
    required bool isActive,
  }) async {
    await _ensureCoreAccessRecords();
    final String cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw Exception('El usuario es obligatorio.');
    }
    final String cleanPassword = password.trim();
    if (cleanPassword.length < 4) {
      throw Exception('La contrasena debe tener al menos 4 caracteres.');
    }
    final Set<String> normalizedRoleIds = await _normalizeRoleIds(roleIds);
    if (normalizedRoleIds.isEmpty) {
      throw Exception('Debes asignar al menos un rol.');
    }

    final String salt = _newSalt();
    final String hash = _hashPassword(cleanPassword, salt);
    final String id = _uuid.v4();
    final bool isAdminUser = normalizedRoleIds.contains(AppRoleIds.admin);

    await _db.transaction(() async {
      await _db.into(_db.users).insert(
            UsersCompanion.insert(
              id: id,
              username: cleanUsername,
              passwordHash: hash,
              salt: salt,
              role: Value(isAdminUser ? 'admin' : 'cajero'),
              isActive: Value(isActive || isAdminUser),
            ),
          );

      for (final String roleId in normalizedRoleIds) {
        await _db.into(_db.userRoles).insert(
              UserRolesCompanion.insert(
                userId: id,
                roleId: roleId,
              ),
            );
      }
    });

    return id;
  }

  Future<void> updateUser({
    required String userId,
    required String username,
    String? password,
    required Set<String> roleIds,
    required bool isActive,
  }) async {
    await _ensureCoreAccessRecords();
    final User? existing = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El usuario no existe.');
    }

    final bool isDefaultAdmin = _isDefaultAdmin(existing);
    final String cleanUsername = isDefaultAdmin ? 'admin' : username.trim();
    if (cleanUsername.isEmpty) {
      throw Exception('El usuario es obligatorio.');
    }

    String? normalizedPassword;
    if (password != null && password.trim().isNotEmpty) {
      normalizedPassword = password.trim();
      if (normalizedPassword.length < 4) {
        throw Exception('La contrasena debe tener al menos 4 caracteres.');
      }
    }

    Set<String> normalizedRoleIds = await _normalizeRoleIds(roleIds);
    if (isDefaultAdmin) {
      normalizedRoleIds = <String>{AppRoleIds.admin};
    }
    if (normalizedRoleIds.isEmpty) {
      throw Exception('Debes asignar al menos un rol.');
    }

    final bool isAdminUser = normalizedRoleIds.contains(AppRoleIds.admin);
    final bool nextIsActive = isDefaultAdmin ? true : (isActive || isAdminUser);

    await _db.transaction(() async {
      final String? newSalt = normalizedPassword == null ? null : _newSalt();
      final String? newHash = normalizedPassword == null
          ? null
          : _hashPassword(normalizedPassword, newSalt!);

      await (_db.update(_db.users)..where((Users tbl) => tbl.id.equals(userId)))
          .write(
        UsersCompanion(
          username: Value(cleanUsername),
          passwordHash: newHash == null ? const Value.absent() : Value(newHash),
          salt: newSalt == null ? const Value.absent() : Value(newSalt),
          role: Value(isAdminUser ? 'admin' : 'cajero'),
          isActive: Value(nextIsActive),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (_db.delete(_db.userRoles)
            ..where((UserRoles tbl) => tbl.userId.equals(userId)))
          .go();
      for (final String roleId in normalizedRoleIds) {
        await _db.into(_db.userRoles).insert(
              UserRolesCompanion.insert(
                userId: userId,
                roleId: roleId,
              ),
            );
      }
    });
  }

  Future<void> toggleUserActive({
    required String userId,
    required bool isActive,
  }) async {
    final User? existing = await (_db.select(_db.users)
          ..where((Users tbl) => tbl.id.equals(userId)))
        .getSingleOrNull();
    if (existing == null) {
      throw Exception('El usuario no existe.');
    }
    if (_isDefaultAdmin(existing)) {
      throw Exception('El usuario admin por defecto no se puede desactivar.');
    }
    await (_db.update(_db.users)..where((Users tbl) => tbl.id.equals(userId)))
        .write(
      UsersCompanion(
        isActive: Value(isActive),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _ensureCoreAccessRecords() async {
    for (final AppPermissionDefinition definition
        in AppPermissionsCatalog.definitions) {
      await _db.into(_db.permissions).insert(
            PermissionsCompanion.insert(
              key: definition.key,
              module: definition.module,
              label: definition.label,
              description: Value(definition.description),
              isSystem: const Value(true),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    await _db.into(_db.roles).insert(
          RolesCompanion.insert(
            id: AppRoleIds.admin,
            name: 'Administrador',
            description: const Value('Acceso total a la aplicacion.'),
            isSystem: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _db.into(_db.roles).insert(
          RolesCompanion.insert(
            id: AppRoleIds.cashier,
            name: 'Cajero',
            description: const Value('Acceso basico de caja y TPV.'),
            isSystem: const Value(true),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    for (final String permissionKey in AppPermissionsCatalog.allKeys) {
      await _db.into(_db.rolePermissions).insert(
            RolePermissionsCompanion.insert(
              roleId: AppRoleIds.admin,
              permissionKey: permissionKey,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    for (final String permissionKey
        in AppPermissionsCatalog.defaultCashierPermissions) {
      await _db.into(_db.rolePermissions).insert(
            RolePermissionsCompanion.insert(
              roleId: AppRoleIds.cashier,
              permissionKey: permissionKey,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  Future<void> _ensureUserHasRole(String userId, String roleId) async {
    await _db.into(_db.userRoles).insert(
          UserRolesCompanion.insert(
            userId: userId,
            roleId: roleId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  Future<Set<String>> _normalizeRoleIds(Set<String> roleIds) async {
    final Set<String> requested = roleIds
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toSet();
    if (requested.isEmpty) {
      return <String>{};
    }

    final List<Role> roles = await (_db.select(_db.roles)
          ..where((Roles tbl) =>
              tbl.id.isIn(requested) & tbl.isActive.equals(true)))
        .get();
    return roles.map((Role role) => role.id).toSet();
  }

  Set<String> _normalizePermissionKeys(Set<String> permissionKeys) {
    return permissionKeys
        .map((String value) => value.trim())
        .where((String value) => AppPermissionsCatalog.allKeys.contains(value))
        .toSet();
  }

  Future<_UserAccessBundle> _loadAccessForUser(User user) async {
    await _ensureCoreAccessRecords();
    await _ensureRoleAssignmentsForLegacyUser(user);

    final List<QueryRow> rows = await _db.customSelect(
      '''
      SELECT
        r.id AS role_id,
        r.name AS role_name,
        rp.permission_key AS permission_key
      FROM user_roles ur
      INNER JOIN roles r
        ON r.id = ur.role_id
      LEFT JOIN role_permissions rp
        ON rp.role_id = r.id
      WHERE ur.user_id = ?
        AND r.is_active = 1
      ORDER BY r.name ASC, rp.permission_key ASC
      ''',
      variables: <Variable<Object>>[Variable<String>(user.id)],
    ).get();

    final Set<String> roleIds = <String>{};
    final Set<String> roleNames = <String>{};
    final Set<String> permissionKeys = <String>{};
    for (final QueryRow row in rows) {
      final String roleId = (row.read<String>('role_id')).trim();
      final String roleName = (row.read<String>('role_name')).trim();
      final String permissionKey =
          (row.readNullable<String>('permission_key') ?? '').trim();
      if (roleId.isNotEmpty) {
        roleIds.add(roleId);
      }
      if (roleName.isNotEmpty) {
        roleNames.add(roleName);
      }
      if (permissionKey.isNotEmpty) {
        permissionKeys.add(permissionKey);
      }
    }

    if (roleIds.isEmpty) {
      final String fallbackRoleId = user.role.trim().toLowerCase() == 'admin'
          ? AppRoleIds.admin
          : AppRoleIds.cashier;
      await _ensureUserHasRole(user.id, fallbackRoleId);
      roleIds.add(fallbackRoleId);
      final Role? role = await (_db.select(_db.roles)
            ..where((Roles tbl) => tbl.id.equals(fallbackRoleId)))
          .getSingleOrNull();
      if (role != null) {
        roleNames.add(role.name);
      }
    }

    if (roleIds.contains(AppRoleIds.admin)) {
      permissionKeys.addAll(AppPermissionsCatalog.allKeys);
    }

    return _UserAccessBundle(
      roleIds: roleIds.toList(growable: false),
      roleNames: roleNames.toList(growable: false),
      permissionKeys: permissionKeys,
    );
  }

  Future<void> _ensureRoleAssignmentsForLegacyUser(User user) async {
    final List<UserRole> assigned = await (_db.select(_db.userRoles)
          ..where((UserRoles tbl) => tbl.userId.equals(user.id))
          ..limit(1))
        .get();
    if (assigned.isNotEmpty) {
      return;
    }
    final String fallbackRoleId =
        user.role.trim().toLowerCase() == 'admin' || _isDefaultAdmin(user)
            ? AppRoleIds.admin
            : AppRoleIds.cashier;
    await _ensureUserHasRole(user.id, fallbackRoleId);
  }

  bool _isDefaultAdmin(User user) {
    return user.username.trim().toLowerCase() == 'admin';
  }

  String? _normalizeOptional(String? raw) {
    final String value = (raw ?? '').trim();
    return value.isEmpty ? null : value;
  }

  String _newSalt() {
    final List<int> bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final List<int> bytes = utf8.encode('$password::$salt');
    return sha256.convert(bytes).toString();
  }
}

class _RoleBuilder {
  _RoleBuilder({
    required this.id,
    required this.name,
    required this.description,
    required this.isSystem,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isActive;
  final Set<String> permissionKeys = <String>{};
}

class _UserBuilder {
  _UserBuilder({
    required this.id,
    required this.username,
    required this.isActive,
    this.employeeName,
    this.employeeImagePath,
  });

  final String id;
  final String username;
  final bool isActive;
  String? employeeName;
  String? employeeImagePath;
  final Set<String> roleIds = <String>{};
  final Set<String> roleNames = <String>{};
}

class _UserAccessBundle {
  const _UserAccessBundle({
    required this.roleIds,
    required this.roleNames,
    required this.permissionKeys,
  });

  final List<String> roleIds;
  final List<String> roleNames;
  final Set<String> permissionKeys;
}
