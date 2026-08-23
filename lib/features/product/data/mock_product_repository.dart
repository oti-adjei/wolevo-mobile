import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';
import '../../shop/data/mock_shop_repository.dart';
import 'product_models.dart';
import 'product_repository.dart';

/// In-memory stand-in for `GET /shop/products/parse`.
///
/// The Anker cable observed during discovery is reproduced in full — title,
/// seller, brand, condition, ASIN, price, seven gallery slots, three variant
/// groups, the free-to-warehouse + $2.09-to-Ghana landed cost. Every other
/// product id is generated: the title and price come from the shop's seeded
/// catalogue where the id is known, and the rest of the detail is synthesized
/// so the screen always has something realistic to render.
class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  // ASSUMPTION: matches the shop mock's latency so the two screens feel like
  // one API.
  static const _latency = Duration(milliseconds: 500);

  /// The ASIN captured in discovery-notes.md § 2.6.
  static const ankerAsin = 'B088NRLMPV';

  @override
  Future<ProductDetail> parse({
    required String productId,
    required Retailer retailer,
    required DestinationCountry destinationCountry,
  }) async {
    await Future<void>.delayed(_latency);
    if (retailer == Retailer.amazon && productId.toUpperCase() == ankerAsin) {
      return _anker(destinationCountry);
    }
    return _generated(
      productId: productId,
      retailer: retailer,
      country: destinationCountry,
    );
  }

  // --- The observed product -------------------------------------------------

  ProductDetail _anker(DestinationCountry country) {
    return ProductDetail(
      productId: ankerAsin,
      retailer: Retailer.amazon,
      title: 'Anker USB C to USB C Cable, 60W Fast Charging Cable '
          '(2-Pack, 6 ft, Black)',
      seller: 'Amazon (FBA)',
      brand: 'Anker',
      condition: 'New',
      // Seven gallery slots — the counter on the live page read `1 / 7`. The
      // URLs are empty because the image proxy is unreachable offline; the
      // gallery falls back to a placeholder per slot.
      images: const ['', '', '', '', '', '', ''],
      price: Money.mock(9.99, country),
      inStock: true,
      landedCost: LandedCost(
        storeShipping: Money.zero(country),
        toYourDoor: Money.mock(2.09, country),
        destination: country,
      ),
      variantGroups: [
        // Six swatches were visible plus a `See more (1 more)` affordance, so
        // the group holds seven options.
        VariantGroup(
          name: 'Size',
          options: const [
            VariantOption(id: 'size-1ft', label: '1FT*2'),
            VariantOption(id: 'size-1ft-pack2', label: '1FT*2 (Pack of 2)'),
            VariantOption(id: 'size-33ft', label: '3.3FT*2'),
            VariantOption(id: 'size-33ft-pack2', label: '3.3FT*2 (Pack of 2)'),
            VariantOption(id: 'size-6ft', label: '6FT*2', selected: true),
            VariantOption(id: 'size-6ft-pack2', label: '6FT*2 (Pack of 2)'),
            VariantOption(id: 'size-10ft', label: '10FT*2'),
          ],
        ),
        VariantGroup(
          name: 'Color',
          options: const [
            VariantOption(
              id: 'color-black',
              label: 'Black',
              selected: true,
              kind: VariantOptionKind.color,
            ),
            VariantOption(
              id: 'color-red',
              label: 'Red',
              kind: VariantOptionKind.color,
            ),
            VariantOption(
              id: 'color-white',
              label: 'White',
              kind: VariantOptionKind.color,
            ),
          ],
        ),
        VariantGroup(
          name: 'NumberOfItems',
          options: const [
            VariantOption(id: 'items-2', label: '2', selected: true),
            VariantOption(id: 'items-4', label: '4'),
            VariantOption(id: 'items-5', label: '5'),
          ],
        ),
      ],
      // ASSUMPTION: the notes record that the page has six Product Highlights
      // bullets but do not quote them. These are the manufacturer's standard
      // copy for this cable, matched to the observed spec (60W, 2-pack, 6ft).
      highlights: const [
        'Powerful 60W Charging: Charge a MacBook Air to 50% in just 45 minutes, '
            'or top up your Galaxy S23 in under an hour.',
        'Universal Compatibility: Works with iPhone 15 series, MacBook Air, '
            'iPad Pro, Galaxy S23, Pixel 8, and other USB-C devices.',
        'Built to Last: Reinforced with a 12,000-bend lifespan so it survives '
            'daily coiling, packing, and unplugging.',
        'Two Cables, One Box: A 2-pack of 6 ft cables — one for your desk, one '
            'for your bag.',
        'Superior Safety: Built-in smart chip protects your devices against '
            'over-current, over-voltage, and overheating.',
        'What You Get: 2 × Anker USB-C to USB-C 60W cable (6 ft), a welcome '
            'guide, and our worry-free 24-month warranty.',
      ],
      // ASSUMPTION: the `Dimensions & Weight` rows were not transcribed; these
      // are the values Amazon lists for a 6 ft 2-pack cable.
      dimensions: const {
        'Package Dimensions': '6.7 x 4.4 x 0.7 inches',
        'Item Weight': '3.2 ounces',
        'Shipping Weight': '0.2 lb',
        'Manufacturer': 'Anker',
        'ASIN': ankerAsin,
        'Country of Origin': 'China',
      },
    );
  }

  // --- Everything else ------------------------------------------------------

  ProductDetail _generated({
    required String productId,
    required Retailer retailer,
    required DestinationCountry country,
  }) {
    final seed = MockShopRepository.seedListing(
      retailer: retailer,
      productId: productId,
      country: country,
    );

    final title = seed?.title ?? '${retailer.label} product $productId';
    final price = seed?.price ?? Money.mock(24.99, country);
    final hash = _hash(productId);

    // ASSUMPTION: everything below the title and price is invented — discovery
    // only ever opened one product page. The values are derived from the id so
    // a given product looks identical on every rebuild.
    final brand = title.split(' ').first;
    final imageCount = 4 + hash % 4; // 4–7 gallery slots

    return ProductDetail(
      productId: productId,
      retailer: retailer,
      title: title,
      seller: switch (retailer) {
        Retailer.amazon => 'Amazon (FBA)',
        Retailer.ebay => 'eBay Top Rated Seller',
        Retailer.bestBuy => 'Best Buy',
        Retailer.fashionNova => 'Fashion Nova',
        Retailer.plugTech => 'Plug Tech',
        Retailer.sephora => 'Sephora',
      },
      brand: brand,
      condition: title.toLowerCase().contains('renewed')
          ? 'Renewed'
          : (title.toLowerCase().contains('grade b') ? 'Used - Very Good' : 'New'),
      images: List<String>.filled(imageCount, ''),
      price: price,
      wasPrice: seed?.wasPrice,
      inStock: seed?.inStock ?? true,
      landedCost: LandedCost(
        storeShipping: Money.zero(country),
        // Wolevo's own leg scales with the item, so a heavier / pricier product
        // costs more to deliver than a cable.
        toYourDoor: Money.mock(2.09 + (price.usd * 0.03), country),
        destination: country,
      ),
      variantGroups: [
        VariantGroup(
          name: 'Color',
          options: [
            for (final (i, label) in _colorsFor(hash).indexed)
              VariantOption(
                id: 'color-${label.toLowerCase()}',
                label: label,
                selected: i == 0,
                kind: VariantOptionKind.color,
              ),
          ],
        ),
        if (hash.isEven)
          VariantGroup(
            name: 'Size',
            options: const [
              VariantOption(id: 'size-s', label: 'Small', selected: true),
              VariantOption(id: 'size-m', label: 'Medium'),
              VariantOption(id: 'size-l', label: 'Large'),
              VariantOption(id: 'size-xl', label: 'X-Large'),
            ],
          ),
      ],
      highlights: [
        '$brand original product, sourced directly from ${retailer.label}.',
        'Ships free to our US warehouse in Delaware, then straight to '
            '${country.name}.',
        'Price shown includes the store price in USD and today\'s '
            '${country.currencyCode} equivalent.',
        'Inspected and repacked at our warehouse before the onward flight.',
        'Covered by Wolevo buyer protection until the parcel reaches your door.',
      ],
      dimensions: {
        'Package Dimensions': '${8 + hash % 6} x ${5 + hash % 4} x '
            '${2 + hash % 3} inches',
        'Item Weight': '${1 + hash % 5}.${hash % 10} lb',
        'Shipping Weight': '${1 + hash % 6}.0 lb',
        'Manufacturer': brand,
        'Product ID': productId,
      },
    );
  }

  List<String> _colorsFor(int hash) => switch (hash % 3) {
        // Names limited to the ones the variant picker can paint from a brand
        // token — it never invents a hex value for a colour swatch.
        0 => const ['Black', 'Silver', 'Green'],
        1 => const ['White', 'Black', 'Red'],
        _ => const ['Black', 'Green', 'Red'],
      };

  /// Deterministic, platform-independent hash — `String.hashCode` is not
  /// guaranteed stable across runs.
  static int _hash(String value) {
    var h = 0;
    for (final unit in value.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }
}
