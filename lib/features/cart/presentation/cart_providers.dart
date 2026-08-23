import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/cart_models.dart';
import '../data/cart_repository.dart';
import '../data/mock_cart_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
///
/// The name is load-bearing: the product screen adds to the cart through this
/// provider, and it is the only cart symbol other features may reach for.
final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => MockCartRepository(),
);

/// Step 2's form state. Seeded from the signed-in user: the site prefills the
/// contact phone and scopes the address list to the user's destination country.
class DeliveryDetailsController extends Notifier<DeliveryDetails> {
  @override
  DeliveryDetails build() {
    final user = ref.watch(currentUserProvider);
    return DeliveryDetails(
      destinationCountry: user.destinationCountry,
      phoneNumber: user.phoneNumber,
    );
  }

  /// Changing country invalidates the picked address — the sheet only lists
  /// addresses in the selected country ("Showing addresses in Ghana").
  void setCountry(DestinationCountry country) {
    state = DeliveryDetails(
      destinationCountry: country,
      phoneNumber: state.phoneNumber,
      differentReceiver: state.differentReceiver,
      receiverName: state.receiverName,
      receiverPhone: state.receiverPhone,
      orderNotes: state.orderNotes,
    );
  }

  void setAddress(String addressId) =>
      state = state.copyWith(addressId: addressId);

  void setPhone(String phoneNumber) =>
      state = state.copyWith(phoneNumber: phoneNumber);

  void setDifferentReceiver(bool value) =>
      state = state.copyWith(differentReceiver: value);

  void setReceiverName(String value) =>
      state = state.copyWith(receiverName: value);

  void setReceiverPhone(String value) =>
      state = state.copyWith(receiverPhone: value);

  void setOrderNotes(String value) => state = state.copyWith(orderNotes: value);
}

final deliveryDetailsProvider =
    NotifierProvider<DeliveryDetailsController, DeliveryDetails>(
      DeliveryDetailsController.new,
    );

/// `GET /api/v1/carts/active`, plus the mutations the panel drives.
///
/// Rebuilds whenever the delivery country changes, mirroring the web app —
/// switching country re-requests the cart so prices come back in the new
/// currency rather than being converted on the client.
class CartController extends AsyncNotifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Future<Cart> build() {
    final country = ref.watch(
      deliveryDetailsProvider.select((d) => d.destinationCountry),
    );
    return _repo.fetch(country);
  }

  Future<void> refresh() async {
    final country = ref.read(deliveryDetailsProvider).destinationCountry;
    state = await AsyncValue.guard(() => _repo.fetch(country));
  }

  /// Keeps the current cart on screen while the mutation runs, so the list does
  /// not collapse into a spinner on every `+` tap.
  Future<void> _mutate(Future<Cart> Function() action) async {
    final previous = state.valueOrNull;
    try {
      state = AsyncValue.data(await action());
    } catch (e, st) {
      state = previous == null
          ? AsyncValue.error(e, st)
          : AsyncValue.data(previous);
      rethrow;
    }
  }

  Future<void> addItem({
    required String productId,
    required Retailer retailer,
    required String title,
    required Money unitPrice,
    required int quantity,
    String? imageUrl,
    String? variantSummary,
  }) {
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvents.addedToCart,
          properties: {
            'product_id': productId,
            'retailer': retailer.apiValue,
            'quantity': quantity,
            'unit_price_usd': unitPrice.usd,
          },
        );
    return _mutate(
      () => _repo.addItem(
        productId: productId,
        retailer: retailer,
        title: title,
        unitPrice: unitPrice,
        quantity: quantity,
        imageUrl: imageUrl,
        variantSummary: variantSummary,
      ),
    );
  }

  Future<void> updateQuantity(String itemId, int quantity) =>
      _mutate(() => _repo.updateQuantity(itemId: itemId, quantity: quantity));

  Future<void> removeItem(String itemId) =>
      _mutate(() => _repo.removeItem(itemId));

  Future<void> clear() => _mutate(_repo.clear);

  /// Throws [PromoCodeException] so the disclosure can show the error inline.
  Future<void> applyPromo(String code) =>
      _mutate(() => _repo.applyPromoCode(code));

  Future<void> removePromo() => _mutate(_repo.removePromoCode);
}

final cartProvider = AsyncNotifierProvider<CartController, Cart>(
  CartController.new,
);

/// Badge count for the header and the product screen's `View Cart (3)` button.
/// Reads 0 while the first fetch is in flight rather than flashing a stale one.
final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).valueOrNull?.itemCount ?? 0,
);

/// Drives the checkout screen's pay button and its success state. Null data is
/// "not paid yet".
class CheckoutController extends AsyncNotifier<CheckoutResult?> {
  @override
  Future<CheckoutResult?> build() async => null;

  Future<void> pay(PaymentMethod method) async {
    state = const AsyncValue.loading();
    final delivery = ref.read(deliveryDetailsProvider);
    final cart = ref.read(cartProvider).valueOrNull;
    state = await AsyncValue.guard(
      () => ref
          .read(cartRepositoryProvider)
          .checkout(delivery: delivery, method: method),
    );
    if (state.valueOrNull case final result?) {
      ref
          .read(analyticsProvider)
          .track(
            AnalyticsEvents.orderPlaced,
            properties: {
              'reference': result.orderReference,
              'method': method.apiValue,
              'total_usd': result.paidAmount.usd,
              'currency': result.paidAmount.localCurrency,
              'item_count': cart?.itemCount ?? 0,
            },
          );
      // The cart is emptied server-side by a successful checkout.
      ref.invalidate(cartProvider);
    }
  }
}

final checkoutControllerProvider =
    AsyncNotifierProvider<CheckoutController, CheckoutResult?>(
      CheckoutController.new,
    );
