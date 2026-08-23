import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import 'shop_models.dart';
import 'shop_repository.dart';

/// A row of the seeded catalogue, before it is turned into money for a
/// particular destination country.
typedef _Seed = ({String id, String title, double usd, double? was});

/// In-memory stand-in for the `/shop` feed, `/shop/search` and the
/// paste-a-link resolver.
///
/// Titles and prices quoted in discovery-notes.md are reproduced verbatim
/// (the Anker cable, the LISEN 240W, the renewed iPhone 14, the SanDisk SSD);
/// the rest are plausible filler so each retailer has a realistic 24-item
/// catalogue to page through.
class MockShopRepository implements ShopRepository {
  const MockShopRepository();

  // ASSUMPTION: 500ms keeps the skeletons, pull-to-refresh and infinite-scroll
  // spinners visible while building. The real API is faster.
  static const _latency = Duration(milliseconds: 500);

  @override
  Future<Paged<ShopListing>> browse({
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination = const Pagination(),
  }) async {
    await Future<void>.delayed(_latency);
    return _page(_catalogue(retailer, country), pagination);
  }

  @override
  Future<Paged<ShopListing>> search({
    required String keyword,
    required Retailer retailer,
    required DestinationCountry country,
    Pagination pagination = const Pagination(),
  }) async {
    await Future<void>.delayed(_latency);
    final needle = keyword.trim().toLowerCase();
    if (needle.isEmpty) {
      return const ShopPage(
        items: [],
        pageNumber: 1,
        hasMore: false,
        totalCount: 0,
      );
    }

    // ASSUMPTION: the live search matches on more than the title (brand,
    // category, keywords). Case-insensitive substring per whitespace-separated
    // term is the closest honest mock, and matches how Home fakes it.
    final terms = needle.split(RegExp(r'\s+'));
    final matches = _catalogue(retailer, country)
        .where((l) => terms.every((t) => l.title.toLowerCase().contains(t)))
        .toList(growable: false);

    return _page(matches, pagination);
  }

  @override
  Future<ShopListing> parseLink({
    required String url,
    required DestinationCountry country,
  }) async {
    await Future<void>.delayed(_latency);

    final trimmed = url.trim();
    if (trimmed.isEmpty) throw ShopLinkException.notAUrl;

    // Users rarely paste a scheme, so tolerate a bare host.
    final uri = Uri.tryParse(
      trimmed.startsWith('http') ? trimmed : 'https://$trimmed',
    );
    if (uri == null || uri.host.isEmpty) throw ShopLinkException.notAUrl;

    final retailer = _retailerForHost(uri.host.toLowerCase());
    if (retailer == null) throw ShopLinkException.unsupportedRetailer;

    final productId = _productIdFrom(uri, retailer);
    if (productId == null) throw ShopLinkException.noProductId;

    final catalogue = _catalogue(retailer, country);
    for (final listing in catalogue) {
      if (listing.productId.toLowerCase() == productId.toLowerCase()) {
        return listing;
      }
    }

    // ASSUMPTION: a real parse can resolve any live product page, not only the
    // ones in our seeded catalogue, so an unknown id still returns a listing.
    return mockListing(
      productId: productId,
      retailer: retailer,
      title: '${retailer.label} product $productId',
      usd: 24.99,
      country: country,
    );
  }

  /// Looks a seeded listing up by retailer + id.
  ///
  /// The product mock uses this so a tile tapped in the grid opens a detail
  /// page carrying the same title and price the grid just showed. Returns null
  /// for ids that are not in the seeded catalogue.
  static ShopListing? seedListing({
    required Retailer retailer,
    required String productId,
    required DestinationCountry country,
  }) {
    for (final listing in const MockShopRepository()._catalogue(
      retailer,
      country,
    )) {
      if (listing.productId.toLowerCase() == productId.toLowerCase()) {
        return listing;
      }
    }
    return null;
  }

  // --- Paging ---------------------------------------------------------------

  ShopPage _page(List<ShopListing> all, Pagination pagination) {
    final start = (pagination.pageNumber - 1) * pagination.pageSize;
    if (start >= all.length) {
      return ShopPage(
        items: const [],
        pageNumber: pagination.pageNumber,
        hasMore: false,
        totalCount: all.length,
      );
    }
    final end = (start + pagination.pageSize).clamp(0, all.length);
    return ShopPage(
      items: all.sublist(start, end),
      pageNumber: pagination.pageNumber,
      hasMore: end < all.length,
      totalCount: all.length,
    );
  }

