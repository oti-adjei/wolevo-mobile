import '../../../core/models/destination_country.dart';
import '../../../core/models/retailer.dart';
import 'product_models.dart';

/// The Product data surface.
///
/// Endpoint modelled (observed verbatim, discovery-notes.md § 2.6):
/// `GET /api/v1/shop/products/parse?retailer=AMAZON&productId=B088NRLMPV
/// &destinationCountryCode=GH`
///
/// `destinationCountryCode` is what makes the response carry the local-currency
/// price and the `Ship to Ghana for $2.09` line, so it is required rather than
/// optional. Swap [MockProductRepository] for a Dio-backed implementation to go
/// live; the providers only ever see this interface.
abstract interface class ProductRepository {
  Future<ProductDetail> parse({
    required String productId,
    required Retailer retailer,
    required DestinationCountry destinationCountry,
  });
}
