import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';

/// Models the `GET /api/v1/shop/homepage-deals` payload (discovery-notes.md
/// § 2.1). The web app renders one section per retailer; three of them are
/// product carousels and three are category tile grids, so the section itself
/// carries the discriminator rather than the retailer.
enum HomeSectionKind {
  products,
  categories;

  String get apiValue => name.toUpperCase();

  // ASSUMPTION: the live payload distinguishes the two row types with a `kind`
  // field. Only the rendered output was observable, so the parser also falls
  // back to inferring the kind from whichever list is populated.
  static HomeSectionKind fromApi(String? value) => switch (value?.toUpperCase()) {
        'CATEGORIES' => HomeSectionKind.categories,
        'PRODUCTS' => HomeSectionKind.products,
        _ => HomeSectionKind.products,
      };
}

/// A single merchandised product in a deal row or a search result.
class DealProduct {
  const DealProduct({
    required this.productId,
    required this.retailer,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.wasPrice,
  });

  /// Retailer-native identifier — an ASIN for Amazon, an item id for eBay.
  final String productId;
  final Retailer retailer;
  final String title;

  /// Cloudflare image-proxy URL on the live API. Empty in mock data, which is
  /// why [ProductThumb] always has a deterministic placeholder to fall back to.
  final String imageUrl;

  final Money price;

  /// Struck-through original price. Absent when the item is not discounted.
  final Money? wasPrice;

  bool get isDiscounted => wasPrice != null && wasPrice!.usd > price.usd;

  /// `-22%` — derived, not sent by the API.
  int? get discountPercent {
    if (!isDiscounted) return null;
    return (((wasPrice!.usd - price.usd) / wasPrice!.usd) * 100).round();
  }

  factory DealProduct.fromJson(Map<String, dynamic> json) => DealProduct(
        productId: json['productId'] as String,
        retailer: Retailer.fromApi(json['retailer'] as String? ?? 'AMAZON'),
        title: json['title'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        price: Money.fromJson(json['price'] as Map<String, dynamic>),
        wasPrice: json['wasPrice'] == null
            ? null
            : Money.fromJson(json['wasPrice'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'retailer': retailer.apiValue,
        'title': title,
        'imageUrl': imageUrl,
        'price': price.toJson(),
        if (wasPrice != null) 'wasPrice': wasPrice!.toJson(),
      };
}

/// One tile in a category row — Fashion Nova / Plug Tech / Sephora merchandise
/// by department rather than by product.
class CategoryTile {
  const CategoryTile({
    required this.label,
    required this.imageUrl,
    required this.retailer,
  });

  final String label;
  final String imageUrl;
  final Retailer retailer;

  factory CategoryTile.fromJson(Map<String, dynamic> json) => CategoryTile(
        label: json['label'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        retailer: Retailer.fromApi(json['retailer'] as String? ?? 'AMAZON'),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'imageUrl': imageUrl,
        'retailer': retailer.apiValue,
      };
}

/// One merchandised row: `Deals from Amazon`, `Sephora`, …
class HomeSection {
  const HomeSection({
    required this.retailer,
    required this.title,
    required this.kind,
    this.products = const [],
    this.categories = const [],
  });

  final Retailer retailer;

  /// Rendered heading. The web app writes `Deals from Amazon` for product rows
  /// and the bare retailer name for category rows, so the title ships from the
  /// server rather than being derived client-side.
  final String title;

  final HomeSectionKind kind;
  final List<DealProduct> products;
  final List<CategoryTile> categories;

  bool get isEmpty => kind == HomeSectionKind.products ? products.isEmpty : categories.isEmpty;

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? const [])
        .map((e) => DealProduct.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final categories = (json['categories'] as List<dynamic>? ?? const [])
        .map((e) => CategoryTile.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final retailer = Retailer.fromApi(json['retailer'] as String? ?? 'AMAZON');
    return HomeSection(
      retailer: retailer,
      title: json['title'] as String? ?? retailer.label,
      kind: json['kind'] == null
          ? (categories.isNotEmpty ? HomeSectionKind.categories : HomeSectionKind.products)
          : HomeSectionKind.fromApi(json['kind'] as String),
      products: products,
      categories: categories,
    );
  }

  Map<String, dynamic> toJson() => {
        'retailer': retailer.apiValue,
        'title': title,
        'kind': kind.apiValue,
        'products': products.map((p) => p.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}

/// The whole `/shop/homepage-deals` response.
class HomeFeed {
  const HomeFeed({required this.sections});

  final List<HomeSection> sections;

  static const empty = HomeFeed(sections: []);

  /// The chip row at the top of Home is not part of the payload — the web app
  /// hardcodes all six retailers regardless of what the feed contains.
  List<Retailer> get browsableRetailers => Retailer.values;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => HomeFeed(
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  Map<String, dynamic> toJson() => {
        'sections': sections.map((s) => s.toJson()).toList(),
      };
}

/// A page of `GET /shop/search` results plus the count the web app prints
/// beside the query (`"usb c cable" × Clear   20 items`).
class SearchResults {
  const SearchResults({
    required this.query,
    required this.retailer,
    required this.products,
    required this.totalCount,
    required this.hasMore,
  });

  final String query;
  final Retailer retailer;
  final List<DealProduct> products;
  final int totalCount;
  final bool hasMore;

  static SearchResults emptyFor(String query, Retailer retailer) => SearchResults(
        query: query,
        retailer: retailer,
        products: const [],
        totalCount: 0,
        hasMore: false,
      );
}

/// Convenience for seeding mock catalogues without repeating `Money.mock`.
DealProduct mockProduct({
  required String productId,
  required Retailer retailer,
  required String title,
  required double usd,
  double? wasUsd,
  required DestinationCountry country,
  String imageUrl = '',
}) {
  return DealProduct(
    productId: productId,
    retailer: retailer,
    title: title,
    imageUrl: imageUrl,
    price: Money.mock(usd, country),
    wasPrice: wasUsd == null ? null : Money.mock(wasUsd, country),
  );
}