  // --- Link parsing ---------------------------------------------------------

  // ASSUMPTION: the host list is inferred from each retailer's public domain;
  // discovery only ever exercised an Amazon link.
  static const _hosts = <Retailer, List<String>>{
    Retailer.amazon: ['amazon.com', 'amzn.to', 'amzn.com'],
    Retailer.ebay: ['ebay.com', 'ebay.to'],
    Retailer.fashionNova: ['fashionnova.com'],
    Retailer.plugTech: ['plugtech.com', 'theplug.tech'],
    Retailer.bestBuy: ['bestbuy.com'],
    Retailer.sephora: ['sephora.com'],
  };

  Retailer? _retailerForHost(String host) {
    final bare = host.startsWith('www.') ? host.substring(4) : host;
    for (final entry in _hosts.entries) {
      for (final domain in entry.value) {
        if (bare == domain || bare.endsWith('.$domain')) return entry.key;
      }
    }
    return null;
  }

  /// Pulls the retailer-native id out of a product URL — `/dp/B088NRLMPV`,
  /// `/itm/285412990017`, `?skuId=6522287`, or the last slug otherwise.
  String? _productIdFrom(Uri uri, Retailer retailer) {
    final segments = [
      for (final s in uri.pathSegments)
        if (s.isNotEmpty) s,
    ];

    String? after(String marker) {
      final index = segments.indexOf(marker);
      if (index == -1 || index + 1 >= segments.length) return null;
      return segments[index + 1];
    }

    return switch (retailer) {
      Retailer.amazon =>
        after('dp') ??
            after('gp') ??
            uri.queryParameters['asin'] ??
            segments.lastOrNull,
      Retailer.ebay => after('itm') ?? segments.lastOrNull,
      Retailer.bestBuy => uri.queryParameters['skuId'] ?? segments.lastOrNull,
      _ => uri.queryParameters['productId'] ?? segments.lastOrNull,
    };
  }

  // --- Seeded catalogues ----------------------------------------------------

  List<ShopListing> _catalogue(Retailer retailer, DestinationCountry country) {
    final seeds = switch (retailer) {
      Retailer.amazon => _amazon,
      Retailer.ebay => _ebay,
      Retailer.fashionNova => _fashionNova,
      Retailer.plugTech => _plugTech,
      Retailer.bestBuy => _bestBuy,
      Retailer.sephora => _sephora,
    };
    return [
      for (final (index, s) in seeds.indexed)
        mockListing(
          productId: s.id,
          retailer: retailer,
          title: s.title,
          usd: s.usd,
          wasUsd: s.was,
          country: country,
          // ASSUMPTION: the grid never showed an out-of-stock tile during
          // discovery. One sold-out item per catalogue keeps that state real.
          inStock: index != 17,
        ),
    ];
  }

