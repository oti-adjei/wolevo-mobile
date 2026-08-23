import '../../../core/network/api_exception.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

/// In-memory [ProfileRepository]. Seeds the exact record discovery observed on
/// the live account so the screens render real copy, not lorem.
class MockProfileRepository implements ProfileRepository {
  MockProfileRepository();

  static const _latency = Duration(milliseconds: 500);

  final List<SavedAddress> _addresses = [
    const SavedAddress(
      id: 'addr_1',
      countryCode: 'GH',
      city: 'Accra',
      region: 'Greater Accra',
      streetAddress: '8 Bia Rd',
      nearestLandmark: 'Near Omanye Lodge',
      isPrimary: true,
    ),
  ];

  int _nextId = 2;

  Future<void> _wait() => Future<void>.delayed(_latency);

  @override
  Future<List<SavedAddress>> listAddresses() async {
    await _wait();
    // Primary first, mirroring the web ordering.
    final sorted = [..._addresses]
      ..sort((a, b) => (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0));
    return sorted;
  }

  @override
  Future<List<GeocodedPlace>> searchCities({
    required String query,
    required String countryCode,
  }) async {
    await _wait();
    final q = query.trim();
    if (q.isEmpty) return const [];

    final country = _countryOf(countryCode);
    final regions = _regionsFor(countryCode);
    final cased = _titleCase(q);

    // A plausible geocoder: the query itself in the country's capital region,
    // plus a couple of "<query> <suffix>" variants in other regions — which is
    // what `Accra` returned live ("Accra, Greater Accra" + "Accra Village,
    // Eastern").
    final variants = <(String, String)>[
      (cased, regions.first),
      if (regions.length > 1) ('$cased Village', regions[1]),
      if (regions.length > 2) ('$cased New Town', regions[2]),
    ];

    return variants
        .take(5)
        .map(
          (v) => GeocodedPlace(
            city: v.$1,
            region: v.$2,
            countryCode: country.$1,
            countryName: country.$2,
            flag: country.$3,
          ),
        )
        .toList();
  }

  @override
  Future<SavedAddress> saveAddress(SavedAddress a) async {
    await _wait();
    final saved = a.id.isEmpty ? a.copyWith(id: 'addr_${_nextId++}') : a;

    if (saved.isPrimary) {
      for (var i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isPrimary: false);
      }
    }

    final index = _addresses.indexWhere((x) => x.id == saved.id);
    if (index == -1) {
      // The very first address is always primary, whatever the checkbox says.
      _addresses.add(
        _addresses.isEmpty ? saved.copyWith(isPrimary: true) : saved,
      );
    } else {
      _addresses[index] = saved;
    }
    return saved;
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _wait();
    final removed = _addresses.indexWhere((a) => a.id == id);
    if (removed == -1) {
      throw const ApiException(
        'That address no longer exists.',
        statusCode: 404,
      );
    }
    final wasPrimary = _addresses[removed].isPrimary;
    _addresses.removeAt(removed);
    if (wasPrimary && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isPrimary: true);
    }
  }

  @override
  Future<ReferralSummary> referrals() async {
    await _wait();
    // The live account showed a code with zero activity.
    const code = 'DEMOREF1';
    return const ReferralSummary(
      code: code,
      link: 'https://www.wolevo.com/?ref=$code',
      entries: [],
    );
  }

  @override
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) async {
    await _wait();
  }

  @override
  Future<void> setPromotionalEmails(bool enabled) async {
    await _wait();
  }

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) async {
    await _wait();
    // ASSUMPTION: the API rejects a wrong current password with a 400; the mock
    // uses the demo account's password so the error path is demoable.
    if (current != 'Password1!') {
      throw const ApiException(
        'Your current password is incorrect.',
        statusCode: 400,
        fieldErrors: {'current': 'Your current password is incorrect.'},
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    await _wait();
  }

  /// (code, name, flag) for the two deliverable countries; anything else keeps
  /// the code and shows a globe.
  (String, String, String) _countryOf(String code) =>
      switch (code.toUpperCase()) {
        'GH' => ('GH', 'Ghana', '🇬🇭'),
        'NG' => ('NG', 'Nigeria', '🇳🇬'),
        final other => (other, other, '🌍'),
      };

  List<String> _regionsFor(String code) => switch (code.toUpperCase()) {
    'GH' => const ['Greater Accra', 'Eastern', 'Ashanti', 'Central'],
    'NG' => const ['Lagos', 'Ogun', 'Abuja FCT', 'Rivers'],
    _ => const ['Region'],
  };

  String _titleCase(String v) => v
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}
