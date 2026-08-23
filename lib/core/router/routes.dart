/// Route paths, mirroring the web app's URL structure so deep links map 1:1.
abstract final class AppRoutes {
  // Public
  static const splash = '/splash';
  static const onboarding = '/onboarding';

  /// The compact, task-first public entry point.
  static const landing = '/';

  /// The full marketing scroll. The live site served the same page at `/` and
  /// `/welcome`; here `/welcome` keeps that long-form version while `/` is the
  /// lighter Explore screen.
  static const welcome = '/welcome';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const calculator = '/calculator';
  static const help = '/help';
  static const pricing = '/pricing';
  static const support = '/support';

  // Authenticated — the five bottom-tab destinations
  static const home = '/home';
  static const shop = '/shop';
  static const ship = '/ship';
  static const orders = '/orders';
  static const account = '/account';

  // Authenticated — pushed on top of the shell
  static const search = '/search';
  static const product = '/product';
  static const cart = '/cart';
  static const checkout = '/cart/checkout';
  static const addAddress = '/account/addresses/new';
  static const messages = '/messages';

  static String orderDetail(String id) => '/orders/$id';

  /// One account section, e.g. `/account/addresses`. Takes the enum's `name`
  /// rather than the enum itself, since core must not import a feature.
  /// Mirrors the web app's `/profile?section=addresses`.
  static String accountSection(String sectionName) => '$account/$sectionName';

  /// Query key used to carry the intended destination through the auth wall.
  /// The live site drops it; preserving it is a deliberate improvement.
  static const nextParam = 'next';

  static String loginWithNext(String destination) =>
      '$login?$nextParam=${Uri.encodeComponent(destination)}';
}