  static const _amazon = <_Seed>[
    // Quoted verbatim in discovery-notes.md § 2.5 / § 2.6.
    (
      id: 'B088NRLMPV',
      title:
          'Anker USB C to USB C Cable, 60W Fast Charging Cable (2-Pack, 6 ft, Black)',
      usd: 9.99,
      was: null,
    ),
    (
      id: 'B0CJ5X1L4Z',
      title:
          'LISEN 240W USB C to USB C Cable, 3.3ft Fast Charging Nylon Braided Cord',
      usd: 8.99,
      was: 9.99,
    ),
    (
      id: 'B0BN72FYFG',
      title: 'Apple iPhone 14, 512GB, (PRODUCT)Red - Unlocked (Renewed)',
      usd: 391.50,
      was: 499.00,
    ),
    (
      id: 'B0B7CPSN2K',
      title: 'SANDISK 1TB Extreme Portable SSD - Up to 1050MB/s, USB-C, IP65',
      usd: 165.70,
      was: 189.99,
    ),
    (
      id: 'B0BLTBHXTM',
      title:
          'Amazon Fire HD 10 tablet, 10.1", 1080p Full HD, 32 GB, latest model',
      usd: 119.99,
      was: 154.99,
    ),
    (
      id: 'B0DGJ7X7NM',
      title:
          'Apple AirPods Pro 2 Wireless Earbuds, Active Noise Cancellation, USB-C',
      usd: 189.00,
      was: 249.00,
    ),
    (
      id: 'B09B8V1LZ3',
      title: 'Echo Dot (5th Gen) Smart Speaker with Alexa, Charcoal',
      usd: 34.99,
      was: 49.99,
    ),
    (
      id: 'B0C1J6Q1WS',
      title: 'SAMSUNG 990 PRO 2TB PCIe 4.0 NVMe M.2 Internal SSD',
      usd: 149.99,
      was: 219.99,
    ),
    (
      id: 'B07FZ8S74R',
      title:
          'Kindle Paperwhite (16 GB) - 6.8" display and adjustable warm light',
      usd: 129.99,
      was: 159.99,
    ),
    (
      id: 'B0BDHWDR12',
      title: 'Logitech MX Master 3S Wireless Performance Mouse, Graphite',
      usd: 89.99,
      was: 99.99,
    ),
    (
      id: 'B0949X9BKS',
      title: 'HP DeskJet 4155e All-in-One Wireless Colour Printer',
      usd: 84.99,
      was: null,
    ),
    (
      id: 'B08HR8T3M4',
      title: 'Ninja AF101 Air Fryer, 4 Quart Capacity, Grey',
      usd: 79.99,
      was: 129.99,
    ),
    (
      id: 'B08C1W5N87',
      title:
          'Anker 6-in-1 USB C Cable, 100W Fast Charging Nylon Braided, 6ft, 3-Pack',
      usd: 21.99,
      was: 29.99,
    ),
    (
      id: 'B0CHX2F5QT',
      title:
          'Anker 737 Power Bank (PowerCore 24K, 140W) with Smart Digital Display',
      usd: 99.99,
      was: 149.99,
    ),
    (
      id: 'B09JQL3NWT',
      title: 'JBL Flip 6 Portable Waterproof Bluetooth Speaker - Black',
      usd: 89.95,
      was: 129.95,
    ),
    (
      id: 'B0BSHF7WHW',
      title: 'Apple AirTag 4 Pack - Item Finder with Precision Finding',
      usd: 74.99,
      was: 99.00,
    ),
    (
      id: 'B0863TXGM3',
      title: 'SAMSUNG EVO Select 512GB microSDXC Memory Card with Adapter',
      usd: 34.99,
      was: 54.99,
    ),
    (
      id: 'B07YFF3JCN',
      title:
          'Instant Pot Duo 7-in-1 Electric Pressure Cooker, 6 Quart, Stainless Steel',
      usd: 89.99,
      was: 119.99,
    ),
    (
      id: 'B09G9FPHY6',
      title:
          'Fitbit Charge 6 Fitness Tracker with Heart Rate and GPS - Obsidian',
      usd: 129.95,
      was: 159.95,
    ),
    (
      id: 'B0BQ7RJK9C',
      title: 'Beats Studio Pro Wireless Bluetooth Headphones - Deep Brown',
      usd: 179.99,
      was: 349.99,
    ),
    (
      id: 'B08KH53NKR',
      title: 'Crocs Unisex-Adult Classic Clogs, Black, Men 9 / Women 11',
      usd: 44.99,
      was: 54.99,
    ),
    (
      id: 'B0BFVXPXGX',
      title: 'Baseus 100W USB C Charger, 4-Port GaN Fast Wall Charger Block',
      usd: 45.99,
      was: 69.99,
    ),
    (
      id: 'B09XS7JWHH',
      title: 'CeraVe Moisturizing Cream for Normal to Dry Skin, 19 Ounce',
      usd: 17.98,
      was: 22.49,
    ),
    (
      id: 'B0BCS4Q3TQ',
      title: 'Ring Battery Doorbell Plus, Head-to-Toe Video, Satin Nickel',
      usd: 99.99,
      was: 149.99,
    ),
  ];

