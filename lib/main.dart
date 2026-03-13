import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

final Set<String> _reportedAsyncErrors = <String>{};

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        _logCapturedError(
          label: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      PlatformDispatcher.instance.onError =
          (Object error, StackTrace stackTrace) {
        _logCapturedError(
          label: 'PlatformDispatcher',
          error: error,
          stackTrace: stackTrace,
        );
        return true;
      };

      runApp(const ProviderScope(child: PosiPvApp()));
    },
    (Object error, StackTrace stackTrace) {
      _logCapturedError(
        label: 'runZonedGuarded',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

void _logCapturedError({
  required String label,
  required Object error,
  StackTrace? stackTrace,
}) {
  final String message = '$label: $error';
  if (_reportedAsyncErrors.add(message)) {
    debugPrint(message);
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
