import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

import '../../../core/models/destination_country.dart';
import '../../../core/models/retailer.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/mock_product_repository.dart';
import '../data/product_models.dart';
import '../data/product_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => const MockProductRepository(),
);

/// `destinationCountryCode` on the parse endpoint — it drives both the local
/// price and the `Ship to Ghana for $2.09` line, so the detail refetches when
/// the user's country changes.
final productDestinationProvider = Provider<DestinationCountry>(
  (ref) => ref.watch(currentUserProvider).destinationCountry,
);

/// The route's two query params, as one key for the family.
typedef ProductArgs = ({String productId, Retailer retailer});

/// One parsed product. Variant picks are applied locally: the site swaps
/// swatches without a round trip, and the price only changes when the retailer
/// says so.
///
// ASSUMPTION: a real implementation would re-parse when a variant that changes
// the ASIN is picked. Nothing in discovery showed a price moving on a swatch
// tap, so the mock keeps the same product and only moves the selection.
class ProductDetailController
    extends FamilyAsyncNotifier<ProductDetail, ProductArgs> {
  @override
  Future<ProductDetail> build(ProductArgs arg) async {
    final country = ref.watch(productDestinationProvider);
    final product = await ref
        .read(productRepositoryProvider)
        .parse(
          productId: arg.productId,
          retailer: arg.retailer,
          destinationCountry: country,
        );

    // Fired here rather than in the screen's initState: this runs once per
    // load, so a rebuild cannot double-count a view.
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvents.productViewed,
          properties: {
            'product_id': product.productId,
            'retailer': product.retailer.apiValue,
            'price_usd': product.price.usd,
            'in_stock': product.inStock,
            'destination': country.code,
          },
        );

    return product;
  }

  void selectVariant({required String groupName, required String optionId}) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.selectVariant(groupName: groupName, optionId: optionId),
    );
  }
}

final productDetailProvider =
    AsyncNotifierProvider.family<
      ProductDetailController,
      ProductDetail,
      ProductArgs
    >(ProductDetailController.new);

/// Quantity for the sticky action bar. Keyed by product so backing out of one
/// product and into another does not carry the count over.
class ProductQuantityController extends FamilyNotifier<int, ProductArgs> {
  static const max = 20;

  @override
  int build(ProductArgs arg) => 1;

  void increment() {
    if (state >= max) return;
    state = state + 1;
  }

  void decrement() {
    if (state <= 1) return;
    state = state - 1;
  }

  void reset() => state = 1;
}

final productQuantityProvider =
    NotifierProvider.family<ProductQuantityController, int, ProductArgs>(
      ProductQuantityController.new,
    );