  static const _ebay = <_Seed>[
    (
      id: '285412990017',
      title: 'Apple Watch Series 11 GPS 46mm Aluminium Case - Sealed',
      usd: 639.00,
      was: 799.00,
    ),
    (
      id: '167233410882',
      title: 'Sony WH-1000XM5 Wireless Noise Cancelling Headphones - Black',
      usd: 268.00,
      was: 399.99,
    ),
    (
      id: '145988012774',
      title: 'Nintendo Switch OLED Model Console 64GB - White Joy-Con',
      usd: 289.95,
      was: 349.99,
    ),
    (
      id: '204712339051',
      title:
          'Samsung Galaxy S24 Ultra 256GB Unlocked - Titanium Grey (Excellent)',
      usd: 749.00,
      was: 1099.00,
    ),
    (
      id: '176004481920',
      title: 'Anker USB C Cable 240W 6ft Braided Charging Cord for MacBook Pro',
      usd: 14.49,
      was: 19.99,
    ),
    (
      id: '186103772045',
      title: 'DJI Mini 4K Drone with Camera, 3-Axis Gimbal, 31-Min Flight',
      usd: 249.00,
      was: 299.00,
    ),
    (
      id: '155743290118',
      title: "Levi's 501 Original Fit Men's Jeans - Dark Stonewash, 34x32",
      usd: 42.99,
      was: 69.50,
    ),
    (
      id: '134589012337',
      title: 'Canon EOS R50 Mirrorless Camera with RF-S 18-45mm Lens Kit',
      usd: 599.00,
      was: 679.00,
    ),
    (
      id: '295012774310',
      title: "Nike Air Force 1 '07 Men's Trainers - Triple White, UK 9",
      usd: 84.00,
      was: 114.99,
    ),
    (
      id: '166012338994',
      title: 'SanDisk Extreme PRO 1TB Portable SSD USB-C 2000MB/s',
      usd: 109.99,
      was: null,
    ),
    (
      id: '256113904472',
      title: 'Apple iPad Air 5th Gen 64GB Wi-Fi - Space Grey (Very Good)',
      usd: 379.00,
      was: 599.00,
    ),
    (
      id: '225498013776',
      title: 'PlayStation 5 Slim Digital Edition Console - Boxed',
      usd: 419.00,
      was: 449.99,
    ),
    (
      id: '145112907733',
      title: 'GoPro HERO12 Black Action Camera - 5.3K60 Waterproof',
      usd: 279.00,
      was: 399.99,
    ),
    (
      id: '387009123845',
      title: 'Seiko 5 Sports SRPD55 Automatic Watch - Black Dial 42.5mm',
      usd: 189.00,
      was: 275.00,
    ),
    (
      id: '176441220038',
      title: 'Dell Latitude 7420 14" Laptop i7 16GB 512GB SSD Windows 11 Pro',
      usd: 329.00,
      was: 499.00,
    ),
    (
      id: '204990017722',
      title: 'Ray-Ban Wayfarer RB2140 Sunglasses - Black / Green Classic G-15',
      usd: 119.00,
      was: 171.00,
    ),
    (
      id: '166778001235',
      title: 'Anker Soundcore Life Q30 Hybrid Noise Cancelling Headphones',
      usd: 54.99,
      was: 79.99,
    ),
    (
      id: '285990112004',
      title: 'Xbox Series X 1TB Console with Wireless Controller - Sealed',
      usd: 449.00,
      was: 499.99,
    ),
    (
      id: '134001982277',
      title: 'Apple MacBook Air M2 13.6" 8GB 256GB - Midnight (Refurbished)',
      usd: 699.00,
      was: 999.00,
    ),
    (
      id: '195774003318',
      title: 'Adidas Samba OG Trainers - Cloud White / Core Black, UK 8',
      usd: 92.00,
      was: 110.00,
    ),
    (
      id: '256448012009',
      title: 'Bose SoundLink Flex Bluetooth Speaker - Stone Blue',
      usd: 109.00,
      was: 149.00,
    ),
    (
      id: '176990224417',
      title:
          'Garmin Forerunner 265 GPS Running Smartwatch - Black / Powder Grey',
      usd: 379.00,
      was: 449.99,
    ),
    (
      id: '145330018806',
      title: 'Lego Star Wars Millennium Falcon 75375 Building Set - New',
      usd: 79.99,
      was: 84.99,
    ),
    (
      id: '387112009943',
      title: 'Samsung 32" Odyssey G7 4K UHD 144Hz Gaming Monitor',
      usd: 549.00,
      was: 799.99,
    ),
  ];

