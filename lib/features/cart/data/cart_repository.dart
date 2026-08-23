import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';
import 'cart_models.dart';

/// The cart's data contract.
///
/// This is the one interface other features are allowed to reach for: the
/// product screen adds to the cart through [addItem], and Home badges the tab
/// from [fetch]. Nothing outside this feature touches the cart's widgets or
/// notifiers.
///
/// Endpoint modelled: `GET /api/v1/carts/active`. The mutation endpoints were
/// never observed (discovery only captured the read), so their paths are
/// inferred and marked where implemented.
abstract interface class CartRepository {
  Future<Cart> fetch(DestinationCountry country);

  /// Adds a product, or bumps the quantity when the same product+variant is
  /// already in the cart.
  Future<Cart> addItem({
    required String productId,
    required Retailer retailer,
    required String title,
    required Money unitPrice,
    required int quantity,
    String? imageUrl,
    String? variantSummary,
  });

  Future<Cart> updateQuantity({required String itemId, required int quantity});

  Future<Cart> removeItem(String itemId);

  /// The cart header's `Clear List` action.
  Future<Cart> clear();

  /// Throws [PromoCodeException] when the code is not valid.
  Future<Cart> applyPromoCode(String code);

  Future<Cart> removePromoCode();

  /// ASSUMPTION: the payment flow was never exercised during discovery.
  Future<CheckoutResult> checkout({
    required DeliveryDetails delivery,
    required PaymentMethod method,
  });
}
