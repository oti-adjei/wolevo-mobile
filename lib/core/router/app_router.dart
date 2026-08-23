import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/calculator/presentation/screens/calculator_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/cart/presentation/screens/checkout_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/notifications/presentation/screens/messages_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/product/presentation/screens/product_screen.dart';
import '../../features/profile/presentation/screens/account_screen.dart';
import '../../features/profile/presentation/screens/add_address_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/support/presentation/screens/help_screen.dart';
import '../../features/support/presentation/screens/pricing_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/ship/presentation/screens/register_package_screen.dart';
import '../../features/shop/data/shop_models.dart';
import '../../features/shop/presentation/screens/shop_screen.dart';
import '../../features/ship/presentation/screens/ship_screen.dart';
import '../models/retailer.dart';
import '../analytics/analytics.dart';
import '../analytics/analytics_observer.dart';
import '../theme/app_colors.dart';
import 'app_shell.dart';
import 'splash_screen.dart';
import 'auth_gate.dart';
import 'routes.dart';

final _rootKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ValueNotifier<bool>(false);

  ref.listen(sessionProvider, (_, next) {
    auth.value = next.valueOrNull != null;
  });
  ref.onDispose(auth.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    // Screen views are reported from here rather than from each screen, so a
    // new route cannot silently go untracked.
    observers: [AnalyticsNavigatorObserver(ref.watch(analyticsProvider))],
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);

      // The splash owns the pre-session window: it plays its animation while
      // the stored token is restored, then routes on itself.
      if (state.matchedLocation == AppRoutes.splash) return null;

      // Hold every route until the initial token restore resolves, otherwise a
      // returning user flashes the landing page before being sent to Home.
      if (session.isLoading) return null;

      final loggedIn = session.valueOrNull != null;
      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isLanding = location == AppRoutes.landing;

      if (!loggedIn) {
        if (_isPublic(location)) return null;
        // IMPROVEMENT over the live site: the web app drops the intended
        // destination on redirect, stranding deep-linked users on Home after
        // sign-in. We carry it through as ?next=.
        return AppRoutes.loginWithNext(state.uri.toString());
      }

      // Signed in: the landing and auth routes redirect to Home, matching the
      // site's behaviour of bouncing /auth/login and /auth/register.
      if (isAuthRoute || isLanding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (_, _) => const ExploreScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const LandingScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.calculator,
        builder: (_, _) => const CalculatorScreen(),
      ),
      GoRoute(path: AppRoutes.help, builder: (_, _) => const HelpScreen()),
      GoRoute(
        path: AppRoutes.pricing,
        builder: (_, _) => const PricingScreen(),
      ),
      GoRoute(
        path: AppRoutes.support,
        builder: (_, state) =>
            SupportScreen(initialCountry: state.uri.queryParameters['country']),
      ),

      // Authenticated routes pushed above the tab shell.
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AuthGate(child: SearchScreen()),
      ),
      GoRoute(
        path: AppRoutes.product,
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final params = state.uri.queryParameters;
          return AuthGate(
            child: ProductScreen(
              productId: params['productId'] ?? '',
              retailer: Retailer.fromApi(params['retailer'] ?? 'AMAZON'),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cart,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AuthGate(child: CartScreen()),
        routes: [
          GoRoute(
            path: 'checkout',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const AuthGate(child: CheckoutScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.messages,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AuthGate(child: MessagesScreen()),
      ),
      GoRoute(
        path: '/ship/register',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const AuthGate(child: RegisterPackageScreen()),
      ),

      // The four bottom-tab branches, each with its own navigator stack.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const AuthGate(child: HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shop,
                builder: (_, state) {
                  final params = state.uri.queryParameters;
                  return AuthGate(
                    child: ShopScreen(
                      initialRetailer: params['retailer'] == null
                          ? null
                          : Retailer.fromApi(params['retailer']!),
                      initialMode: ShopMode.fromQuery(params['mode']),
                      initialQuery: params['q'],
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ship,
                builder: (_, _) => const AuthGate(child: ShipScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const AuthGate(child: OrdersScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => AuthGate(
                      child: OrderDetailScreen(
                        orderId: state.pathParameters['id']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.account,
                builder: (_, _) => const AuthGate(child: AccountScreen()),
                routes: [
                  GoRoute(
                    path: 'addresses/new',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) =>
                        const AuthGate(child: AddAddressScreen()),
                  ),
                  GoRoute(
                    path: ':section',
                    parentNavigatorKey: _rootKey,
                    builder: (_, state) => AuthGate(
                      child: ProfileSectionScreen(
                        section: ProfileSection.values.firstWhere(
                          (s) => s.name == state.pathParameters['section'],
                          orElse: () => ProfileSection.profile,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(child: Center(child: Text('No route for ${state.uri}'))),
    ),
  );
});

/// Routes reachable without a session. Mirrors the live site: the marketing
/// pages, the auth screens and the public calculator stay open; everything else
/// bounces to login.
bool _isPublic(String location) {
  const publicPrefixes = [
    AppRoutes.landing,
    AppRoutes.splash,
    AppRoutes.onboarding,
    AppRoutes.welcome,
    '/auth',
    AppRoutes.calculator,
    AppRoutes.help,
    AppRoutes.pricing,
    AppRoutes.support,
  ];
  if (location == AppRoutes.landing) return true;
  return publicPrefixes
      .where((p) => p != AppRoutes.landing)
      .any(location.startsWith);
}
