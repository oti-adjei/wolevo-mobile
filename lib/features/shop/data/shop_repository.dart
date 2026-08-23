import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import 'shop_models.dart';

/// The Shop data surface — one method per mode of `/shop`.
///
/// Endpoints modelled (discovery-notes.md § 2.5):
/// - browse → the default `/shop` feed (`Amazon Deals & Featured Products`,
///   `141 items`). ASSUMPTION: the exact path was not captured; the response
///   shape is the same paged listing envelope as search.
/// - search → `GET /api/v1/shop/search?keyword=&retailer=&page=` (observed).
/// - parseLink → the paste-a-link flow, which resolves a retailer URL to a
///   listing before handing off to `/shop/products/parse`.
///
/// Swap [MockShopRepository] for a Dio-backed implementation to go live; the
/// providers only ever see this interface.
abstract interface class ShopRepository {
  /// The default `/shop` view for a retailer.
  Future<Paged<ShopListing>> browse({
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination = const Pagination(),
  });

  /// `GET /shop/search?keyword=usb+c+cable&retailer=AMAZON&page=1`
  Future<Paged<ShopListing>> search({
    required String keyword,
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination = const Pagination(),
  });

  /// Resolves a pasted product URL to a listing.
  ///
  /// Throws [ShopLinkException] when the URL is malformed, carries no product
  /// id, or belongs to a store Wolevo does not support.
  Future<ShopListing> parseLink({
    required String url,
    required DestinationCountry country,
  });
}
