import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import 'home_models.dart';
import 'home_repository.dart';

/// In-memory stand-in for `/shop/homepage-deals` and `/shop/search`.
///
/// The section order, titles and category labels mirror the live `/home`
/// exactly (discovery-notes.md § 2.1). Product titles and prices are the ones
/// quoted verbatim in the notes where available; the rest are plausible filler
/// so each row has a realistic ten items.
class MockHomeRepository implements HomeRepository {
  const MockHomeRepository();

  // ASSUMPTION: the real API is fast enough that a spinner barely flashes;
  // 600ms keeps the loading and pull-to-refresh states visible while building.
  static const _latency = Duration(milliseconds: 600);

  @override
  Future<HomeFeed> fetchFeed(DestinationCountry country) async {
    await Future<void>.delayed(_latency);
    return HomeFeed(
      sections: [
        HomeSection(
          retailer: Retailer.amazon,
          title: 'Deals from Amazon',
          kind: HomeSectionKind.products,
          products: _amazon(country),
        ),
        HomeSection(
          retailer: Retailer.fashionNova,
          title: 'Fashion Nova',
          kind: HomeSectionKind.categories,
          categories: _categories(Retailer.fashionNova, const [
            'Women',
            'Men',
            'Plus + Curve',
            'Kids',
            'Beauty',
          ]),
        ),
        HomeSection(
          retailer: Retailer.ebay,
          title: 'Deals from eBay',
          kind: HomeSectionKind.products,
          products: _ebay(country),
        ),
        HomeSection(
          retailer: Retailer.plugTech,
          title: 'Plug Tech',
          kind: HomeSectionKind.categories,
          categories: _categories(Retailer.plugTech, const [
            'Sale',
            'Student Favorites',
            'iPhone',
            'Android',
            'iPad',
            'MacBook',
            'Watches',
            'Audio',
            'Accessories',
          ]),
        ),
        HomeSection(
          retailer: Retailer.sephora,
          title: 'Sephora',
          kind: HomeSectionKind.categories,
          categories: _categories(Retailer.sephora, const [
            'Makeup',
            'Skincare',
            'Hair',
            'Fragrance',
            'Bath & Body',
          ]),
        ),
        HomeSection(
          retailer: Retailer.bestBuy,
          title: 'Deals from Best Buy',
          kind: HomeSectionKind.products,
          products: _bestBuy(country),
        ),
      ],
    );
  }

  @override
  Future<List<DealProduct>> search({
    required String query,
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination = const Pagination(),
  }) async {
    await Future<void>.delayed(_latency);
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return const [];

    final catalogue = _catalogueFor(retailer, country);
    // ASSUMPTION: the live search matches on more than the title (brand,
    // category, keywords). Substring-on-title is the closest honest mock.
    final matches = catalogue
        .where((p) => needle
            .split(RegExp(r'\s+'))
            .every((term) => p.title.toLowerCase().contains(term)))
        .toList(growable: false);

    final start = (pagination.pageNumber - 1) * pagination.pageSize;
    if (start >= matches.length) return const [];
    final end = (start + pagination.pageSize).clamp(0, matches.length);
    return matches.sublist(start, end);
  }

  /// Retailers without a product feed (Fashion Nova, Plug Tech, Sephora) still
  /// need something searchable, so each gets a small seeded catalogue.
  List<DealProduct> _catalogueFor(Retailer retailer, DestinationCountry country) {
    return switch (retailer) {
      Retailer.amazon => _amazon(country),
      Retailer.ebay => _ebay(country),
      Retailer.bestBuy => _bestBuy(country),
      Retailer.fashionNova => _fashionNova(country),
      Retailer.plugTech => _plugTech(country),
      Retailer.sephora => _sephora(country),
    };
  }

  List<CategoryTile> _categories(Retailer retailer, List<String> labels) => [
        for (final label in labels)
          CategoryTile(label: label, imageUrl: '', retailer: retailer),
      ];

  // --- Seeded catalogues -----------------------------------------------------

