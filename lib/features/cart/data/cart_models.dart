import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';

/// One line in the cart. `GET /api/v1/carts/active` returns items grouped by
/// retailer, each carrying the retailer's own price in USD plus the
/// server-converted local amount.
class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.retailer,
    required this.title,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.variantSummary,
  });

  final String id;
  final String productId;
  final Retailer retailer;
  final String title;
  final Money unitPrice;
  final int quantity;
  final String? imageUrl;

  /// e.g. `6FT*2 · Black` — the picked variant options, flattened for display.
  final String? variantSummary;

  Money get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        retailer: retailer,
        title: title,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
        variantSummary: variantSummary,
      );

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productId: json['productId'] as String,
        retailer: Retailer.fromApi(json['retailer'] as String),
        title: json['title'] as String,
        unitPrice: Money.fromJson(json['unitPrice'] as Map<String, dynamic>),
        quantity: json['quantity'] as int,
        imageUrl: json['imageUrl'] as String?,
        variantSummary: json['variantSummary'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'retailer': retailer.apiValue,
        'title': title,
        'unitPrice': unitPrice.toJson(),
        'quantity': quantity,
        'imageUrl': imageUrl,
        'variantSummary': variantSummary,
      };
}

/// Items sharing a retailer. The cart screen renders one group per store, with
/// the store's name and item count as a header.
class CartGroup {
  const CartGroup({required this.retailer, required this.items});

  final Retailer retailer;
  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);
}

/// The cart's money. Shipping figures stay null until checkout computes them —
/// the UI renders "Calculated at checkout" in their place, exactly like the web
/// app does.
class CartTotals {
  const CartTotals({
    required this.subtotal,
    required this.estimatedTotal,
    this.retailerShipping,
    this.shippingToDestination,
    this.discount,
  });

  final Money subtotal;

  /// Subtotal plus whatever is already known. The web app renders this with a
  /// trailing `+` while shipping is still unknown.
  final Money estimatedTotal;

  final Money? retailerShipping;
  final Money? shippingToDestination;
  final Money? discount;

  bool get hasPendingCosts =>
      retailerShipping == null || shippingToDestination == null;
}

/// `GET /api/v1/carts/active`
class Cart {
  const Cart({
    required this.id,
    required this.groups,
    required this.totals,
    required this.destinationCountry,
    this.promoCode,
  });

  final String id;
  final List<CartGroup> groups;
  final CartTotals totals;
  final DestinationCountry destinationCountry;
  final String? promoCode;

  List<CartItem> get allItems => [for (final g in groups) ...g.items];

  int get itemCount => groups.fold(0, (sum, g) => sum + g.itemCount);

  bool get isEmpty => itemCount == 0;
}

/// Where a delivery is going, plus who receives it. Mirrors the cart's step 2.
class DeliveryDetails {
  const DeliveryDetails({
    required this.destinationCountry,
    this.addressId,
    this.phoneNumber,
    this.differentReceiver = false,
    this.receiverName,
    this.receiverPhone,
    this.orderNotes,
  });

  final DestinationCountry destinationCountry;
  final String? addressId;
  final String? phoneNumber;

  /// "Different receiver? (optional) — Check this if someone else will receive
  /// the delivery."
  final bool differentReceiver;
  final String? receiverName;
  final String? receiverPhone;
  final String? orderNotes;

  bool get isValid => addressId != null && (phoneNumber?.isNotEmpty ?? false);

  DeliveryDetails copyWith({
    DestinationCountry? destinationCountry,
    String? addressId,
    String? phoneNumber,
    bool? differentReceiver,
    String? receiverName,
    String? receiverPhone,
    String? orderNotes,
  }) {
    return DeliveryDetails(
      destinationCountry: destinationCountry ?? this.destinationCountry,
      addressId: addressId ?? this.addressId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      differentReceiver: differentReceiver ?? this.differentReceiver,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      orderNotes: orderNotes ?? this.orderNotes,
    );
  }

  Map<String, dynamic> toJson() => {
        'destinationCountryCode': destinationCountry.code,
        'addressId': addressId,
        'phoneNumber': phoneNumber,
        'differentReceiver': differentReceiver,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'orderNotes': orderNotes,
      };
}

/// ASSUMPTION: checkout was never exercised during discovery — the Checkout
/// button leads to a real payment flow that was deliberately not clicked (see
/// discovery-notes.md § "States not reached"). The three rails below are the
/// ones the product page advertises: Visa/Mastercard, Mobile Money and Bank
/// Transfer.
enum PaymentMethod {
  card('CARD', 'Card', 'Visa or Mastercard'),
  mobileMoney('MOBILE_MONEY', 'Mobile Money', 'MTN, Telecel, AirtelTigo'),
  bankTransfer('BANK_TRANSFER', 'Bank Transfer', 'Pay from your bank app');

  const PaymentMethod(this.apiValue, this.label, this.subtitle);

  final String apiValue;
  final String label;
  final String subtitle;
}

/// What a completed checkout returns. ASSUMPTION: inferred, as above.
class CheckoutResult {
  const CheckoutResult({
    required this.orderReference,
    required this.paidAmount,
    required this.method,
  });

  final String orderReference;
  final Money paidAmount;
  final PaymentMethod method;
}

/// Raised when a promo code is rejected, so the cart can show it inline.
class PromoCodeException implements Exception {
  const PromoCodeException(this.message);

  final String message;

  @override
  String toString() => message;
}
