class UserSession {
  const UserSession({
    required this.userId,
    required this.username,
    required this.role,
    this.activeTerminalId,
  });

  final String userId;
  final String username;
  final String role;
  final String? activeTerminalId;

  factory UserSession.fromJson(Map<String, Object?> json) {
    return UserSession(
      userId: (json['userId'] as String? ?? '').trim(),
      username: (json['username'] as String? ?? '').trim(),
      role: (json['role'] as String? ?? '').trim(),
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
      'activeTerminalId': activeTerminalId,
    };
  }

  UserSession copyWith({
    String? userId,
    String? username,
    String? role,
    String? activeTerminalId,
    bool clearActiveTerminal = false,
  }) {
    return UserSession(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      activeTerminalId: clearActiveTerminal
          ? null
          : activeTerminalId ?? this.activeTerminalId,
    );
  }
}
