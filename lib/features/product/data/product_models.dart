import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';

/// How a variant option is rendered. The web app draws `Size` and
/// `NumberOfItems` as text swatches and `Color` as image swatches
/// (discovery-notes.md § 2.6).
enum VariantOptionKind {
  /// A labelled pill — `6FT*2`, `4`.
  text,

  /// A colour swatch. The live site uses the retailer's own thumbnail; with no
  /// reachable imagery the app draws the named colour instead.
  color;

  static VariantOptionKind fromApi(String? value) =>
      value?.toUpperCase() == 'COLOR' ? VariantOptionKind.color : VariantOptionKind.text;
}

class VariantOption {
  const VariantOption({
    required this.id,
    required this.label,
    this.selected = false,
    this.kind = VariantOptionKind.text,
    this.available = true,
  });

  final String id;
  final String label;
  final bool selected;
  final VariantOptionKind kind;

  /// ASSUMPTION: retailers grey out combinations they cannot fulfil. Never
  /// observed live, so every seeded option is available.
  final bool available;

  VariantOption copyWith({bool? selected}) => VariantOption(
        id: id,
        label: label,
        selected: selected ?? this.selected,
        kind: kind,
        available: available,
      );

  factory VariantOption.fromJson(Map<String, dynamic> json) => VariantOption(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        selected: json['selected'] as bool? ?? false,
        kind: VariantOptionKind.fromApi(json['kind'] as String?),
        available: json['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'selected': selected,
        'kind': kind.name.toUpperCase(),
        'available': available,
      };
}

/// One picker. The group names come straight from the retailer's own product
/// dimensions, which is why they arrive in the retailer's casing
/// (`Size`, `Color`, `NumberOfItems`).
class VariantGroup {
  const VariantGroup({required this.name, required this.options});

  final String name;
  final List<VariantOption> options;

  VariantOption? get selectedOption {
    for (final o in options) {
      if (o.selected) return o;
    }
    return null;
  }

  /// `NumberOfItems` → `Number Of Items`. The site prints the raw key; a phone
  /// has less room, so the label is spaced out for legibility.
  String get displayName =>
      name.replaceAllMapped(RegExp(r'(?<=[a-z])(?=[A-Z])'), (_) => ' ');

  VariantGroup select(String optionId) => VariantGroup(
        name: name,
        options: [
          for (final o in options) o.copyWith(selected: o.id == optionId),
        ],
      );

  factory VariantGroup.fromJson(Map<String, dynamic> json) => VariantGroup(
        name: json['name'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? const [])
            .map((e) => VariantOption.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'options': options.map((o) => o.toJson()).toList(),
      };
}

/// What it costs to get the item from the store to the buyer's door.
///
/// Drives the site's two-row pale-lime callout: **Store Shipping — Free
/// Shipping to our US Warehouse** and **To Your Door — Ship to Ghana for
/// $2.09**. `destinationCountryCode` on the parse endpoint is what makes the
/// second line name a country.
class LandedCost {
  const LandedCost({
    required this.storeShipping,
    required this.toYourDoor,
    required this.destination,
  });

  /// The retailer's own shipping to Wolevo's Delaware warehouse. Zero on every
  /// item observed, which is what produces the "Free Shipping" copy.
  final Money storeShipping;

  /// Wolevo's leg: US warehouse → the buyer's destination country.
  final Money toYourDoor;

  final DestinationCountry destination;

  bool get shipsFreeToWarehouse => storeShipping.usd == 0;

  /// `Free Shipping to our US Warehouse` / `${'$'}4.50 to our US Warehouse`
  String get storeShippingLabel => shipsFreeToWarehouse
      ? 'Free Shipping to our US Warehouse'
      : '${storeShipping.usdLabel} to our US Warehouse';

  /// `Ship to Ghana for $2.09`
  String get toYourDoorLabel =>
      'Ship to ${destination.name} for ${toYourDoor.usdLabel}';

  factory LandedCost.fromJson(Map<String, dynamic> json) => LandedCost(
        storeShipping: Money.fromJson(json['storeShipping'] as Map<String, dynamic>),
        toYourDoor: Money.fromJson(json['toYourDoor'] as Map<String, dynamic>),
        destination: DestinationCountry.fromCode(
          json['destinationCountryCode'] as String? ?? 'GH',
        ),
      );

