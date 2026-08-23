/// Retailer scope. The API uses UPPERCASE enum values; `AMAZON` was observed
/// verbatim, the rest follow the same SCREAMING_SNAKE convention.
enum Retailer {
  amazon('AMAZON', 'Amazon'),
  ebay('EBAY', 'eBay'),
  fashionNova('FASHION_NOVA', 'Fashion Nova'),
  plugTech('PLUG_TECH', 'Plug Tech'),
  bestBuy('BEST_BUY', 'Best Buy'),
  sephora('SEPHORA', 'Sephora');

  const Retailer(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static Retailer fromApi(String value) => values.firstWhere(
    (r) => r.apiValue == value.toUpperCase(),
    orElse: () => Retailer.amazon,
  );

  /// Retailers that expose a searchable product feed. The rest are browsed via
  /// category tiles on Home (Fashion Nova, Plug Tech and Sephora render tiles,
  /// not product cards).
  bool get hasProductFeed => switch (this) {
    Retailer.amazon || Retailer.ebay || Retailer.bestBuy => true,
    _ => false,
  };
}
