import 'dart:math';

import '../../../core/models/destination_country.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

/// In-memory auth. Holds one seeded account so the demo can sign in without
/// registering, and accepts new registrations for the rest of the session.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._storage);

  final TokenStorage _storage;

  static const _latency = Duration(milliseconds: 650);

  /// Seeded demo credentials.
  static const demoEmail = 'demo@wolevo.com';
  static const demoPassword = 'Demo1234!';

  /// The warehouse address is identical for every user — verbatim from the site.
  static const _warehouse = WarehouseAddress(
    name: 'Wolevo DEMO1234',
    addressLine1: '20 Penn Mart Center',
    addressLine2: 'PMB302',
    city: 'New Castle',
    stateCode: 'DE',
    stateName: 'Delaware',
    zipCode: '19720',
    countryCode: 'US',
    phone: '+1 (240) 887-5614',
  );

  final Map<String, String> _passwords = {demoEmail: demoPassword};

  final Map<String, WolevoUser> _users = {
    demoEmail: const WolevoUser(
      id: 'usr_demo',
      firstName: 'Demo',
      lastName: 'User',
      email: demoEmail,
      emailVerified: true,
      phoneNumber: '+233200000000',
      destinationCountry: DestinationCountry.ghana,
      lockerId: 'DEMO1234',
      accountType: AccountType.personal,
      referralCode: 'DEMOREF1',
    ),
  };

  AuthSession? _session;

  WarehouseAddress _addressFor(WolevoUser user) => WarehouseAddress(
    name: user.lockerName,
    addressLine1: _warehouse.addressLine1,
    addressLine2: _warehouse.addressLine2,
    city: _warehouse.city,
    stateCode: _warehouse.stateCode,
    stateName: _warehouse.stateName,
    zipCode: _warehouse.zipCode,
    countryCode: _warehouse.countryCode,
    phone: _warehouse.phone,
  );

  @override
  Future<AuthSession?> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final token = await _storage.readAccessToken();
    if (token == null) return null;
    // Session survives a hot restart within the same process only; a real impl
    // would exchange the stored token for a fresh user payload here.
    return _session;
  }

  @override
  Future<AuthSession> login(LoginRequest request) async {
    await Future<void>.delayed(_latency);
    final email = request.email.trim().toLowerCase();
    if (_passwords[email] != request.password) {
      throw ApiException.invalidCredentials;
    }
    final user = _users[email]!;
    return _establish(user);
  }

  @override
  Future<AuthSession> register(RegisterRequest request) async {
    await Future<void>.delayed(_latency);

    final email = request.email.trim().toLowerCase();
    final fieldErrors = <String, String>{};

    if (_users.containsKey(email)) {
      fieldErrors['email'] =
          'An account with this email already exists. Please sign in.';
    }
    if (_users.values.any((u) => u.phoneNumber == request.phoneNumber)) {
      fieldErrors['phoneNumber'] = 'Account exists with phone number entered';
    }
    if (fieldErrors.isNotEmpty) {
      throw ApiException(
        'Could not create your account.',
        statusCode: 400,
        fieldErrors: fieldErrors,
      );
    }

    // Destination country is never asked for — it is inferred from the phone
    // country code, exactly as the live signup does.
    final dial = DestinationCountry.values.firstWhere(
      (c) => request.phoneNumber.startsWith(c.dialCode),
      orElse: () => DestinationCountry.ghana,
    );

    final user = WolevoUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      firstName: request.firstName.trim(),
      lastName: request.lastName.trim(),
      email: email,
      // Signup never blocks on verification.
      emailVerified: false,
      phoneNumber: request.phoneNumber,
      destinationCountry: dial,
      // A locker is assigned instantly at signup.
      lockerId: _generateLockerId(),
      accountType: AccountType.personal,
      referralCode: _generateReferralCode(),
    );

    _users[email] = user;
    _passwords[email] = request.password;
    return _establish(user);
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _session = null;
    await _storage.clear();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // Resolves regardless of whether the account exists — the success copy is
    // deliberately enumeration-safe.
    await Future<void>.delayed(_latency);
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    await Future<void>.delayed(_latency);
  }

  @override
  Future<WolevoUser> refreshUser() async {
    await Future<void>.delayed(_latency);
    final current = _session;
    if (current == null) throw ApiException.invalidCredentials;
    // Demo behaviour: "I've Already Verified" flips the flag so the verified
    // state is reachable. A real impl re-reads the user from the server.
    final updated = current.user.copyWith(emailVerified: true);
    _users[updated.email] = updated;
    _session = current.copyWith(user: updated);
    return updated;
  }

  @override
  Future<AuthSession> continueWithGoogle() async {
    await Future<void>.delayed(_latency);
    // ASSUMPTION: Google OAuth was never exercised during discovery (it would
    // have handed credentials to a real Google account), so the button is wired
    // to the seeded demo user rather than a real provider flow.
    return _establish(_users[demoEmail]!);
  }

  Future<AuthSession> _establish(WolevoUser user) async {
    final session = AuthSession(
      user: user,
      warehouseAddress: _addressFor(user),
      accessToken: 'mock.${user.id}.${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock.refresh.${user.id}',
    );
    _session = session;
    await _storage.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  static final _rng = Random();
  static const _alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  String _generateLockerId() =>
      List.generate(8, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();

  String _generateReferralCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(8, (_) => chars[_rng.nextInt(chars.length)]).join();
  }
}