  static const _bestBuy = <_Seed>[
    (
      id: '6522287',
      title: 'Roku 40-Inch Select Series 1080p HD Smart RokuTV',
      usd: 129.99,
      was: 169.99,
    ),
    (
      id: '6588451',
      title: 'Apple Watch Series 11 (GPS) 42mm Jet Black Aluminum Case',
      usd: 639.00,
      was: 799.00,
    ),
    (
      id: '6565837',
      title: 'Insignia 55" Class F30 Series LED 4K UHD Smart Fire TV',
      usd: 249.99,
      was: 399.99,
    ),
    (
      id: '6535329',
      title: 'Bose QuietComfort Ultra Wireless Noise Cancelling Headphones',
      usd: 329.00,
      was: 429.00,
    ),
    (
      id: '6509650',
      title:
          'HP 15.6" Touch-Screen Laptop - Intel Core i5, 8GB Memory, 512GB SSD',
      usd: 449.99,
      was: 649.99,
    ),
    (
      id: '6418599',
      title: 'Dyson V8 Plus Cordless Vacuum with 6 Accessories - Silver/Nickel',
      usd: 319.99,
      was: 469.99,
    ),
    (
      id: '6501720',
      title: "Best Buy essentials 6' USB C to USB C Charge-and-Sync Cable",
      usd: 9.99,
      was: 14.99,
    ),
    (
      id: '6577220',
      title: 'Samsung 27" Odyssey G5 QHD 165Hz Curved Gaming Monitor',
      usd: 219.99,
      was: 329.99,
    ),
    (
      id: '6473051',
      title: 'Keurig K-Express Single Serve K-Cup Pod Coffee Maker - Black',
      usd: 59.99,
      was: 89.99,
    ),
    (
      id: '6551234',
      title: 'Apple iPad (10th Generation) 10.9" Wi-Fi 64GB - Silver',
      usd: 299.00,
      was: 349.00,
    ),
    (
      id: '6540122',
      title: 'Sony WF-1000XM5 True Wireless Noise Cancelling Earbuds - Black',
      usd: 229.99,
      was: 299.99,
    ),
    (
      id: '6511008',
      title: 'LG 65" Class C3 Series OLED 4K UHD Smart webOS TV',
      usd: 1299.99,
      was: 1799.99,
    ),
    (
      id: '6499871',
      title: 'Ninja Foodi 6-in-1 8-qt. 2-Basket Air Fryer with DualZone',
      usd: 149.99,
      was: 199.99,
    ),
    (
      id: '6562003',
      title: 'Anker 622 MagGo Magnetic Battery 5000mAh Power Bank - Black',
      usd: 39.99,
      was: 69.99,
    ),
    (
      id: '6530044',
      title: 'Lenovo IdeaPad Slim 3 15.6" Laptop - Ryzen 5, 8GB, 512GB SSD',
      usd: 379.99,
      was: 529.99,
    ),
    (
      id: '6488192',
      title: 'Samsung Galaxy Tab A9+ 11" 64GB Wi-Fi Tablet - Graphite',
      usd: 179.99,
      was: 219.99,
    ),
    (
      id: '6519930',
      title: 'Shark Navigator Lift-Away Upright Vacuum - Blue',
      usd: 149.99,
      was: 229.99,
    ),
    (
      id: '6572811',
      title: 'JBL Tune 770NC Adaptive Noise Cancelling Wireless Headphones',
      usd: 99.95,
      was: 129.95,
    ),
    (
      id: '6505561',
      title: 'Google Nest Learning Thermostat (4th Gen) - Polished Silver',
      usd: 249.99,
      was: 279.99,
    ),
    (
      id: '6493377',
      title: 'Canon PIXMA TR4720 Wireless All-In-One Inkjet Printer - Black',
      usd: 79.99,
      was: 99.99,
    ),
    (
      id: '6558104',
      title: 'WD 2TB My Passport Portable External Hard Drive USB 3.0',
      usd: 74.99,
      was: 109.99,
    ),
    (
      id: '6544890',
      title: 'Meta Quest 3S 128GB All-In-One VR Headset',
      usd: 299.99,
      was: null,
    ),
    (
      id: '6482277',
      title: 'Beats Solo 4 On-Ear Wireless Headphones - Matte Black',
      usd: 129.99,
      was: 199.99,
    ),
    (
      id: '6569012',
      title: 'Amazon Fire TV Stick 4K Max Streaming Device with Wi-Fi 6E',
      usd: 39.99,
      was: 59.99,
    ),
  ];

