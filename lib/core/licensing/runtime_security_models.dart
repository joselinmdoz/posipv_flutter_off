enum RuntimeSecurityIssueType {
  rootedDevice,
  debuggerAttached,
  emulator,
  testKeys,
  fridaDetected,
  xposedDetected,
  suspiciousFiles,
  rootManagementApp,
  adbEnabled,
}

class RuntimeSecurityIssue {
  const RuntimeSecurityIssue({
    required this.type,
    required this.label,
    required this.isCritical,
  });

  final RuntimeSecurityIssueType type;
  final String label;
  final bool isCritical;
}

class RuntimeSecurityStatus {
  const RuntimeSecurityStatus({
    required this.checkedAt,
    required this.isSupported,
    required this.isDebugBuild,
    required this.issues,
  });

  const RuntimeSecurityStatus.unsupported()
      : checkedAt = null,
        isSupported = false,
        isDebugBuild = false,
        issues = const <RuntimeSecurityIssue>[];

  final DateTime? checkedAt;
  final bool isSupported;
  final bool isDebugBuild;
  final List<RuntimeSecurityIssue> issues;

  bool get hasIssues => issues.isNotEmpty;

  bool get hasCriticalIssues =>
      issues.any((RuntimeSecurityIssue issue) => issue.isCritical);

  bool get shouldBlock => !isDebugBuild && hasCriticalIssues;

  String get statusLabel {
    if (!isSupported) {
      return 'Sin soporte';
    }
    if (shouldBlock) {
      return 'Bloqueado';
    }
    if (hasCriticalIssues) {
      return 'Riesgo detectado';
    }
    if (hasIssues) {
      return 'Advertencia';
    }
    return 'Confiable';
  }

  String get summaryMessage {
    if (!isSupported) {
      return 'La inspeccion nativa de seguridad no esta disponible en esta plataforma.';
    }
    if (issues.isEmpty) {
      return 'No se detectaron senales comunes de manipulacion.';
    }
    final String listed =
        issues.map((RuntimeSecurityIssue issue) => issue.label).join(', ');
    if (shouldBlock) {
      return 'Se detectaron riesgos criticos: $listed.';
    }
    if (hasCriticalIssues) {
      return 'Se detectaron riesgos criticos, pero la app no bloquea en modo debug: $listed.';
    }
    return 'Se detectaron advertencias del entorno: $listed.';
  }
}
