import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/mock_profile_repository.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => MockProfileRepository(),
);

/// The five sections the web app switches with `?section=`. On a phone these
/// become a horizontally scrollable tab strip (see [ProfileScreen]).
enum ProfileSection {
  profile('Profile'),
  addresses('Addresses'),
  referrals('Referrals'),
  settings('Settings'),
  support('Support');

  const ProfileSection(this.label);

  final String label;
}

final profileSectionProvider = StateProvider<ProfileSection>(
  (ref) => ProfileSection.profile,
);

/// `GET /api/v1/addresses`.
class SavedAddressesController extends AsyncNotifier<List<SavedAddress>> {
  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  @override
  Future<List<SavedAddress>> build() => _repo.listAddresses();

  Future<void> refresh() async {
    state = await AsyncValue.guard(_repo.listAddresses);
  }

  Future<void> save(SavedAddress address) async {
    await _repo.saveAddress(address);
    await refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteAddress(id);
    await refresh();
  }
}

final savedAddressesProvider =
    AsyncNotifierProvider<SavedAddressesController, List<SavedAddress>>(
      SavedAddressesController.new,
    );

/// `GET /api/v1/user/referrals`. Falls back to the signed-in user's own code if
/// the endpoint ever returns a blank one.
final referralsProvider = FutureProvider<ReferralSummary>((ref) async {
  final summary = await ref.watch(profileRepositoryProvider).referrals();
  if (summary.code.isNotEmpty) return summary;
  final code = ref.read(currentUserProvider).referralCode;
  return ReferralSummary(code: code, link: 'https://www.wolevo.com/?ref=$code');
});

/// Debounced city typeahead for step 2 of the add-address flow.
///
/// The web app debounces the request as the user types (an OPTIONS preflight
/// per keystroke pause was observed); 350ms matches the app's other typeaheads.
class CitySearchState {
  const CitySearchState({
    this.query = '',
    this.countryCode = 'GH',
    this.results = const [],
    this.loading = false,
    this.errorMessage,
  });

  final String query;
  final String countryCode;
  final List<GeocodedPlace> results;
  final bool loading;
  final String? errorMessage;

  CitySearchState copyWith({
    String? query,
    String? countryCode,
    List<GeocodedPlace>? results,
    bool? loading,
    String? errorMessage,
  }) {
    return CitySearchState(
      query: query ?? this.query,
      countryCode: countryCode ?? this.countryCode,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      errorMessage: errorMessage,
    );
  }
}

class CitySearchController extends AutoDisposeNotifier<CitySearchState> {
  Timer? _debounce;

  /// Guards a slow response for an abandoned query from overwriting a newer one.
  int _requestId = 0;

  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  CitySearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const CitySearchState();
  }

  void setCountry(String countryCode) {
    _debounce?.cancel();
    _requestId++;
    state = CitySearchState(countryCode: countryCode);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().length < 2) {
      _requestId++;
      state = state.copyWith(results: const [], loading: false);
      return;
    }
    state = state.copyWith(loading: true);
    _debounce = Timer(_debounceDuration, _run);
  }

  Future<void> _run() async {
    final id = ++_requestId;
    final query = state.query;
    final country = state.countryCode;
    try {
      final results = await ref
          .read(profileRepositoryProvider)
          .searchCities(query: query, countryCode: country);
      if (id != _requestId) return;
      state = state.copyWith(results: results, loading: false);
    } catch (e) {
      if (id != _requestId) return;
      state = state.copyWith(
        results: const [],
        loading: false,
        errorMessage: '$e',
      );
    }
  }
}

final citySearchProvider =
    AutoDisposeNotifierProvider<CitySearchController, CitySearchState>(
      CitySearchController.new,
    );
