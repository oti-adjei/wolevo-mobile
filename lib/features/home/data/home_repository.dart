import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import 'home_models.dart';

/// The Home data surface. Two endpoints back it today:
///
/// * `GET /api/v1/shop/homepage-deals` → [fetchFeed]
/// * `GET /api/v1/shop/search?keyword=&retailer=&page=` → [search]
///
/// Swap [MockHomeRepository] for a Dio-backed implementation to go live; the
/// providers only ever see this interface.
abstract interface class HomeRepository {
  /// Prices come back pre-converted into the user's destination currency, so
  /// the country is a request parameter (`destinationCountryCode`), never a
  /// client-side conversion.
  Future<HomeFeed> fetchFeed(DestinationCountry country);

  Future<List<DealProduct>> search({
    required String query,
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination,
  });
}
