import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';

/// The calculator card has two tabs: `Paste a Link` and `Enter Weight`
/// (discovery-notes.md § 2.9). Both post to the same public endpoint.
enum EstimateMode { link, weight }

/// Unit selector next to the `WEIGHT` field.
enum WeightUnit {
  lbs('lbs'),
  kg('kg');

  const WeightUnit(this.label);

  final String label;

  /// The mock pricing model is expressed per pound, so kg inputs are
  /// normalised before the formula runs.
  double toLbs(double value) => this == WeightUnit.lbs ? value : value * 2.20462;
}

/// Unit selector under `DIMENSIONS (optional)`.
enum DimensionUnit {
  cm('cm'),
  inch('in');

  const DimensionUnit(this.label);

  final String label;
}

/// Request body for `POST /api/v1/public/shipping-estimate`.
///
/// ASSUMPTION: discovery captured the endpoint and the form, but never the
/// payload verbatim (discovery-notes.md § 2.9 "payload shape not captured
/// verbatim"). Field names below are inferred from the rest of the API, which
/// consistently uses camelCase and `destinationCountryCode` (see
/// `/shop/products/parse`). Dimensions are nested because the notes describe
/// them that way: `dimensions?: {l,w,h,unit}`.
class ShippingEstimateRequest {
  const ShippingEstimateRequest({
    required this.destinationCountryCode,
    required this.mode,
    this.productUrl,
    this.weight,
    this.weightUnit,
    this.length,
    this.width,
    this.height,
    this.dimensionUnit,
  });

  final String destinationCountryCode;
  final EstimateMode mode;

  /// Link mode only.
  final String? productUrl;

  /// Weight mode only.
  final double? weight;
  final WeightUnit? weightUnit;

  /// Weight mode, optional.
  final double? length;
  final double? width;
  final double? height;
  final DimensionUnit? dimensionUnit;

  bool get hasDimensions => length != null && width != null && height != null;

  Map<String, dynamic> toJson() => {
        'destinationCountryCode': destinationCountryCode,
        // ASSUMPTION: the server distinguishes the two tabs by an explicit
        // mode discriminator rather than by which fields are present.
        'mode': mode.name.toUpperCase(),
        if (productUrl != null) 'productUrl': productUrl,
        if (weight != null) 'weight': weight,
        if (weightUnit != null) 'weightUnit': weightUnit!.label,
        if (hasDimensions)
          'dimensions': {
            'length': length,
            'width': width,
            'height': height,
            'unit': dimensionUnit?.label ?? DimensionUnit.cm.label,
          },
      };
}

/// Response body. The result card shows a USD figure and the destination
/// currency figure side by side — both arrive from the server, the client never
/// converts (see `Money`).
class ShippingEstimate {
  const ShippingEstimate({
    required this.shipping,
    required this.destination,
    this.productTitle,
    this.billableWeightLbs,
  });

  final Money shipping;
  final DestinationCountry destination;

  /// Link mode only — the parsed product name, so the card can name the item.
  final String? productTitle;

  /// What the quote was actually priced on, after any dimensional-weight
  /// adjustment.
  final double? billableWeightLbs;

  factory ShippingEstimate.fromJson(Map<String, dynamic> json) => ShippingEstimate(
        shipping: Money.fromJson(json['shipping'] as Map<String, dynamic>),
        destination:
            DestinationCountry.fromCode(json['destinationCountryCode'] as String),
        productTitle: json['productTitle'] as String?,
        billableWeightLbs: (json['billableWeightLbs'] as num?)?.toDouble(),
      );
}