  static const _fashionNova = <_Seed>[
    (
      id: 'FN-1001',
      title: 'Classic High Waist Skinny Jeans - Dark Wash',
      usd: 39.99,
      was: 54.99,
    ),
    (
      id: 'FN-1002',
      title: 'Off The Shoulder Bodycon Midi Dress - Black',
      usd: 34.99,
      was: 49.99,
    ),
    (
      id: 'FN-1003',
      title: 'Ribbed Knit Long Sleeve Crop Top - Mocha',
      usd: 19.99,
      was: 29.99,
    ),
    (
      id: 'FN-1004',
      title: 'Curve Faux Leather Moto Jacket - Black',
      usd: 59.99,
      was: 89.99,
    ),
    (
      id: 'FN-1005',
      title: "Men's Essential Fleece Jogger Set - Heather Grey",
      usd: 49.99,
      was: 74.99,
    ),
    (
      id: 'FN-1006',
      title: 'Satin Slip Maxi Dress with Side Slit - Emerald',
      usd: 44.99,
      was: 64.99,
    ),
    (
      id: 'FN-1007',
      title: 'Oversized Boyfriend Blazer - Cream',
      usd: 54.99,
      was: 79.99,
    ),
    (
      id: 'FN-1008',
      title: 'Seamless Sculpt Bodysuit Long Sleeve - Chocolate',
      usd: 29.99,
      was: 39.99,
    ),
    (
      id: 'FN-1009',
      title: 'Plus Wide Leg Cargo Pants - Olive',
      usd: 42.99,
      was: 59.99,
    ),
    (
      id: 'FN-1010',
      title: 'Strappy Square Toe Stiletto Heels - Nude',
      usd: 37.99,
      was: 54.99,
    ),
    (
      id: 'FN-1011',
      title: 'Distressed Mom Jeans - Medium Blue Wash',
      usd: 44.99,
      was: 64.99,
    ),
    (
      id: 'FN-1012',
      title: "Men's Slim Fit Stretch Denim Jacket - Black",
      usd: 54.99,
      was: 84.99,
    ),
    (
      id: 'FN-1013',
      title: 'Cropped Puffer Jacket - Metallic Silver',
      usd: 64.99,
      was: 99.99,
    ),
    (
      id: 'FN-1014',
      title: 'Mesh Long Sleeve Mini Dress - Hot Pink',
      usd: 32.99,
      was: 44.99,
    ),
    (
      id: 'FN-1015',
      title: 'Two Piece Ribbed Lounge Set - Sage',
      usd: 39.99,
      was: 59.99,
    ),
    (
      id: 'FN-1016',
      title: 'Rhinestone Fringe Party Dress - Champagne',
      usd: 74.99,
      was: 109.99,
    ),
    (
      id: 'FN-1017',
      title: 'Faux Fur Cropped Coat - Leopard Print',
      usd: 69.99,
      was: 99.99,
    ),
    (
      id: 'FN-1018',
      title: 'High Waist Butt Lifting Leggings - Black',
      usd: 24.99,
      was: 34.99,
    ),
    (
      id: 'FN-1019',
      title: "Men's Graphic Oversized Tee - Vintage Wash",
      usd: 22.99,
      was: 32.99,
    ),
    (
      id: 'FN-1020',
      title: 'Knee High Pointed Toe Boots - Black Croc',
      usd: 79.99,
      was: 119.99,
    ),
    (
      id: 'FN-1021',
      title: 'Kids Denim Overall Dress - Light Wash',
      usd: 29.99,
      was: 39.99,
    ),
    (
      id: 'FN-1022',
      title: 'Sequin Bodycon Mini Dress - Gold',
      usd: 49.99,
      was: 74.99,
    ),
    (
      id: 'FN-1023',
      title: 'Quilted Shoulder Bag with Chain Strap - Black',
      usd: 34.99,
      was: 49.99,
    ),
    (
      id: 'FN-1024',
      title: 'Cotton Blend Cardigan Set - Butter Yellow',
      usd: 47.99,
      was: 69.99,
    ),
  ];

