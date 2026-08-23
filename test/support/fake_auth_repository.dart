import 'package:wolevo/core/models/destination_country.dart';
import 'package:wolevo/features/auth/data/auth_models.dart';
import 'package:wolevo/features/auth/data/auth_repository.dart';

/// Synchronous auth double so widget tests can render authenticated screens
/// without waiting on the mock repository's simulated latency.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository._(this._session);

  factory FakeAuthRepository.signedIn() => FakeAuthRepository._(_demoSession);
  factory FakeAuthRepository.signedOut() => FakeAuthRepository._(null);

  AuthSession? _session;

  static const _user = WolevoUser(
    id: 'usr_test',
    firstName: 'Demo',
    lastName: 'User',
    email: 'demo@wolevo.com',
    emailVerified: true,
    phoneNumber: '+233200000000',
    destinationCountry: DestinationCountry.ghana,
    lockerId: 'DEMO1234',
    accountType: AccountType.personal,
    referralCode: 'DEMOREF1',
  );

  static const _address = WarehouseAddress(
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

  static const _demoSession = AuthSession(
    user: _user,
    warehouseAddress: _address,
    accessToken: 'test-token',
  );

  @override
  Future<AuthSession?> restore() async => _session;

  @override
  Future<AuthSession> login(LoginRequest request) async => _demoSession;

  @override
  Future<AuthSession> register(RegisterRequest request) async => _demoSession;

  @override
  Future<AuthSession> continueWithGoogle() async => _demoSession;

  @override
  Future<void> logout() async => _session = null;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> resendVerificationEmail(String email) async {}

  @override
  Future<WolevoUser> refreshUser() async => _user;
}
