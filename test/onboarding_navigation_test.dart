import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wolevo/core/router/app_router.dart';
import 'package:wolevo/core/router/routes.dart';
import 'package:wolevo/core/theme/app_theme.dart';
import 'package:wolevo/features/auth/presentation/auth_providers.dart';
import 'package:wolevo/features/auth/presentation/screens/login_screen.dart';
import 'package:wolevo/features/auth/presentation/screens/register_screen.dart';
import 'package:wolevo/features/explore/presentation/screens/explore_screen.dart';
import 'package:wolevo/features/onboarding/data/onboarding_repository.dart';

import 'support/fake_auth_repository.dart';

/// Drives the onboarding CTAs through the *real* router, rather than asserting
/// that a callback exists. Each button has to actually land on its screen, and
/// each has to record that onboarding was seen so it never shows twice.
void main() {
  const phone = Size(390, 844);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpOnboarding(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository.signedOut()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.build(),
          routerConfig: container.read(routerProvider),
        ),
      ),
    );

    // Let the splash animation finish and route on to onboarding.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> swipeToLastSlide(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('first launch routes splash -> onboarding', (tester) async {
    await pumpOnboarding(tester);
    expect(find.text('Receive it at home.'), findsOneWidget);
  });

  testWidgets('Skip lands on register and marks onboarding seen', (tester) async {
    final container = await pumpOnboarding(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(
      await container.read(onboardingRepositoryProvider).hasSeenOnboarding(),
      isTrue,
    );
  });

  testWidgets('Explore first lands on the Explore screen', (tester) async {
    final container = await pumpOnboarding(tester);

    await tester.tap(find.text('Explore first'));
    await tester.pumpAndSettle();

    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(
      await container.read(onboardingRepositoryProvider).hasSeenOnboarding(),
      isTrue,
    );
  });

  testWidgets('Create your account lands on register', (tester) async {
    await pumpOnboarding(tester);
    await swipeToLastSlide(tester);

    await tester.tap(find.text('Create your account'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('I already have an account lands on login', (tester) async {
    await pumpOnboarding(tester);
    await swipeToLastSlide(tester);

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a second launch skips onboarding and opens Explore',
      (tester) async {
    SharedPreferences.setMockInitialValues({'wolevo.onboarding.seen': true});
    await pumpOnboarding(tester);

    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text('Receive it at home.'), findsNothing);
  });

  testWidgets('Next advances one slide at a time', (tester) async {
    await pumpOnboarding(tester);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Your own US address.'), findsOneWidget);
    // Still onboarding — Next must not jump straight out to a route.
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('the login route it lands on is reachable without a session',
      (tester) async {
    await pumpOnboarding(tester);
    await swipeToLastSlide(tester);

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    // The auth guard must not bounce a logged-out user off a public route.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);
    expect(AppRoutes.login, '/auth/login');
  });
}