  static const _plugTech = <_Seed>[
    (
      id: 'PT-2001',
      title: 'Apple iPhone 13 128GB Unlocked - Midnight (Grade A)',
      usd: 379.00,
      was: 499.00,
    ),
    (
      id: 'PT-2002',
      title: 'Apple MacBook Pro 14" M3 16GB 512GB - Space Black',
      usd: 1499.00,
      was: 1699.00,
    ),
    (
      id: 'PT-2003',
      title: 'Samsung Galaxy S23 256GB Unlocked - Phantom Black (Grade A)',
      usd: 449.00,
      was: 649.00,
    ),
    (
      id: 'PT-2004',
      title: 'Apple iPad 9th Gen 64GB Wi-Fi - Silver',
      usd: 219.00,
      was: 329.00,
    ),
    (
      id: 'PT-2005',
      title: 'Apple Watch SE 2nd Gen 40mm GPS - Starlight',
      usd: 189.00,
      was: 249.00,
    ),
    (
      id: 'PT-2006',
      title: 'Anker 65W USB C Charger 3-Port Nano II GaN - White',
      usd: 42.99,
      was: 59.99,
    ),
    (
      id: 'PT-2007',
      title: 'Apple AirPods 4 with Active Noise Cancellation',
      usd: 149.00,
      was: 179.00,
    ),
    (
      id: 'PT-2008',
      title: 'Google Pixel 8a 128GB Unlocked - Aloe',
      usd: 379.00,
      was: 499.00,
    ),
    (
      id: 'PT-2009',
      title: 'Apple iPhone 15 Pro 256GB Unlocked - Natural Titanium',
      usd: 849.00,
      was: 999.00,
    ),
    (
      id: 'PT-2010',
      title: 'Student Bundle: MacBook Air M1 + Sleeve + USB C Hub',
      usd: 749.00,
      was: 899.00,
    ),
    (
      id: 'PT-2011',
      title: 'Samsung Galaxy Watch 6 44mm Bluetooth - Graphite',
      usd: 219.00,
      was: 299.99,
    ),
    (
      id: 'PT-2012',
      title: 'Anker USB C to Lightning Cable 6ft MFi Certified 2-Pack',
      usd: 18.99,
      was: 26.99,
    ),
    (
      id: 'PT-2013',
      title: 'Apple Magic Keyboard for iPad Pro 11" - Black',
      usd: 249.00,
      was: 299.00,
    ),
    (
      id: 'PT-2014',
      title: 'JBL Live 770NC Wireless Over-Ear Headphones - Blue',
      usd: 129.95,
      was: 199.95,
    ),
    (
      id: 'PT-2015',
      title: 'Apple iPhone 12 64GB Unlocked - Blue (Grade B)',
      usd: 249.00,
      was: 349.00,
    ),
    (
      id: 'PT-2016',
      title: 'Baseus 20000mAh 65W Power Bank with Digital Display',
      usd: 54.99,
      was: 79.99,
    ),
    (
      id: 'PT-2017',
      title: 'Samsung Galaxy Buds3 Pro True Wireless Earbuds - White',
      usd: 179.00,
      was: 249.99,
    ),
    (
      id: 'PT-2018',
      title: 'Apple MacBook Air M2 15" 8GB 256GB - Starlight',
      usd: 999.00,
      was: 1299.00,
    ),
    (
      id: 'PT-2019',
      title: 'UGREEN 9-in-1 USB C Docking Station with 4K HDMI',
      usd: 69.99,
      was: 99.99,
    ),
    (
      id: 'PT-2020',
      title: 'Apple iPad Pro 11" M4 256GB Wi-Fi - Silver',
      usd: 949.00,
      was: 1099.00,
    ),
    (
      id: 'PT-2021',
      title: 'Xiaomi Redmi Note 13 Pro 256GB Unlocked - Midnight Black',
      usd: 249.00,
      was: 329.00,
    ),
    (
      id: 'PT-2022',
      title: 'Apple 20W USB C Power Adapter - Original',
      usd: 17.99,
      was: 19.00,
    ),
    (
      id: 'PT-2023',
      title: 'Logitech K380 Multi-Device Bluetooth Keyboard - Off White',
      usd: 34.99,
      was: 49.99,
    ),
    (
      id: 'PT-2024',
      title: 'Sony PlayStation Portal Remote Player for PS5',
      usd: 199.00,
      was: 219.99,
    ),
  ];

