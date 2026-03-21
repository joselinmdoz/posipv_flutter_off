import '../../core/security/app_permissions.dart';

class UserSession {
  const UserSession({
    required this.userId,
    required this.username,
    required this.role,
    this.roleIds = const <String>[],
    this.roleNames = const <String>[],
    this.permissions = const <String>{},
    this.activeTerminalId,
  });

  final String userId;
  final String username;
  final String role;
  final List<String> roleIds;
  final List<String> roleNames;
  final Set<String> permissions;
  final String? activeTerminalId;

  factory UserSession.fromJson(Map<String, Object?> json) {
    final List<String> roleIds = _readStringList(json['roleIds']);
    final List<String> roleNames = _readStringList(json['roleNames']);
    final Set<String> permissions =
        _readStringList(json['permissions']).toSet();
    return UserSession(
      userId: (json['userId'] as String? ?? '').trim(),
      username: (json['username'] as String? ?? '').trim(),
      role: (json['role'] as String? ?? '').trim(),
      roleIds: roleIds,
      roleNames: roleNames,
      permissions: permissions,
      activeTerminalId:
          (json['activeTerminalId'] as String?)?.trim().isEmpty ?? true
              ? null
              : (json['activeTerminalId'] as String?)?.trim(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'userId': userId,
      'username': username,
      'role': role,
      'roleIds': roleIds,
      'roleNames': roleNames,
      'permissions': permissions.toList(growable: false),
      'activeTerminalId': activeTerminalId,
    };
  }

  bool get isAdmin {
    if (roleIds.contains(AppRoleIds.admin)) {
      return true;
    }
    return role.trim().toLowerCase() == 'admin';
  }

  bool hasPermission(String permissionKey) {
    if (isAdmin) {
      return true;
    }
    return permissions.contains(permissionKey);
  }

  UserSession copyWith({
    String? userId,
    String? username,
    String? role,
    List<String>? roleIds,
    List<String>? roleNames,
    Set<String>? permissions,
    String? activeTerminalId,
    bool clearActiveTerminal = false,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      roleIds: roleIds ?? this.roleIds,
      roleNames: roleNames ?? this.roleNames,
      permissions: permissions ?? this.permissions,
      activeTerminalId: clearActiveTerminal
          ? null
          : activeTerminalId ?? this.activeTerminalId,
    );
  }

  static List<String> _readStringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map((Object? item) => (item as String? ?? '').trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
