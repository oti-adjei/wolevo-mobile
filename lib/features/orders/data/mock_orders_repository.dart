import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import 'order_models.dart';
import 'orders_repository.dart';

/// In-memory stand-in for `GET /user/fulfillments`.
///
/// The live account had **zero** fulfillments during discovery, so none of this
/// data was observed — it is constructed so every state the screens can render
/// is reachable while building: all five statuses, both kinds, orders with and
/// without a tracking number, a fully-priced cost breakdown and a partially
/// quoted one, an address with a nearest landmark and one without, and a
/// delivery that ends in pickup rather than a doorstep drop.
///
/// Product titles and prices are the ones quoted verbatim in discovery-notes.md
/// where available (`usb c cable` at `$9.99`, `$187.68` cart subtotal, `$2.09`
/// ship-to-Ghana, `$20.00` weight-based shipping); the rest is plausible filler.
class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository({this.country = DestinationCountry.ghana});

  /// Prices arrive pre-converted from the API, so the mock needs to know which
  /// currency to mint. In the app this is the signed-in user's destination.
  final DestinationCountry country;

  // ASSUMPTION: matches the latency budget used by the other mock repositories.
  static const _latency = Duration(milliseconds: 500);

  /// A fixed "today" so the seeded dates stay stable between runs.
  static final _now = DateTime(2026, 8, 23);

  List<Fulfillment>? _cache;

  List<Fulfillment> get _all => _cache ??= _seed();

  @override
  Future<Paged<Fulfillment>> list({
    OrderStatus? status,
    String? query,
    Pagination pagination = const Pagination(),
  }) async {
    await Future<void>.delayed(_latency);

    final needle = query?.trim().toLowerCase() ?? '';
    final matches = _all.where((f) {
      if (status != null && f.status != status) return false;
      if (needle.isEmpty) return true;
      if (f.reference.toLowerCase().contains(needle)) return true;
      if ((f.trackingNumber ?? '').toLowerCase().contains(needle)) return true;
      return f.items.any((i) => i.title.toLowerCase().contains(needle));
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (pagination.pageNumber - 1) * pagination.pageSize;
    if (start >= matches.length) {
      return Paged<Fulfillment>(
        items: const [],
        pageNumber: pagination.pageNumber,
        hasMore: false,
      );
    }
    final end = (start + pagination.pageSize).clamp(0, matches.length);
    return Paged<Fulfillment>(
      items: matches.sublist(start, end),
      pageNumber: pagination.pageNumber,
      hasMore: end < matches.length,
    );
  }

  @override
  Future<Fulfillment> byId(String id) async {
    await Future<void>.delayed(_latency);
    for (final f in _all) {
      if (f.id == id || f.reference == id) return f;
    }
    throw StateError('No fulfillment matches "$id".');
  }

  // ---------------------------------------------------------------------------
  // Seed
  // ---------------------------------------------------------------------------

  Money _m(double usd) => Money.mock(usd, country);

  DateTime _daysAgo(int days) => _now.subtract(Duration(days: days));

  static const _accra = DeliveryAddressSummary(
    line1: '8 Bia Rd',
    city: 'Accra',
    region: 'Greater Accra',
    countryName: 'Ghana',
    nearestLandmark: 'Omanye Lodge',
  );

  static const _tema = DeliveryAddressSummary(
    line1: '14 Hospital Road, Community 5',
    city: 'Tema',
    region: 'Greater Accra',
    countryName: 'Ghana',
  );

  /// Builds the six-node journey. [completedThrough] is the index of the last
  /// finished stage (-1 = nothing done yet); the node after it is "current" and
  /// everything beyond is a future stage with no timestamp.
  ///
  /// ASSUMPTION: stage labels and copy are inferred from the `/ship` journey
  /// stepper (Shop & ship to locker → Register package → We receive & weigh →
  /// Quote & pay → Delivered to you).
  List<TrackingEvent> _timeline({
    required DateTime createdAt,
    required int completedThrough,
    bool pickup = false,
    bool cancelled = false,
  }) {
    final stages = <TrackingStage>[
      TrackingStage.ordered,
      TrackingStage.receivedAtWarehouse,
      TrackingStage.shipped,
      TrackingStage.inCustoms,
      TrackingStage.outForDelivery,
      pickup ? TrackingStage.readyForPickup : TrackingStage.delivered,
    ];

    const descriptions = <TrackingStage, String>{
      TrackingStage.ordered: 'We received your order and started processing it.',
      TrackingStage.receivedAtWarehouse:
          'Your package arrived at our Delaware warehouse and was weighed.',
      TrackingStage.shipped: 'Your package left the US warehouse.',
      TrackingStage.inCustoms: 'Clearing import duties at the destination port.',
      TrackingStage.outForDelivery: 'A courier is on the way to your address.',
      TrackingStage.delivered: 'Handed over at your delivery address.',
      TrackingStage.readyForPickup: 'Waiting for you at the Accra pickup point.',
    };

    // Roughly a stage every two days — enough to make the timestamps read as a
    // real journey rather than a single burst.
    return [
      for (var i = 0; i < stages.length; i++)
        TrackingEvent(
          stage: stages[i],
          label: stages[i].label,
          description: cancelled && i > completedThrough
              ? 'Cancelled before this step.'
              : descriptions[stages[i]]!,
          completed: i <= completedThrough,
          timestamp: i <= completedThrough
              ? createdAt.add(Duration(days: i * 2, hours: 3 + i))
              : null,
        ),
    ];
  }

  List<Fulfillment> _seed() {
    return [
      // 1 — proxy-buy order, PENDING, not yet quoted end-to-end.
      Fulfillment(
        id: 'ful_10241',
        reference: 'WLV-10241',
        kind: FulfillmentKind.order,
        status: OrderStatus.pending,
        createdAt: _daysAgo(11),
        retailer: Retailer.amazon,
        trackingNumber: null,
        itemCount: 3,
        total: _m(187.68),
        destinationCountry: country,
        deliveryAddress: _accra,
        items: [
          FulfillmentItem(
            title: 'Anker USB C Cable 6ft, 100W Fast Charging Nylon Braided',
            imageUrl: 'https://m.media-amazon.com/images/I/61example1.jpg',
            quantity: 2,
            unitPrice: _m(9.99),
            retailer: Retailer.amazon,
          ),
          FulfillmentItem(
            title: 'Echo Dot (5th Gen) Smart Speaker with Alexa, Charcoal',
            imageUrl: 'https://m.media-amazon.com/images/I/61example2.jpg',
            quantity: 1,
            unitPrice: _m(49.99),
            retailer: Retailer.amazon,
          ),
          FulfillmentItem(
            title: 'Logitech MX Master 3S Wireless Performance Mouse',
            imageUrl: 'https://m.media-amazon.com/images/I/61example3.jpg',
            quantity: 1,
            unitPrice: _m(117.71),
            retailer: Retailer.amazon,
          ),
        ],
        // The cart shows "Calculated at checkout" for both shipping lines until
        // a destination quote exists — a PENDING order is in exactly that state.
        costs: CostBreakdown(
          subtotal: _m(187.68),
          retailerShipping: null,
          shippingToDestination: null,
          handling: null,
          total: _m(187.68),
        ),
        timeline: _timeline(createdAt: _daysAgo(11), completedThrough: 0),
      ),

      // 2 — self-registered forwarded shipment, PENDING, no retailer.
      Fulfillment(
        id: 'ful_10238',
        reference: 'WLV-10238',
        kind: FulfillmentKind.shipment,
        status: OrderStatus.pending,
        createdAt: _daysAgo(9),
        retailer: null,
        trackingNumber: '1Z999AA10123456784',
        itemCount: 1,
        total: _m(140.00),
        destinationCountry: country,
        deliveryAddress: _tema,
        items: [
          FulfillmentItem(
            title: 'Package from Nike.com — declared value \$140.00',
            imageUrl: null,
            quantity: 1,
            unitPrice: _m(140.00),
            retailer: Retailer.amazon,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(140.00),
          retailerShipping: null,
          shippingToDestination: null,
          handling: null,
          total: _m(140.00),
        ),
        timeline: _timeline(createdAt: _daysAgo(9), completedThrough: 0),
      ),

      // 3 — order Wolevo has bought but not yet shipped out.
      Fulfillment(
        id: 'ful_10233',
        reference: 'WLV-10233',
        kind: FulfillmentKind.order,
        status: OrderStatus.purchased,
        createdAt: _daysAgo(18),
        retailer: Retailer.fashionNova,
        trackingNumber: null,
        itemCount: 4,
        total: _m(126.42),
        destinationCountry: country,
        deliveryAddress: _accra,
        items: [
          FulfillmentItem(
            title: 'High Waist Straight Leg Jeans — Dark Wash',
            imageUrl: null,
            quantity: 2,
            unitPrice: _m(34.99),
            retailer: Retailer.fashionNova,
          ),
          FulfillmentItem(
            title: 'Ribbed Knit Bodysuit — Black',
            imageUrl: null,
            quantity: 2,
            unitPrice: _m(19.99),
            retailer: Retailer.fashionNova,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(109.96),
          retailerShipping: _m(0),
          shippingToDestination: _m(12.46),
          handling: null,
          total: _m(122.42),
        ),
        timeline: _timeline(createdAt: _daysAgo(18), completedThrough: 1),
      ),

      // 4 — forwarded shipment in transit, tracking number copyable.
      Fulfillment(
        id: 'ful_10227',
        reference: 'WLV-10227',
        kind: FulfillmentKind.shipment,
        status: OrderStatus.shipped,
        createdAt: _daysAgo(24),
        retailer: null,
        trackingNumber: '9400111899223197428490',
        itemCount: 2,
        total: _m(83.40),
        destinationCountry: country,
        deliveryAddress: _tema,
        items: [
          FulfillmentItem(
            title: 'Package from Walmart — 2 items, 6.2 lbs',
            imageUrl: null,
            quantity: 2,
            unitPrice: _m(31.70),
            retailer: Retailer.bestBuy,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(63.40),
          retailerShipping: null,
          shippingToDestination: _m(20.00),
          handling: _m(0),
          total: _m(83.40),
        ),
        timeline: _timeline(createdAt: _daysAgo(24), completedThrough: 2),
      ),

      // 5 — proxy-buy order in customs.
      Fulfillment(
        id: 'ful_10219',
        reference: 'WLV-10219',
        kind: FulfillmentKind.order,
        status: OrderStatus.shipped,
        createdAt: _daysAgo(31),
        retailer: Retailer.bestBuy,
        trackingNumber: '9261290306531234567890',
        itemCount: 1,
        total: _m(348.07),
        destinationCountry: country,
        deliveryAddress: _accra,
        items: [
          FulfillmentItem(
            title: 'Sony WH-1000XM5 Wireless Noise Cancelling Headphones',
            imageUrl: null,
            quantity: 1,
            unitPrice: _m(328.00),
            retailer: Retailer.bestBuy,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(328.00),
          retailerShipping: _m(0),
          shippingToDestination: _m(18.07),
          handling: _m(2.00),
          total: _m(348.07),
        ),
        timeline: _timeline(createdAt: _daysAgo(31), completedThrough: 3),
      ),

      // 6 — completed order that ended in pickup rather than doorstep delivery.
      Fulfillment(
        id: 'ful_10204',
        reference: 'WLV-10204',
        kind: FulfillmentKind.order,
        status: OrderStatus.delivered,
        createdAt: _daysAgo(46),
        retailer: Retailer.sephora,
        trackingNumber: '9405511899223197428123',
        itemCount: 3,
        total: _m(154.18),
        destinationCountry: country,
        deliveryAddress: _accra,
        items: [
          FulfillmentItem(
            title: 'Dior Sauvage Eau de Parfum 100ml',
            imageUrl: null,
            quantity: 1,
            unitPrice: _m(112.00),
            retailer: Retailer.sephora,
          ),
          FulfillmentItem(
            title: 'Laneige Lip Sleeping Mask — Berry',
            imageUrl: null,
            quantity: 2,
            unitPrice: _m(12.00),
            retailer: Retailer.sephora,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(136.00),
          retailerShipping: _m(0),
          shippingToDestination: _m(16.18),
          handling: _m(2.00),
          total: _m(154.18),
        ),
        timeline: _timeline(
          createdAt: _daysAgo(46),
          completedThrough: 5,
          pickup: true,
        ),
      ),

      // 7 — cancelled order: stopped after the warehouse step.
      Fulfillment(
        id: 'ful_10198',
        reference: 'WLV-10198',
        kind: FulfillmentKind.order,
        status: OrderStatus.cancelled,
        createdAt: _daysAgo(58),
        retailer: Retailer.ebay,
        trackingNumber: null,
        itemCount: 1,
        total: _m(45.50),
        destinationCountry: country,
        deliveryAddress: _accra,
        items: [
          FulfillmentItem(
            title: 'Refurbished Nintendo Switch Joy-Con Pair — Neon',
            imageUrl: null,
            quantity: 1,
            unitPrice: _m(45.50),
            retailer: Retailer.ebay,
          ),
        ],
        costs: CostBreakdown(
          subtotal: _m(45.50),
          retailerShipping: null,
          shippingToDestination: null,
          handling: null,
          total: _m(45.50),
        ),
        timeline: _timeline(
          createdAt: _daysAgo(58),
          completedThrough: 0,
          cancelled: true,
        ),
      ),
    ];
  }
}