  static const _sephora = <_Seed>[
    (
      id: 'SP-3001',
      title: 'Rare Beauty Soft Pinch Liquid Blush - Happy',
      usd: 23.00,
      was: null,
    ),
    (
      id: 'SP-3002',
      title: 'Fenty Beauty Pro Filt\'r Soft Matte Longwear Foundation',
      usd: 40.00,
      was: null,
    ),
    (
      id: 'SP-3003',
      title: 'Drunk Elephant Protini Polypeptide Cream Moisturizer 50ml',
      usd: 68.00,
      was: 78.00,
    ),
    (
      id: 'SP-3004',
      title: 'The Ordinary Niacinamide 10% + Zinc 1% Serum 30ml',
      usd: 6.50,
      was: null,
    ),
    (
      id: 'SP-3005',
      title: 'Charlotte Tilbury Pillow Talk Lipstick - Matte Revolution',
      usd: 35.00,
      was: null,
    ),
    (
      id: 'SP-3006',
      title: 'Olaplex No. 3 Hair Perfector Bond Repair Treatment 100ml',
      usd: 30.00,
      was: 38.00,
    ),
    (
      id: 'SP-3007',
      title: 'Dior Sauvage Eau de Parfum Spray 100ml',
      usd: 125.00,
      was: 155.00,
    ),
    (
      id: 'SP-3008',
      title: 'Laneige Lip Sleeping Mask Intense Hydration - Berry',
      usd: 24.00,
      was: null,
    ),
    (
      id: 'SP-3009',
      title: 'Tatcha The Water Cream Oil-Free Pore Minimizing Moisturizer',
      usd: 72.00,
      was: 82.00,
    ),
    (
      id: 'SP-3010',
      title: 'NARS Radiant Creamy Concealer - Custard',
      usd: 32.00,
      was: null,
    ),
    (
      id: 'SP-3011',
      title: 'Sol de Janeiro Brazilian Bum Bum Body Cream 240ml',
      usd: 48.00,
      was: null,
    ),
    (
      id: 'SP-3012',
      title: 'Glow Recipe Watermelon Glow Niacinamide Dew Drops',
      usd: 35.00,
      was: 42.00,
    ),
    (
      id: 'SP-3013',
      title: 'Anastasia Beverly Hills Brow Wiz Pencil - Medium Brown',
      usd: 25.00,
      was: null,
    ),
    (
      id: 'SP-3014',
      title: 'Kiehl\'s Ultra Facial Cream Daily Moisturizer 125ml',
      usd: 46.00,
      was: 58.00,
    ),
    (
      id: 'SP-3015',
      title: 'Maison Margiela REPLICA Jazz Club Eau de Toilette 100ml',
      usd: 165.00,
      was: 195.00,
    ),
    (
      id: 'SP-3016',
      title: 'Briogeo Don\'t Despair, Repair! Deep Conditioning Mask',
      usd: 38.00,
      was: null,
    ),
    (
      id: 'SP-3017',
      title: 'Huda Beauty Easy Bake Loose Baking Powder - Cinnamon',
      usd: 37.00,
      was: 45.00,
    ),
    (
      id: 'SP-3018',
      title: 'Summer Fridays Jet Lag Mask Hydrating Face Mask 64g',
      usd: 49.00,
      was: null,
    ),
    (
      id: 'SP-3019',
      title: 'Dyson Airwrap Multi-Styler Complete Long - Nickel/Copper',
      usd: 599.99,
      was: 649.99,
    ),
    (
      id: 'SP-3020',
      title: 'Supergoop! Unseen Sunscreen SPF 40 PA+++ 50ml',
      usd: 38.00,
      was: null,
    ),
    (
      id: 'SP-3021',
      title: 'Too Faced Better Than Sex Volumizing Mascara - Black',
      usd: 29.00,
      was: 34.00,
    ),
    (
      id: 'SP-3022',
      title: 'Ouai Detox Shampoo Clarifying Cleanser 300ml',
      usd: 32.00,
      was: null,
    ),
    (
      id: 'SP-3023',
      title: 'Yves Saint Laurent Libre Eau de Parfum 90ml',
      usd: 145.00,
      was: 175.00,
    ),
    (
      id: 'SP-3024',
      title: 'Paula\'s Choice 2% BHA Liquid Exfoliant 118ml',
      usd: 35.00,
      was: 42.00,
    ),
  ];
}
