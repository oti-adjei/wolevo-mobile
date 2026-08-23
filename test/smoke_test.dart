import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wolevo/core/router/auth_gate.dart';
import 'package:wolevo/core/router/splash_screen.dart';
import 'package:wolevo/core/widgets/wolevo_mark.dart';
import 'package:wolevo/core/theme/app_theme.dart';
import 'package:wolevo/features/auth/presentation/auth_providers.dart';
import 'package:wolevo/features/auth/presentation/screens/landing_screen.dart';
import 'package:wolevo/features/auth/presentation/screens/login_screen.dart';
import 'package:wolevo/features/auth/presentation/screens/register_screen.dart';
import 'package:wolevo/features/calculator/presentation/widgets/calculator_panel.dart';
import 'package:wolevo/features/explore/presentation/screens/explore_screen.dart';
import 'package:wolevo/features/cart/presentation/screens/cart_screen.dart';
import 'package:wolevo/features/home/presentation/screens/home_screen.dart';
import 'package:wolevo/core/widgets/retailer_logo.dart';
import 'package:wolevo/core/models/retailer.dart';
import 'package:wolevo/features/notifications/presentation/screens/messages_screen.dart';
import 'package:wolevo/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:wolevo/features/orders/presentation/screens/orders_screen.dart';
import 'package:wolevo/features/product/presentation/screens/product_screen.dart';
import 'package:wolevo/features/profile/presentation/profile_providers.dart';
import 'package:wolevo/features/profile/presentation/screens/account_screen.dart';
import 'package:wolevo/features/profile/presentation/screens/profile_screen.dart';
import 'package:wolevo/features/ship/presentation/screens/ship_screen.dart';
import 'package:wolevo/features/shop/presentation/screens/shop_screen.dart';
import 'package:wolevo/features/support/presentation/screens/help_screen.dart';
import 'package:wolevo/features/support/presentation/screens/pricing_screen.dart';
import 'package:wolevo/features/support/presentation/screens/support_screen.dart';

import 'support/fake_auth_repository.dart';