  List<DealProduct> _amazon(DestinationCountry c) => [
        // Titles and prices quoted verbatim in discovery-notes.md.
        mockProduct(
          productId: 'B0BN72FYFG',
          retailer: Retailer.amazon,
          title: 'Apple iPhone 14, 512GB, (PRODUCT)Red - Unlocked (Renewed)',
          usd: 391.50,
          wasUsd: 499.00,
          country: c,
        ),
        mockProduct(
          productId: 'B0BLTBHXTM',
          retailer: Retailer.amazon,
          title: 'Amazon Fire HD 10 tablet, 10.1", 1080p Full HD, 32 GB, latest model',
          usd: 119.99,
          wasUsd: 154.99,
          country: c,
        ),
        mockProduct(
          productId: 'B0DGJ7X7NM',
          retailer: Retailer.amazon,
          title: 'Apple AirPods Pro 2 Wireless Earbuds, Active Noise Cancellation, USB-C',
          usd: 189.00,
          wasUsd: 249.00,
          country: c,
        ),
        mockProduct(
          productId: 'B08C1W5N87',
          retailer: Retailer.amazon,
          title: 'Anker 6-in-1 USB C Cable, 100W Fast Charging Nylon Braided, 6ft, 3-Pack',
          usd: 21.99,
          wasUsd: 29.99,
          country: c,
        ),
        mockProduct(
          productId: 'B09B8V1LZ3',
          retailer: Retailer.amazon,
          title: 'Echo Dot (5th Gen) Smart Speaker with Alexa, Charcoal',
          usd: 34.99,
          wasUsd: 49.99,
          country: c,
        ),
        mockProduct(
          productId: 'B0C1J6Q1WS',
          retailer: Retailer.amazon,
          title: 'SAMSUNG 990 PRO 2TB PCIe 4.0 NVMe M.2 Internal SSD',
          usd: 149.99,
          wasUsd: 219.99,
          country: c,
        ),
        mockProduct(
          productId: 'B07FZ8S74R',
          retailer: Retailer.amazon,
          title: 'Kindle Paperwhite (16 GB) - Now with a 6.8" display and adjustable warm light',
          usd: 129.99,
          wasUsd: 159.99,
          country: c,
        ),
        mockProduct(
          productId: 'B0BDHWDR12',
          retailer: Retailer.amazon,
          title: 'Logitech MX Master 3S Wireless Performance Mouse, Graphite',
          usd: 89.99,
          wasUsd: 99.99,
          country: c,
        ),
        mockProduct(
          productId: 'B0949X9BKS',
          retailer: Retailer.amazon,
          title: 'HP DeskJet 4155e All-in-One Wireless Colour Printer',
          usd: 84.99,
          country: c,
        ),
        mockProduct(
          productId: 'B08HR8T3M4',
          retailer: Retailer.amazon,
          title: 'Ninja AF101 Air Fryer, 4 Quart Capacity, Grey',
          usd: 79.99,
          wasUsd: 129.99,
          country: c,
        ),
      ];

