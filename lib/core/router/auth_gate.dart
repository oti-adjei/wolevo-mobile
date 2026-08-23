import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_scaffolding.dart';

/// Wraps every authenticated route.
///
/// The router's redirect keeps signed-out users away, but a route still builds
/// its first frame while the initial token restore is in flight — and during a
/// logout the session briefly has no value. Screens read the user through
/// `currentUserProvider`, which is non-nullable, so they must not be built in
/// either of those windows. This gate holds a spinner until a session exists.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.valueOrNull == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: AppLoader(),
      );
    }
    return child;
  }
}
