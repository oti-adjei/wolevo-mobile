/// A failure surfaced to the UI. [fieldErrors] mirrors the shape the register
/// endpoint returns on 400, where the server attaches a message per field
/// (`email` → "An account with this email already exists. Please sign in.",
/// `phoneNumber` → "Account exists with phone number entered").
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  /// The generic, enumeration-safe copy the login form shows on a 401.
  static const invalidCredentials = ApiException(
    'Invalid email or password',
    statusCode: 401,
  );

  static const network = ApiException(
    'Something went wrong. Check your connection and try again.',
  );

  @override
  String toString() => message;
}
