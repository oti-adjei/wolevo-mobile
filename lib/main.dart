import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env/app_environment.dart';
import 'core/logging/app_logger.dart';
import 'core/observability/observability.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sentry and PostHog start first so nothing that happens during boot is
  // missed. Both no-op when their key is absent, which is the case for every
  // local build.
  await Observability.start(_bootstrap);
}

Future<void> _bootstrap() async {
  final container = ProviderContainer();
  final logger = container.read(loggerProvider);

  void run() {
    logger.info(
      'Wolevo starting',
      context: {
        'env': AppEnvironment.current.name,
        'api': AppEnvironment.current.apiBaseUrl,
        'crashReporting': Observability.sentryEnabled,
        'analytics': Observability.postHogEnabled,
      },
    );

    runApp(
      UncontrolledProviderScope(container: container, child: const WolevoApp()),
    );
  }

  if (Observability.sentryEnabled) {
    // Sentry installs its own FlutterError, PlatformDispatcher and zone
    // handlers. Adding ours on top would report every crash twice, so when it
    // is running we let it own error capture entirely.
    run();
    return;
  }

  // No crash reporter: catch everything ourselves so nothing is silently lost.
  runZonedGuarded(
    () {
      FlutterError.onError = (details) {
        logger.error(
          details.exceptionAsString(),
          error: details.exception,
          stackTrace: details.stack,
          context: {'library': details.library ?? 'flutter'},
        );
        FlutterError.presentError(details);
      };

      WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
        logger.error(
          'Uncaught platform error',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      run();
    },
    (error, stack) =>
        logger.error('Uncaught zone error', error: error, stackTrace: stack),
  );
}

class WolevoApp extends ConsumerWidget {
  const WolevoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Wolevo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      routerConfig: router,
      // A corner ribbon on dev and staging builds, so nobody demos or reports a
      // bug against the wrong environment thinking it is production.
      builder: (context, child) {
        final label = AppEnvironment.current.label;
        if (label == null || child == null) return child ?? const SizedBox();
        return Banner(
          message: label,
          location: BannerLocation.topEnd,
          color: Colors.redAccent,
          child: child,
        );
      },
    );
  }
}
