import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';

/// The three modes `/shop` renders, driven by the web app's `?mode=` query
/// param (discovery-notes.md § 2.5). [ShopMode.browse] is the bare `/shop`.
enum ShopMode {
  browse,
  search,
  paste;

  /// `?mode=search` / `?mode=paste`. Browse omits the param entirely.
  String? get queryValue => this == ShopMode.browse ? null : name;

  static ShopMode fromQuery(String? value) => switch (value?.toLowerCase()) {
    'search' => ShopMode.search,
    'paste' => ShopMode.paste,
    _ => ShopMode.browse,
  };
}

/// One tile in the shop grid — the payload behind both the default browse feed
/// and `GET /shop/search`. Deliberately the same shape as the search results
/// the web app renders: image, 2-line title, USD price, was-price, local price.
class ShopListing {
  const ShopListing({
    required this.productId,
    required this.retailer,
    required this.title,
    required this.imageUrl,
    required this.price,
    this.wasPrice,
    this.inStock = true,
  });

  /// Retailer-native identifier — an ASIN for Amazon, an item id for eBay.
  final String productId;
  final Retailer retailer;
  final String title;

  /// Cloudflare image-proxy URL on the live API. Empty in mock data, which is
  /// why every thumbnail has a deterministic placeholder to fall back to.
  final String imageUrl;

  final Money price;

  /// Struck-through original price. Absent when the item is not discounted.
  final Money? wasPrice;

  final bool inStock;

  bool get isDiscounted => wasPrice != null && wasPrice!.usd > price.usd;

  /// `-22%` — derived, not sent by the API.
  int? get discountPercent {
    if (!isDiscounted) return null;
    return (((wasPrice!.usd - price.usd) / wasPrice!.usd) * 100).round();
  }

  factory ShopListing.fromJson(Map<String, dynamic> json) => ShopListing(
    productId: json['productId'] as String,
    retailer: Retailer.fromApi(json['retailer'] as String? ?? 'AMAZON'),
    title: json['title'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    price: Money.fromJson(json['price'] as Map<String, dynamic>),
    wasPrice: json['wasPrice'] == null
        ? null
        : Money.fromJson(json['wasPrice'] as Map<String, dynamic>),
    inStock: json['inStock'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'retailer': retailer.apiValue,
    'title': title,
    'imageUrl': imageUrl,
    'price': price.toJson(),
    if (wasPrice != null) 'wasPrice': wasPrice!.toJson(),
    'inStock': inStock,
  };
}

/// A page of listings that also carries the catalogue-wide count.
///
/// The web app prints the total beside the heading (`Amazon Deals & Featured
/// Products` · `141 items`, `"usb c cable"` · `20 items`) while only one page of
/// tiles is on screen, so the count has to travel with the page rather than be
/// derived from `items.length`.
///
/// Extending [Paged] keeps the repository signature exactly
/// `Future<Paged<ShopListing>>` — callers that do not care about the count are
/// unaffected, and the shop controller reads it with a type test.
class ShopPage extends Paged<ShopListing> {
  const ShopPage({
    required super.items,
    required super.pageNumber,
    required super.hasMore,
    required this.totalCount,
  });

  final int totalCount;

  /// `141 items` / `1 item`.
  String get countLabel => '$totalCount ${totalCount == 1 ? 'item' : 'items'}';
}

/// Reads the header count off a page, falling back to what is on screen when
/// the response did not carry one.
int shopTotalCount(Paged<ShopListing> page) =>
    page is ShopPage ? page.totalCount : page.items.length;

/// Raised by `parseLink` when the pasted URL cannot become a listing — an
/// unsupported store, or a link with no product id in it. Shown inline under
/// the field rather than as a toast.
class ShopLinkException implements Exception {
  const ShopLinkException(this.message);

  final String message;

  static const unsupportedRetailer = ShopLinkException(
    "That link isn't from a store we support yet. "
    'Try Amazon, eBay, Fashion Nova, Plug Tech, Best Buy or Sephora.',
  );

  static const notAUrl = ShopLinkException(
    'That doesn\'t look like a product URL. Paste the full link from your '
    "browser's address bar.",
  );

  static const noProductId = ShopLinkException(
    "We couldn't find a product in that link. Open the product page on the "
    'store and copy the URL from there.',
  );

  @override
  String toString() => message;
}

/// Convenience for seeding mock catalogues without repeating `Money.mock`,
/// mirroring `mockProduct` in the Home feature.
ShopListing mockListing({
  required String productId,
  required Retailer retailer,
  required String title,
  required double usd,
  required DestinationCountry country,
  double? wasUsd,
  bool inStock = true,
  String imageUrl = '',
}) {
  return ShopListing(
    productId: productId,
    retailer: retailer,
    title: title,
    imageUrl: imageUrl,
    price: Money.mock(usd, country),
    wasPrice: wasUsd == null ? null : Money.mock(wasUsd, country),
    inStock: inStock,
  );
}