/// Renders each screen on a phone-sized surface and asserts it lays out without
/// throwing or overflowing. This is a wiring check, not a golden test.
void main() {
  // A 390x844 logical viewport — an iPhone 15-class device.
  const phone = Size(390, 844);

  Widget wrap(Widget child, {bool signedIn = true}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          signedIn ? FakeAuthRepository.signedIn() : FakeAuthRepository.signedOut(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: signedIn ? AuthGate(child: child) : child,
      ),
    );
  }

  Future<void> pumpPhone(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = phone * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = phone;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(child);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('splash animates the mark and then settles', (tester) async {
    await tester.pumpWidget(wrap(const SplashScreen(), signedIn: false));
    // First frame must already show the mark, so the handoff from the native
    // splash has nothing to flash through.
    expect(find.byType(AnimatedWolevoMark), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('wolevo'), findsWidgets);
    // Let the controller finish so the test does not end mid-animation.
    await tester.pump(const Duration(milliseconds: 900));
  });

  testWidgets('onboarding swipes through every slide', (tester) async {
    await pumpPhone(tester, wrap(const OnboardingScreen(), signedIn: false));
    // Slide 1 — the landing hero, condensed.
    expect(find.text('Receive it at home.'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Your own US address.'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('No US card needed.'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Track every package.'), findsOneWidget);
    // The last slide swaps the CTA pair.
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets('explore offers shop, ship and a working calculator', (tester) async {
    await pumpPhone(tester, wrap(const ExploreScreen(), signedIn: false));
    expect(find.text('Shop global.'), findsOneWidget);
    expect(find.text('Shop'), findsWidgets);

    // Ship tab.
    await tester.tap(find.text('Ship'));
    await tester.pumpAndSettle();
    expect(find.text('Your US warehouse address'), findsOneWidget);

    // Calculator tab — the one public tab that does real work.
    await tester.tap(find.text('Calculator'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Know your cost'), findsWidgets);
  });

  testWidgets('landing renders on a phone', (tester) async {
    await pumpPhone(tester, wrap(const LandingScreen(), signedIn: false));
    expect(find.textContaining('Shop global.'), findsWidgets);
  });

  testWidgets('login renders and shows its copy', (tester) async {
    await pumpPhone(tester, wrap(const LoginScreen(), signedIn: false));
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('register shows every required field', (tester) async {
    await pumpPhone(tester, wrap(const RegisterScreen(), signedIn: false));
    expect(find.text('Create Account'), findsOneWidget);
    // Field labels render inside RichText (the red required asterisk is a
    // second span), so assert on the inputs themselves: first, last, email,
    // phone, password, confirm.
    expect(find.byType(TextField), findsAtLeast(6));
    expect(find.textContaining('Have a referral code?'), findsOneWidget);
  });

  testWidgets('calculator panel renders standalone', (tester) async {
    await pumpPhone(tester, wrap(
        const Scaffold(body: SingleChildScrollView(child: CalculatorPanel())),
      ));
    expect(find.textContaining('Know your cost'), findsWidgets);
  });

  testWidgets('home renders for a signed-in user', (tester) async {
    await pumpPhone(tester, wrap(const HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Hello'), findsWidgets);
    // The store row is a fixed four-up grid with a View All overflow, matching
    // the client mockups — not a scrolling pill strip.
    expect(find.text('Browse Top U.S stores'), findsOneWidget);
    expect(find.text('View All'), findsWidgets);
    // "Amazon" also appears in the deal-section headings, so assert on the
    // logo tiles instead. The row scrolls, so only the ones on screen are
    // built — at 390pt that is at least four of the six.
    expect(find.byType(RetailerLogo), findsAtLeast(4));
  });

  testWidgets('ship renders the three intent cards', (tester) async {
    await pumpPhone(tester, wrap(const ShipScreen()));
    expect(find.text("I'm yet to shop"), findsOneWidget);
    expect(find.text('Someone is sending to me'), findsOneWidget);
    expect(find.text('Already shipped'), findsOneWidget);
  });

  testWidgets('orders renders its filters and empty/loaded state', (tester) async {
    await pumpPhone(tester, wrap(const OrdersScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('account hub lists every section and the locker id', (tester) async {
    await pumpPhone(tester, wrap(const AccountScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Addresses'), findsOneWidget);
    expect(find.text('Referrals'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    // The identity card replaces the reference design's premium banner.
    expect(find.text('DEMO1234'), findsOneWidget);
    // Log out sits at the very bottom, below the groups.
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('an account section opens as its own route', (tester) async {
    await pumpPhone(
      tester,
      wrap(const ProfileSectionScreen(section: ProfileSection.addresses)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Addresses'), findsWidgets);
    expect(find.text('Saved Addresses'), findsWidgets);
  });

  testWidgets('messages renders', (tester) async {
    await pumpPhone(tester, wrap(const MessagesScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('cart renders the seeded items and totals', (tester) async {
    await pumpPhone(tester, wrap(const CartScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Order Summary'), findsWidgets);
    expect(find.textContaining('UGREEN'), findsWidgets);
    // The cost summary sits below the item list, so drag it into view. The
    // three seeded Amazon items sum to the live cart's subtotal.
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pump();
    expect(find.textContaining(r'$187.68'), findsWidgets);
    expect(find.textContaining('Calculated at checkout'), findsWidgets);
  });

  testWidgets('shop renders the browse grid', (tester) async {
    await pumpPhone(tester, wrap(const ShopScreen()));
    await tester.pump(const Duration(seconds: 1));
    // The mockup's Shop header: Select Store chips, then search, then SKU.
    expect(find.text('Select Store'), findsOneWidget);
    expect(find.text('Enter SKU'), findsOneWidget);
    expect(find.text('All'), findsWidgets);
    expect(find.byType(RetailerLogo), findsAtLeast(3));
  });

  testWidgets('product renders the observed Anker listing', (tester) async {
    await pumpPhone(
      tester,
      wrap(const ProductScreen(productId: 'B088NRLMPV', retailer: Retailer.amazon)),
    );
    await tester.pump(const Duration(seconds: 1));
    // Details captured verbatim from the live product page.
    expect(find.textContaining('Anker USB C to USB C Cable'), findsWidgets);
    expect(find.text('1 / 7'), findsWidgets);
    // The sticky action bar is always visible; the landed-cost callout sits
    // below the gallery, so scroll down for it.
    expect(find.textContaining('Add to Cart'), findsWidgets);
    // The thumbnail strip is a second (horizontal) ListView, so target the
    // vertical page scroller explicitly.
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('Free Shipping to our US Warehouse'), findsWidgets);
    expect(find.textContaining('Ship to Ghana'), findsWidgets);
  });

  testWidgets('help renders its FAQ groups', (tester) async {
    await pumpPhone(tester, wrap(const HelpScreen(), signedIn: false));
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('How does shopping on Wolevo work?'), findsOneWidget);
  });

  testWidgets('pricing renders the first accordion open', (tester) async {
    await pumpPhone(tester, wrap(const PricingScreen(), signedIn: false));
    expect(find.text('Pricing Overview'), findsOneWidget);
    // The expanded body sits below the fold behind the hero, so scroll to it.
    await tester.scrollUntilVisible(find.text('Item Cost'), 200);
    expect(find.text('Item Cost'), findsOneWidget);
  });

  testWidgets('support renders the office cards', (tester) async {
    await pumpPhone(
      tester,
      wrap(const SupportScreen(initialCountry: 'ghana'), signedIn: false),
    );
    expect(find.text('Ghana'), findsWidgets);
    expect(find.text('support@wolevo.com'), findsWidgets);
  });
}
