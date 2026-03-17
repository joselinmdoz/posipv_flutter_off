import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'runtime_security_models.dart';

class RuntimeSecurityService {
  static const MethodChannel _channel =
      MethodChannel('com.example.posipv/device_identity');
  static const Duration _cacheLifetime = Duration(seconds: 20);

  RuntimeSecurityStatus? _cachedStatus;
  DateTime? _cachedAt;

  Future<RuntimeSecurityStatus> inspect({
    bool forceRefresh = false,
  }) async {
    if (kDebugMode) {
      return const RuntimeSecurityStatus.unsupported();
    }
    final DateTime now = DateTime.now();
    if (!forceRefresh &&
        _cachedStatus != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) <= _cacheLifetime) {
      return _cachedStatus!;
    }

    try {
      final Map<Object?, Object?>? response =
          await _channel.invokeMethod<Map<Object?, Object?>>(
        'inspectRuntimeSecurity',
      );
      final Map<String, Object?> raw = <String, Object?>{
        for (final MapEntry<Object?, Object?> entry
            in (response ?? <Object?, Object?>{}).entries)
          entry.key.toString(): entry.value,
      };
      return _cache(_fromMap(raw), now);
    } on MissingPluginException {
      return _cache(const RuntimeSecurityStatus.unsupported(), now);
    }
  }

  RuntimeSecurityStatus _cache(RuntimeSecurityStatus status, DateTime now) {
    _cachedStatus = status;
    _cachedAt = now;
    return status;
  }

  RuntimeSecurityStatus _fromMap(Map<String, Object?> raw) {
    final DateTime? checkedAt = _readDate(raw['checkedAt']);
    final bool isSupported = _readBool(raw['isSupported']);
    final bool isDebugBuild = _readBool(raw['isDebugBuild']);
    final List<RuntimeSecurityIssue> issues = <RuntimeSecurityIssue>[
      if (_readBool(raw['hasSuBinary']))
        _issue(RuntimeSecurityIssueType.rootedDevice),
      if (_readBool(raw['hasRootManagementApp']))
        _issue(RuntimeSecurityIssueType.rootManagementApp),
      if (_readBool(raw['isDebuggerAttached']))
        _issue(RuntimeSecurityIssueType.debuggerAttached),
      if (_readBool(raw['isEmulator']))
        _issue(RuntimeSecurityIssueType.emulator),
      if (_readBool(raw['hasTestKeys']))
        _issue(RuntimeSecurityIssueType.testKeys),
      if (_readBool(raw['hasFridaPort']) || _readBool(raw['hasFridaFiles']))
        _issue(RuntimeSecurityIssueType.fridaDetected),
      if (_readBool(raw['hasXposedFiles']) ||
          _readBool(raw['hasXposedClasses']))
        _issue(RuntimeSecurityIssueType.xposedDetected),
      if (_readBool(raw['hasSuspiciousFiles']))
        _issue(RuntimeSecurityIssueType.suspiciousFiles),
      if (_readBool(raw['adbEnabled']))
        _issue(RuntimeSecurityIssueType.adbEnabled),
    ];

    return RuntimeSecurityStatus(
      checkedAt: checkedAt ?? DateTime.now(),
      isSupported: isSupported,
      isDebugBuild: isDebugBuild,
      issues: issues,
    );
  }

  RuntimeSecurityIssue _issue(RuntimeSecurityIssueType type) {
    switch (type) {
      case RuntimeSecurityIssueType.rootedDevice:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.rootedDevice,
          label: 'binario su',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.debuggerAttached:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.debuggerAttached,
          label: 'debugger activo',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.emulator:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.emulator,
          label: 'emulador',
          isCritical: false,
        );
      case RuntimeSecurityIssueType.testKeys:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.testKeys,
          label: 'firmware test-keys',
          isCritical: false,
        );
      case RuntimeSecurityIssueType.fridaDetected:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.fridaDetected,
          label: 'Frida',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.xposedDetected:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.xposedDetected,
          label: 'Xposed/Substrate',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.suspiciousFiles:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.suspiciousFiles,
          label: 'archivos sospechosos',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.rootManagementApp:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.rootManagementApp,
          label: 'app de root',
          isCritical: true,
        );
      case RuntimeSecurityIssueType.adbEnabled:
        return const RuntimeSecurityIssue(
          type: RuntimeSecurityIssueType.adbEnabled,
          label: 'ADB habilitado',
          isCritical: false,
        );
    }
  }

  bool _readBool(Object? value) {
    if (value is bool) {
      return value;
    }
    return '$value'.toLowerCase() == 'true';
  }

  DateTime? _readDate(Object? value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }
}