  Map<String, dynamic> toJson() => {
        'storeShipping': storeShipping.toJson(),
        'toYourDoor': toYourDoor.toJson(),
        'destinationCountryCode': destination.code,
      };
}

/// `GET /api/v1/shop/products/parse?retailer=AMAZON&productId=B088NRLMPV
/// &destinationCountryCode=GH`
class ProductDetail {
  const ProductDetail({
    required this.productId,
    required this.retailer,
    required this.title,
    required this.seller,
    required this.brand,
    required this.condition,
    required this.images,
    required this.price,
    required this.inStock,
    required this.landedCost,
    this.wasPrice,
    this.variantGroups = const [],
    this.highlights = const [],
    this.dimensions = const {},
  });

  final String productId;
  final Retailer retailer;
  final String title;

  /// `Amazon (FBA)` — who actually fulfils the item.
  final String seller;

  final String brand;

  /// `New`, `Renewed`, `Used - Very Good`.
  final String condition;

  /// Gallery URLs, in order. Empty in mock data — the gallery falls back to a
  /// deterministic placeholder per slot.
  final List<String> images;

  final Money price;
  final Money? wasPrice;
  final bool inStock;
  final LandedCost landedCost;
  final List<VariantGroup> variantGroups;

  /// The `Product Highlights` bullets.
  final List<String> highlights;

  /// The `Dimensions & Weight` rows, in insertion order.
  final Map<String, String> dimensions;

  bool get isDiscounted => wasPrice != null && wasPrice!.usd > price.usd;

  /// `6FT*2 · Black · 2` — the picked options, flattened for the cart line.
  String? get variantSummary {
    final picked = [
      for (final g in variantGroups)
        if (g.selectedOption != null) g.selectedOption!.label,
    ];
    return picked.isEmpty ? null : picked.join(' · ');
  }

  /// Applies a pick to one group, leaving the others untouched.
  ProductDetail selectVariant({required String groupName, required String optionId}) {
    return copyWith(
      variantGroups: [
        for (final g in variantGroups)
          if (g.name == groupName) g.select(optionId) else g,
      ],
    );
  }

  ProductDetail copyWith({List<VariantGroup>? variantGroups}) => ProductDetail(
        productId: productId,
        retailer: retailer,
        title: title,
        seller: seller,
        brand: brand,
        condition: condition,
        images: images,
        price: price,
        wasPrice: wasPrice,
        inStock: inStock,
        landedCost: landedCost,
        variantGroups: variantGroups ?? this.variantGroups,
        highlights: highlights,
        dimensions: dimensions,
      );

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
        productId: json['productId'] as String,
        retailer: Retailer.fromApi(json['retailer'] as String? ?? 'AMAZON'),
        title: json['title'] as String? ?? '',
        seller: json['seller'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        condition: json['condition'] as String? ?? 'New',
        images: (json['images'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        price: Money.fromJson(json['price'] as Map<String, dynamic>),
        wasPrice: json['wasPrice'] == null
            ? null
            : Money.fromJson(json['wasPrice'] as Map<String, dynamic>),
        inStock: json['inStock'] as bool? ?? true,
        landedCost: LandedCost.fromJson(json['landedCost'] as Map<String, dynamic>),
        variantGroups: (json['variantGroups'] as List<dynamic>? ?? const [])
            .map((e) => VariantGroup.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        highlights: (json['highlights'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(growable: false),
        dimensions: (json['dimensions'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, '$v')),
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'retailer': retailer.apiValue,
        'title': title,
        'seller': seller,
        'brand': brand,
        'condition': condition,
        'images': images,
        'price': price.toJson(),
        if (wasPrice != null) 'wasPrice': wasPrice!.toJson(),
        'inStock': inStock,
        'landedCost': landedCost.toJson(),
        'variantGroups': variantGroups.map((g) => g.toJson()).toList(),
        'highlights': highlights,
        'dimensions': dimensions,
      };
}
