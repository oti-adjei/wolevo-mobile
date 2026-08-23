import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env/app_environment.dart';

enum LogLevel { debug, info, warning, error }

/// Logging seam.
///
/// Deliberately vendor-neutral: features call this, never a Sentry API. Adding
/// crash reporting later means writing one more implementation and changing the
/// provider — no feature code moves. Same shape as the repository pattern used
/// everywhere else in this codebase.
abstract interface class AppLogger {
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context,
  });

  /// A trail of recent activity, attached to the next error report. Cheap —
  /// breadcrumbs are held in memory and only transmitted when something breaks.
  void breadcrumb(String message, {Map<String, Object?> data});

  /// Ties reports to a user. Pass null on logout.
  void setUser({String? id, String? email});
}

extension AppLoggerLevels on AppLogger {
  void debug(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.debug, message, context: context);

  void info(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.info, message, context: context);

  void warn(String message, {Map<String, Object?> context = const {}}) =>
      log(LogLevel.warning, message, context: context);

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) =>
      log(
        LogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
}

/// Writes to the IDE console. The default everywhere except production.
class ConsoleLogger implements AppLogger {
  ConsoleLogger({this.minimumLevel = LogLevel.debug});

  final LogLevel minimumLevel;

  final List<String> _breadcrumbs = [];

  /// Bounded so a long session cannot grow this without limit.
  static const _maxBreadcrumbs = 50;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (level.index < minimumLevel.index) return;

    final tag = switch (level) {
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warning => 'WARN',
      LogLevel.error => 'ERROR',
    };
    final suffix = context.isEmpty ? '' : ' $context';

    developer.log(
      '$message$suffix',
      name: 'wolevo.$tag',
      error: error,
      stackTrace: stackTrace,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
    );
  }

  @override
  void breadcrumb(String message, {Map<String, Object?> data = const {}}) {
    _breadcrumbs.add(message);
    if (_breadcrumbs.length > _maxBreadcrumbs) _breadcrumbs.removeAt(0);
    if (kDebugMode) log(LogLevel.debug, '🍞 $message', context: data);
  }

  @override
  void setUser({String? id, String? email}) =>
      log(LogLevel.debug, 'User context: ${id ?? 'anonymous'}');
}

/// Swallows everything. Used in tests and as the production default until a
/// crash reporter is wired up.
class NoopLogger implements AppLogger {
  const NoopLogger();

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {}

  @override
  void breadcrumb(String message, {Map<String, Object?> data = const {}}) {}

  @override
  void setUser({String? id, String? email}) {}
}

final loggerProvider = Provider<AppLogger>((ref) {
  final env = AppEnvironment.current;
  final console = env.verboseLogging ? ConsoleLogger() : const NoopLogger();

  // Sentry's iOS SDK does not currently compile under Xcode 26 (see
  // docs/handbook/10-observability.md), so it is not installed. SentryLogger
  // lives in sentry_logger.dart.disabled ready to be restored — the provider is
  // the only line that changes.
  return console;
});