  List<DealProduct> _ebay(DestinationCountry c) => [
        mockProduct(
          productId: '285412990017',
          retailer: Retailer.ebay,
          title: 'Apple Watch Series 11 GPS 46mm Aluminium Case - Sealed',
          usd: 639.00,
          wasUsd: 799.00,
          country: c,
        ),
        mockProduct(
          productId: '167233410882',
          retailer: Retailer.ebay,
          title: 'Sony WH-1000XM5 Wireless Noise Cancelling Headphones - Black',
          usd: 268.00,
          wasUsd: 399.99,
          country: c,
        ),
        mockProduct(
          productId: '145988012774',
          retailer: Retailer.ebay,
          title: 'Nintendo Switch OLED Model Console 64GB - White Joy-Con',
          usd: 289.95,
          wasUsd: 349.99,
          country: c,
        ),
        mockProduct(
          productId: '204712339051',
          retailer: Retailer.ebay,
          title: 'Samsung Galaxy S24 Ultra 256GB Unlocked - Titanium Grey (Excellent)',
          usd: 749.00,
          wasUsd: 1099.00,
          country: c,
        ),
        mockProduct(
          productId: '176004481920',
          retailer: Retailer.ebay,
          title: 'Anker USB C Cable 240W 6ft Braided Charging Cord for MacBook Pro',
          usd: 14.49,
          wasUsd: 19.99,
          country: c,
        ),
        mockProduct(
          productId: '186103772045',
          retailer: Retailer.ebay,
          title: 'DJI Mini 4K Drone with Camera, 3-Axis Gimbal, 31-Min Flight',
          usd: 249.00,
          wasUsd: 299.00,
          country: c,
        ),
        mockProduct(
          productId: '155743290118',
          retailer: Retailer.ebay,
          title: 'Levi\'s 501 Original Fit Men\'s Jeans - Dark Stonewash, 34x32',
          usd: 42.99,
          wasUsd: 69.50,
          country: c,
        ),
        mockProduct(
          productId: '134589012337',
          retailer: Retailer.ebay,
          title: 'Canon EOS R50 Mirrorless Camera with RF-S 18-45mm Lens Kit',
          usd: 599.00,
          wasUsd: 679.00,
          country: c,
        ),
        mockProduct(
          productId: '295012774310',
          retailer: Retailer.ebay,
          title: 'Nike Air Force 1 \'07 Men\'s Trainers - Triple White, UK 9',
          usd: 84.00,
          wasUsd: 114.99,
          country: c,
        ),
        mockProduct(
          productId: '166012338994',
          retailer: Retailer.ebay,
          title: 'SanDisk Extreme PRO 1TB Portable SSD USB-C 2000MB/s',
          usd: 109.99,
          country: c,
        ),
      ];

  List<DealProduct> _bestBuy(DestinationCountry c) => [
        mockProduct(
          productId: '6522287',
          retailer: Retailer.bestBuy,
          title: 'Roku 40-Inch Select Series 1080p HD Smart RokuTV',
          usd: 129.99,
          wasUsd: 169.99,
          country: c,
        ),
        mockProduct(
          productId: '6588451',
          retailer: Retailer.bestBuy,
          title: 'Apple Watch Series 11 (GPS) 42mm Jet Black Aluminum Case',
          usd: 639.00,
          wasUsd: 799.00,
          country: c,
        ),
        mockProduct(
          productId: '6565837',
          retailer: Retailer.bestBuy,
          title: 'Insignia 55" Class F30 Series LED 4K UHD Smart Fire TV',
          usd: 249.99,
          wasUsd: 399.99,
          country: c,
        ),
        mockProduct(
          productId: '6535329',
          retailer: Retailer.bestBuy,
          title: 'Bose QuietComfort Ultra Wireless Noise Cancelling Headphones',
          usd: 329.00,
          wasUsd: 429.00,
          country: c,
        ),
        mockProduct(
          productId: '6509650',
          retailer: Retailer.bestBuy,
          title: 'HP 15.6" Touch-Screen Laptop - Intel Core i5, 8GB Memory, 512GB SSD',
          usd: 449.99,
          wasUsd: 649.99,
          country: c,
        ),
        mockProduct(
          productId: '6418599',
          retailer: Retailer.bestBuy,
          title: 'Dyson V8 Plus Cordless Vacuum with 6 Accessories - Silver/Nickel',
          usd: 319.99,
          wasUsd: 469.99,
          country: c,
        ),
        mockProduct(
          productId: '6501720',
          retailer: Retailer.bestBuy,
          title: 'Best Buy essentials 6\' USB C to USB C Charge-and-Sync Cable',
          usd: 9.99,
          wasUsd: 14.99,
          country: c,
        ),
        mockProduct(
          productId: '6577220',
          retailer: Retailer.bestBuy,
          title: 'Samsung 27" Odyssey G5 QHD 165Hz Curved Gaming Monitor',
          usd: 219.99,
          wasUsd: 329.99,
          country: c,
        ),
        mockProduct(
          productId: '6473051',
          retailer: Retailer.bestBuy,
          title: 'Keurig K-Express Single Serve K-Cup Pod Coffee Maker - Black',
          usd: 59.99,
          wasUsd: 89.99,
          country: c,
        ),
        mockProduct(
          productId: '6551234',
          retailer: Retailer.bestBuy,
          title: 'Apple iPad (10th Generation) 10.9" Wi-Fi 64GB - Silver',
          usd: 299.00,
          wasUsd: 349.00,
          country: c,
        ),
      ];

