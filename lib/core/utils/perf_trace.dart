import 'package:flutter/foundation.dart';

class PerfTrace {
  PerfTrace(this.label) : _watch = Stopwatch()..start() {
    if (kDebugMode) {
      debugPrint('[PERF][$label] start');
    }
  }

  final String label;
  final Stopwatch _watch;

  void mark(String step) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[PERF][$label] $step @ ${_watch.elapsedMilliseconds}ms');
  }

  void end([String? message]) {
    if (!kDebugMode) {
      return;
    }
    final String suffix = message == null || message.trim().isEmpty
        ? ''
        : ' | $message';
    debugPrint('[PERF][$label] end @ ${_watch.elapsedMilliseconds}ms$suffix');
  }
}
