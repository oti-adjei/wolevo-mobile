import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';
import 'cart_models.dart';
import 'cart_repository.dart';

/// In-memory stand-in for `GET /api/v1/carts/active` and the (never observed)
/// cart mutation endpoints.
///
/// The seed is the exact cart discovery captured: three Amazon items totalling
/// **$187.68**, matching the `Estimated Total $187.68+` line in
/// `cart-desktop-items.jpg`. Titles and prices are transcribed verbatim.
///
/// Amounts are stored as USD only and minted through [Money.mock] at read time,
/// so the same cart renders in ₵ or ₦ depending on the destination the caller
/// asks for. A real client never converts — the server returns both figures.
class MockCartRepository implements CartRepository {
  MockCartRepository();

  // ASSUMPTION: matches the latency budget used by the other mock repositories.
  static const _latency = Duration(milliseconds: 500);

  /// The destination the cart was last read for. Every mutation returns a cart
  /// in this currency, so the screens stay consistent between calls.
  DestinationCountry _country = DestinationCountry.ghana;

  final List<_Line> _lines = [
    const _Line(
      id: 'ci_1',
      productId: 'B088NRLMPV',
      retailer: Retailer.amazon,
      title: 'UGREEN 10Gbps USB C to Micro B Cable 1.5FT for External Hard Drive',
      unitPriceUsd: 8.99,
      quantity: 1,
    ),
    const _Line(
      id: 'ci_2',
      productId: 'B0B3RS7B6L',
      retailer: Retailer.amazon,
      title: 'SANDISK 1TB Portable SSD - Up to 800MB/s, USB-C, USB 3.2 Gen 2, '
          'Updated Firmware - External Solid State Drive - SDSSDE30-1T00-G26',
      unitPriceUsd: 165.70,
      quantity: 1,
    ),
    const _Line(
      id: 'ci_3',
      productId: 'B0CJ2K7M4T',
      retailer: Retailer.amazon,
      title: 'Slipdrive Short USB C to USB C 3.2 Gen 2 (12 in.) - 20Gbps, SSD '
          'HDD Hard Drive Cable - Right Angle High Speed Data Transfer 4K Video '
          'Output 90 Degree 100W Fast Charging (Black)',
      unitPriceUsd: 12.99,
      quantity: 1,
    ),
  ];

  String? _promoCode;

  /// The one code the mock honours. The live apply endpoint was never captured
  /// (discovery-notes.md § "States not reached").
  // ASSUMPTION: invented — no valid promo code was observed.
  static const _validPromoCode = 'WOLEVO10';
  static const _promoRate = 0.10;

  /// Order references count up from the shape the mock uses everywhere else.
  int _nextReference = 10247;

  int _nextItemId = 4;

  Cart _buildCart() {
    // Group by retailer, preserving the order items were added in — the web
    // panel renders `Amazon (3 items)` as a single block per store.
    final byRetailer = <Retailer, List<CartItem>>{};
    for (final line in _lines) {
      byRetailer.putIfAbsent(line.retailer, () => []).add(line.toItem(_country));
    }

    final groups = [
      for (final entry in byRetailer.entries)
        CartGroup(retailer: entry.key, items: entry.value),
    ];

    final subtotalUsd = _lines.fold<double>(
      0,
      (sum, l) => sum + l.unitPriceUsd * l.quantity,
    );

    final discountUsd = _promoCode == null ? null : subtotalUsd * _promoRate;

    return Cart(
      id: 'cart_active',
      groups: groups,
      // Shipping stays null on purpose: the site renders "Calculated at
      // checkout" for both rows and shows the estimated total with a `+`.
      totals: CartTotals(
        subtotal: Money.mock(subtotalUsd, _country),
        // ASSUMPTION: with nothing else known, the estimate is the subtotal
        // (less any discount). The web shows `$187.68+` — the subtotal, marked
        // as incomplete rather than as a final figure.
        estimatedTotal: Money.mock(subtotalUsd - (discountUsd ?? 0), _country),
        discount: discountUsd == null ? null : Money.mock(discountUsd, _country),
      ),
      destinationCountry: _country,
      promoCode: _promoCode,
    );
  }

