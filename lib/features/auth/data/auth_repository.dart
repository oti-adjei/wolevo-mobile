import 'auth_models.dart';

/// Every auth call the web app makes, in one interface. A Dio-backed
/// implementation drops straight in behind this — the UI never changes.
///
/// Endpoint map (see discovery-notes.md § "Network during auth"):
///   POST /auth/restore                       — session bootstrap, 401 when out
///   POST /auth/login                         — { email, password }
///   POST /auth/register                      — full payload, 400 on duplicate
///   POST /auth/forgot-password?email=…       — email travels as a query param
///   POST /auth/resend-verification-email?email=…
abstract interface class AuthRepository {
  /// Restores a session from a stored token. Returns null when there is none.
  Future<AuthSession?> restore();

  Future<AuthSession> login(LoginRequest request);

  /// On success the user is signed in immediately — the site has no
  /// verification gate and no onboarding tour.
  Future<AuthSession> register(RegisterRequest request);

  Future<void> logout();

  /// Always resolves, whether or not the address exists — the success copy is
  /// deliberately enumeration-safe.
  Future<void> sendPasswordReset(String email);

  Future<void> resendVerificationEmail(String email);

  /// Re-checks verification status after the user taps "I've Already Verified".
  Future<WolevoUser> refreshUser();

  /// Google OAuth. Stubbed for now — the flow was never exercised in discovery.
  Future<AuthSession> continueWithGoogle();
}