  // Category-led retailers: smaller catalogues, search-only.
  List<DealProduct> _fashionNova(DestinationCountry c) => [
        mockProduct(
          productId: 'FN-1001',
          retailer: Retailer.fashionNova,
          title: 'Classic High Waist Skinny Jeans - Dark Wash',
          usd: 39.99,
          wasUsd: 54.99,
          country: c,
        ),
        mockProduct(
          productId: 'FN-1002',
          retailer: Retailer.fashionNova,
          title: 'Off The Shoulder Bodycon Midi Dress - Black',
          usd: 34.99,
          wasUsd: 49.99,
          country: c,
        ),
        mockProduct(
          productId: 'FN-1003',
          retailer: Retailer.fashionNova,
          title: 'Men\'s Oversized Graphic Tee - Washed Grey',
          usd: 19.99,
          country: c,
        ),
        mockProduct(
          productId: 'FN-1004',
          retailer: Retailer.fashionNova,
          title: 'Plus Curve Ribbed Two Piece Lounge Set - Mocha',
          usd: 44.99,
          wasUsd: 64.99,
          country: c,
        ),
        mockProduct(
          productId: 'FN-1005',
          retailer: Retailer.fashionNova,
          title: 'Kids Cargo Jogger Pants - Olive',
          usd: 24.99,
          country: c,
        ),
      ];

  List<DealProduct> _plugTech(DestinationCountry c) => [
        mockProduct(
          productId: 'PT-2001',
          retailer: Retailer.plugTech,
          title: 'iPhone 15 Pro 256GB Unlocked - Natural Titanium (Grade A)',
          usd: 749.00,
          wasUsd: 899.00,
          country: c,
        ),
        mockProduct(
          productId: 'PT-2002',
          retailer: Retailer.plugTech,
          title: 'MacBook Air 13" M2 8GB/256GB - Midnight (Refurbished)',
          usd: 719.00,
          wasUsd: 999.00,
          country: c,
        ),
        mockProduct(
          productId: 'PT-2003',
          retailer: Retailer.plugTech,
          title: 'iPad 10th Gen 64GB Wi-Fi - Blue',
          usd: 289.00,
          wasUsd: 349.00,
          country: c,
        ),
        mockProduct(
          productId: 'PT-2004',
          retailer: Retailer.plugTech,
          title: '65W GaN USB C Charger with 6ft Cable - Student Bundle',
          usd: 29.99,
          wasUsd: 44.99,
          country: c,
        ),
        mockProduct(
          productId: 'PT-2005',
          retailer: Retailer.plugTech,
          title: 'Samsung Galaxy Watch 6 44mm Bluetooth - Graphite',
          usd: 199.00,
          wasUsd: 279.99,
          country: c,
        ),
      ];

  List<DealProduct> _sephora(DestinationCountry c) => [
        mockProduct(
          productId: 'SEP-3001',
          retailer: Retailer.sephora,
          title: 'Rare Beauty Soft Pinch Liquid Blush - Hope',
          usd: 23.00,
          country: c,
        ),
        mockProduct(
          productId: 'SEP-3002',
          retailer: Retailer.sephora,
          title: 'The Ordinary Niacinamide 10% + Zinc 1% Serum, 30ml',
          usd: 12.00,
          country: c,
        ),
        mockProduct(
          productId: 'SEP-3003',
          retailer: Retailer.sephora,
          title: 'Olaplex No. 3 Hair Perfector Bond Repair Treatment',
          usd: 30.00,
          wasUsd: 38.00,
          country: c,
        ),
        mockProduct(
          productId: 'SEP-3004',
          retailer: Retailer.sephora,
          title: 'Sol de Janeiro Brazilian Crush Cheirosa 62 Perfume Mist',
          usd: 38.00,
          country: c,
        ),
        mockProduct(
          productId: 'SEP-3005',
          retailer: Retailer.sephora,
          title: 'Fenty Beauty Pro Filt\'r Soft Matte Longwear Foundation',
          usd: 41.00,
          wasUsd: 46.00,
          country: c,
        ),
      ];
}