  Future<Cart> _respond() async {
    await Future<void>.delayed(_latency);
    return _buildCart();
  }

  @override
  Future<Cart> fetch(DestinationCountry country) {
    _country = country;
    return _respond();
  }

  @override
  Future<Cart> addItem({
    required String productId,
    required Retailer retailer,
    required String title,
    required Money unitPrice,
    required int quantity,
    String? imageUrl,
    String? variantSummary,
  }) {
    final existing = _lines.indexWhere(
      (l) => l.productId == productId && l.variantSummary == variantSummary,
    );

    if (existing >= 0) {
      final line = _lines[existing];
      _lines[existing] = line.copyWith(quantity: line.quantity + quantity);
    } else {
      _lines.add(
        _Line(
          id: 'ci_${_nextItemId++}',
          productId: productId,
          retailer: retailer,
          title: title,
          unitPriceUsd: unitPrice.usd,
          quantity: quantity,
          imageUrl: imageUrl,
          variantSummary: variantSummary,
        ),
      );
    }
    return _respond();
  }

  @override
  Future<Cart> updateQuantity({required String itemId, required int quantity}) {
    if (quantity <= 0) return removeItem(itemId);
    final index = _lines.indexWhere((l) => l.id == itemId);
    if (index >= 0) {
      _lines[index] = _lines[index].copyWith(quantity: quantity);
    }
    return _respond();
  }

  @override
  Future<Cart> removeItem(String itemId) {
    _lines.removeWhere((l) => l.id == itemId);
    return _respond();
  }

  @override
  Future<Cart> clear() {
    _lines.clear();
    _promoCode = null;
    return _respond();
  }

  @override
  Future<Cart> applyPromoCode(String code) async {
    await Future<void>.delayed(_latency);
    if (code.trim().toUpperCase() != _validPromoCode) {
      throw const PromoCodeException('That promo code is not valid.');
    }
    _promoCode = _validPromoCode;
    return _buildCart();
  }

  @override
  Future<Cart> removePromoCode() {
    _promoCode = null;
    return _respond();
  }

  // ASSUMPTION: checkout was never exercised during discovery — the live
  // `Checkout` button leads to a real payment flow that was deliberately not
  // clicked (discovery-notes.md § "States not reached"). Both the request shape
  // and the reference format below are invented.
  @override
  Future<CheckoutResult> checkout({
    required DeliveryDetails delivery,
    required PaymentMethod method,
  }) async {
    await Future<void>.delayed(_latency);
    final cart = _buildCart();
    final result = CheckoutResult(
      orderReference: 'WLV-${_nextReference++}',
      paidAmount: cart.totals.estimatedTotal,
      method: method,
    );
    // A real checkout empties the active cart and opens a fulfillment.
    _lines.clear();
    _promoCode = null;
    return result;
  }
}

/// A stored cart line. Holds USD only; the destination amount is minted per
/// read so switching country never leaves a stale conversion behind.
class _Line {
  const _Line({
    required this.id,
    required this.productId,
    required this.retailer,
    required this.title,
    required this.unitPriceUsd,
    required this.quantity,
    this.imageUrl,
    this.variantSummary,
  });

  final String id;
  final String productId;
  final Retailer retailer;
  final String title;
  final double unitPriceUsd;
  final int quantity;
  final String? imageUrl;
  final String? variantSummary;

  _Line copyWith({int? quantity}) => _Line(
        id: id,
        productId: productId,
        retailer: retailer,
        title: title,
        unitPriceUsd: unitPriceUsd,
        quantity: quantity ?? this.quantity,
        imageUrl: imageUrl,
        variantSummary: variantSummary,
      );

  CartItem toItem(DestinationCountry country) => CartItem(
        id: id,
        productId: productId,
        retailer: retailer,
        title: title,
        unitPrice: Money.mock(unitPriceUsd, country),
        quantity: quantity,
        imageUrl: imageUrl,
        variantSummary: variantSummary,
      );
}
