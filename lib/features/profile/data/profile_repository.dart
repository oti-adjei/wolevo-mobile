import 'profile_models.dart';

/// Everything `/profile` reads and writes. Endpoints observed in discovery:
///
/// * `GET  /api/v1/addresses`                                   → [listAddresses]
/// * `GET  /api/v1/geocoding/search?query=&country=&limit=5`    → [searchCities]
/// * `GET  /api/v1/user/referrals`                              → [referrals]
///
/// The mutating calls were never exercised during discovery, so their exact
/// verbs/paths are assumptions; the interface is what the UI needs.
// ASSUMPTION: saveAddress / deleteAddress / updateProfile / setPromotionalEmails
// / changePassword / deleteAccount map to POST|PUT /addresses, DELETE
// /addresses/{id}, PATCH /user/profile, PATCH /user/preferences,
// POST /auth/change-password and DELETE /user respectively.
abstract interface class ProfileRepository {
  Future<List<SavedAddress>> listAddresses();

  /// Debounced typeahead behind step 2 of the add-address flow.
  Future<List<GeocodedPlace>> searchCities({
    required String query,
    required String countryCode,
  });

  /// Creates when [a] has an empty id, updates otherwise. Returns the stored
  /// record so the caller gets the server-assigned id back.
  Future<SavedAddress> saveAddress(SavedAddress a);

  Future<void> deleteAddress(String id);

  Future<ReferralSummary> referrals();

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  });

  Future<void> setPromotionalEmails(bool enabled);

  Future<void> changePassword({required String current, required String next});

  Future<void> deleteAccount();
}
