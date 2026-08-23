import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/network/api_exception.dart';
import 'calculator_models.dart';
import 'calculator_repository.dart';

/// In-memory stand-in for `POST /api/v1/public/shipping-estimate`.
///
/// Swap `calculatorRepositoryProvider` for a Dio-backed implementation to go
/// live; nothing in the UI changes.
class MockCalculatorRepository implements CalculatorRepository {
  /// Host fragments the calculator accepts, mirroring the helper text under the
  /// `PRODUCT LINK` field: "Supported: Amazon, eBay, Fashion Nova, Plug Tech,
  /// Best Buy, and Sephora".
  static const _supportedHosts = <String>[
    'amazon',
    'ebay',
    'fashionnova',
    'plugtech',
    'bestbuy',
    'sephora',
  ];

  static const unsupportedLinkMessage =
      "That link isn't from a supported store. Try Amazon, eBay, Fashion Nova, "
      'Plug Tech, Best Buy or Sephora.';

  /// ASSUMPTION — the exact pricing curve is server-side and, per
  /// `/pricing` ("Most items are priced by weight"), almost certainly banded by
  /// weight with per-category overrides for electronics, fragrances and
  /// lithium batteries. Discovery captured exactly one real data point:
  ///
  ///     2 lbs → Ghana = $20.00 / GHS 244.00
  ///
  /// So this mock uses the simplest linear curve that reproduces it:
  ///
  ///     shipping = $6 base + $7 per billable pound
  ///     2 lbs → 6 + 14 = $20.00 ✓
  ///
  /// Do not treat these constants as real pricing.
  static const _baseUsd = 6.0;
  static const _perPoundUsd = 7.0;

  @override
  Future<ShippingEstimate> estimate(ShippingEstimateRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final destination = DestinationCountry.fromCode(
      request.destinationCountryCode,
    );

    return switch (request.mode) {
      EstimateMode.link => _estimateFromLink(request, destination),
      EstimateMode.weight => _estimateFromWeight(request, destination),
    };
  }

  ShippingEstimate _estimateFromLink(
    ShippingEstimateRequest request,
    DestinationCountry destination,
  ) {
    final url = (request.productUrl ?? '').trim();
    final normalised = url.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (url.isEmpty || !_supportedHosts.any(normalised.contains)) {
      throw const ApiException(unsupportedLinkMessage, statusCode: 422);
    }

    // The real endpoint parses the listing to read its shipping weight. Here the
    // URL hash stands in for that lookup, so the same link always quotes the
    // same price: a stable 0.5–8.0 lb weight.
    final hash = url.hashCode.abs();
    final weightLbs = _round1(0.5 + (hash % 76) / 10);

    return ShippingEstimate(
      shipping: Money.mock(_price(weightLbs), destination),
      destination: destination,
      productTitle: _titleFor(normalised, hash),
      billableWeightLbs: weightLbs,
    );
  }

  ShippingEstimate _estimateFromWeight(
    ShippingEstimateRequest request,
    DestinationCountry destination,
  ) {
    final unit = request.weightUnit ?? WeightUnit.lbs;
    final actualLbs = unit.toLbs(request.weight ?? 0);

    // ASSUMPTION: dimensions are optional on the form and described as helping
    // accuracy, which is how carriers describe dimensional (volumetric) weight.
    // Standard air divisor is 139 for in³ / 5000 for cm³; the greater of actual
    // and dimensional weight is billed.
    var billable = actualLbs;
    if (request.hasDimensions) {
      final l = request.length!;
      final w = request.width!;
      final h = request.height!;
      final dimLbs = request.dimensionUnit == DimensionUnit.inch
          ? (l * w * h) / 139
          : (l * w * h) / 5000 * 2.20462;
      if (dimLbs > billable) billable = dimLbs;
    }

    final billableLbs = _round1(billable);
    return ShippingEstimate(
      shipping: Money.mock(_price(billableLbs), destination),
      destination: destination,
      billableWeightLbs: billableLbs,
    );
  }

  /// $6 base + $7/lb, rounded to whole cents.
  double _price(double billableLbs) =>
      ((_baseUsd + _perPoundUsd * billableLbs) * 100).roundToDouble() / 100;

  double _round1(double value) => (value * 10).roundToDouble() / 10;

  String _titleFor(String normalisedUrl, int hash) {
    final store = switch (normalisedUrl) {
      _ when normalisedUrl.contains('amazon') => 'Amazon',
      _ when normalisedUrl.contains('ebay') => 'eBay',
      _ when normalisedUrl.contains('fashionnova') => 'Fashion Nova',
      _ when normalisedUrl.contains('plugtech') => 'Plug Tech',
      _ when normalisedUrl.contains('bestbuy') => 'Best Buy',
      _ => 'Sephora',
    };
    const items = [
      'Wireless Earbuds',
      'Running Sneakers',
      'Cotton Hoodie',
      'Bluetooth Speaker',
      'Skincare Set',
      'Laptop Sleeve',
    ];
    return '${items[hash % items.length]} · $store';
  }
}
