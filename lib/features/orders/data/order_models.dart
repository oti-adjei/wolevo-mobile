import 'package:flutter/material.dart';

import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';
import '../../../core/models/retailer.dart';
import '../../../core/theme/app_colors.dart';

/// The status enum exposed by `GET /api/v1/user/fulfillments?status=…`.
/// Values are UPPERCASE, exactly as observed (discovery-notes.md § 3,
/// "Order status enum is UPPERCASE").
enum OrderStatus {
  pending('PENDING', 'Pending'),
  purchased('PURCHASED', 'Purchased'),
  shipped('SHIPPED', 'Shipped'),
  delivered('DELIVERED', 'Delivered'),
  cancelled('CANCELLED', 'Cancelled');

  const OrderStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// ASSUMPTION: the live list was empty, so no status badge was ever rendered.
  /// Colours are assigned from the palette's existing semantic roles: lime for
  /// "waiting on us", mint for "bought", pale green for "moving", success for
  /// "done", red for "stopped".
  Color get background => switch (this) {
    OrderStatus.pending => AppColors.tertiary,
    OrderStatus.purchased => AppColors.secondary2,
    OrderStatus.shipped => AppColors.primary2,
    OrderStatus.delivered => AppColors.success,
    OrderStatus.cancelled => AppColors.error3,
  };

  Color get foreground => switch (this) {
    OrderStatus.pending => AppColors.secondary,
    OrderStatus.purchased => AppColors.secondary,
    OrderStatus.shipped => AppColors.secondary,
    OrderStatus.delivered => Colors.white,
    OrderStatus.cancelled => AppColors.error,
  };

  static OrderStatus fromApi(String value) => values.firstWhere(
    (s) => s.apiValue == value.toUpperCase(),
    orElse: () => OrderStatus.pending,
  );
}

/// `/user/fulfillments` is deliberately not called `/orders`: the list mixes
/// proxy-buy orders (Wolevo bought it for you) with self-registered forwarded
/// shipments (you shipped it to your locker yourself). Both flows converge on
/// the same list — see discovery-notes.md § 2.3, "unified list of purchases and
/// forwarded shipments".
enum FulfillmentKind {
  order('ORDER', 'Order'),
  shipment('SHIPMENT', 'Shipment');

  const FulfillmentKind(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static FulfillmentKind fromApi(String value) => values.firstWhere(
    (k) => k.apiValue == value.toUpperCase(),
    orElse: () => FulfillmentKind.order,
  );
}

/// The stages of the tracking timeline.
///
/// ASSUMPTION: never observed. Derived from the 5-step journey stepper on
/// `/ship` (Shop & ship to locker → Register package → We receive & weigh →
/// Quote & pay → Delivered to you) plus the customs/last-mile reality of the
/// Ghana/Nigeria corridor. [readyForPickup] exists because the marketing copy
/// advertises "Delivery or Pickup" — a fulfillment ends in one or the other,
/// never both.
enum TrackingStage {
  ordered('ORDERED', 'Ordered'),
  receivedAtWarehouse('RECEIVED_AT_WAREHOUSE', 'Received at Warehouse'),
  shipped('SHIPPED', 'Shipped'),
  inCustoms('IN_CUSTOMS', 'In Customs'),
  outForDelivery('OUT_FOR_DELIVERY', 'Out for Delivery'),
  delivered('DELIVERED', 'Delivered'),
  readyForPickup('READY_FOR_PICKUP', 'Ready for Pickup');

  const TrackingStage(this.apiValue, this.label);

  final String apiValue;
  final String label;

  IconData get icon => switch (this) {
    TrackingStage.ordered => Icons.receipt_long_outlined,
    TrackingStage.receivedAtWarehouse => Icons.warehouse_outlined,
    TrackingStage.shipped => Icons.flight_takeoff_outlined,
    TrackingStage.inCustoms => Icons.gavel_outlined,
    TrackingStage.outForDelivery => Icons.local_shipping_outlined,
    TrackingStage.delivered => Icons.check_circle_outline,
    TrackingStage.readyForPickup => Icons.storefront_outlined,
  };

  static TrackingStage fromApi(String value) => values.firstWhere(
    (s) => s.apiValue == value.toUpperCase(),
    orElse: () => TrackingStage.ordered,
  );
}

/// One node on the vertical timeline. Future stages carry no [timestamp].
class TrackingEvent {
  const TrackingEvent({
    required this.stage,
    required this.label,
    required this.description,
    required this.completed,
    this.timestamp,
  });

  final TrackingStage stage;

  /// Server-supplied label. Falls back to [TrackingStage.label] in mock data,
  /// but the API is free to localise or specialise it ("Ready for Pickup").
  final String label;

  final String description;

  /// Null for stages that have not happened yet.
  final DateTime? timestamp;

  final bool completed;

  factory TrackingEvent.fromJson(Map<String, dynamic> json) => TrackingEvent(
    stage: TrackingStage.fromApi(json['stage'] as String),
    label: json['label'] as String,
    description: json['description'] as String? ?? '',
    completed: json['completed'] as bool? ?? false,
    timestamp: json['timestamp'] == null
        ? null
        : DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'stage': stage.apiValue,
    'label': label,
    'description': description,
    'completed': completed,
    'timestamp': timestamp?.toIso8601String(),
  };
}

/// One line item inside a proxy-buy order.
class FulfillmentItem {
  const FulfillmentItem({
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.retailer,
    this.imageUrl,
  });

  final String title;

  /// Part of the API shape (images are served through the Cloudflare image
  /// proxy). No product images are bundled with the app, so the UI renders
  /// `OrderItemThumb` instead of loading this — the field stays for parity.
  final String? imageUrl;

  final int quantity;
  final Money unitPrice;
  final Retailer retailer;

  Money get lineTotal => unitPrice * quantity;

  factory FulfillmentItem.fromJson(Map<String, dynamic> json) =>
      FulfillmentItem(
        title: json['title'] as String,
        imageUrl: json['imageUrl'] as String?,
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: Money.fromJson(json['unitPrice'] as Map<String, dynamic>),
        retailer: Retailer.fromApi(json['retailer'] as String),
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'imageUrl': imageUrl,
    'quantity': quantity,
    'unitPrice': unitPrice.toJson(),
    'retailer': retailer.apiValue,
  };
}

/// The cost summary. Nullable components render as "Calculated at checkout",
/// exactly as the cart sidebar does before a destination quote exists
/// (discovery-notes.md § 2.4).
class CostBreakdown {
  const CostBreakdown({
    required this.subtotal,
    required this.total,
    this.retailerShipping,
    this.shippingToDestination,
    this.handling,
  });

  final Money subtotal;
  final Money? retailerShipping;
  final Money? shippingToDestination;
  final Money? handling;
  final Money total;

  /// True while any component is still unpriced — the cart shows `$187.68+`
  /// with a trailing plus in this case.
  bool get isEstimate =>
      retailerShipping == null ||
      shippingToDestination == null ||
      handling == null;

  factory CostBreakdown.fromJson(Map<String, dynamic> json) => CostBreakdown(
    subtotal: Money.fromJson(json['subtotal'] as Map<String, dynamic>),
    retailerShipping: json['retailerShipping'] == null
        ? null
        : Money.fromJson(json['retailerShipping'] as Map<String, dynamic>),
    shippingToDestination: json['shippingToDestination'] == null
        ? null
        : Money.fromJson(json['shippingToDestination'] as Map<String, dynamic>),
    handling: json['handling'] == null
        ? null
        : Money.fromJson(json['handling'] as Map<String, dynamic>),
    total: Money.fromJson(json['total'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'subtotal': subtotal.toJson(),
    'retailerShipping': retailerShipping?.toJson(),
    'shippingToDestination': shippingToDestination?.toJson(),
    'handling': handling?.toJson(),
    'total': total.toJson(),
  };
}

/// The delivery address as it is echoed back on a fulfillment. `nearestLandmark`
/// is a first-class field in Ghana/Nigeria addressing and must not be dropped
/// (discovery-notes.md § 4, item 2).
class DeliveryAddressSummary {
  const DeliveryAddressSummary({
    required this.line1,
    required this.city,
    required this.region,
    required this.countryName,
    this.nearestLandmark,
  });

  final String line1;
  final String city;
  final String region;
  final String countryName;
  final String? nearestLandmark;

  /// `8 Bia Rd, Accra, Greater Accra, Ghana` — the format the cart's address
  /// select uses verbatim.
  String get formatted => [line1, city, region, countryName].join(', ');

  factory DeliveryAddressSummary.fromJson(Map<String, dynamic> json) =>
      DeliveryAddressSummary(
        line1: json['line1'] as String,
        city: json['city'] as String,
        region: json['region'] as String,
        countryName: json['countryName'] as String,
        nearestLandmark: json['nearestLandmark'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'line1': line1,
    'city': city,
    'region': region,
    'countryName': countryName,
    'nearestLandmark': nearestLandmark,
  };
}

/// A row in `GET /api/v1/user/fulfillments`, and the payload of the detail
/// screen. One type covers both proxy-buy orders and forwarded shipments; the
/// [kind] discriminates and decides which fields are populated.
class Fulfillment {
  const Fulfillment({
    required this.id,
    required this.reference,
    required this.kind,
    required this.status,
    required this.createdAt,
    required this.itemCount,
    required this.total,
    required this.destinationCountry,
    required this.items,
    required this.timeline,
    required this.deliveryAddress,
    required this.costs,
    this.retailer,
    this.trackingNumber,
  });

  final String id;

  /// Human-facing identifier, e.g. `WLV-10241`. This is the "order ID" the
  /// search field asks for.
  final String reference;

  final FulfillmentKind kind;
  final OrderStatus status;
  final DateTime createdAt;

  /// Null for forwarded shipments — nobody bought those on the user's behalf.
  final Retailer? retailer;

  /// The store's tracking number, present on shipments the user registered and
  /// on orders once they leave the warehouse.
  final String? trackingNumber;

  final int itemCount;
  final Money total;
  final DestinationCountry destinationCountry;
  final List<FulfillmentItem> items;
  final List<TrackingEvent> timeline;
  final DeliveryAddressSummary deliveryAddress;
  final CostBreakdown costs;

  /// The line under the reference on a list card.
  String get sourceLabel => retailer?.label ?? 'Forwarded shipment';

  /// The stage the parcel is at right now: the first incomplete node, or the
  /// last node once everything is done.
  TrackingEvent? get currentEvent {
    if (timeline.isEmpty) return null;
    for (final event in timeline) {
      if (!event.completed) return event;
    }
    return timeline.last;
  }

  factory Fulfillment.fromJson(Map<String, dynamic> json) => Fulfillment(
    id: json['id'] as String,
    reference: json['reference'] as String,
    kind: FulfillmentKind.fromApi(json['kind'] as String),
    status: OrderStatus.fromApi(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    retailer: json['retailer'] == null
        ? null
        : Retailer.fromApi(json['retailer'] as String),
    trackingNumber: json['trackingNumber'] as String?,
    itemCount: (json['itemCount'] as num).toInt(),
    total: Money.fromJson(json['total'] as Map<String, dynamic>),
    destinationCountry: DestinationCountry.fromCode(
      json['destinationCountryCode'] as String,
    ),
    items: (json['items'] as List<dynamic>? ?? const [])
        .map((e) => FulfillmentItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    timeline: (json['timeline'] as List<dynamic>? ?? const [])
        .map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
        .toList(),
    deliveryAddress: DeliveryAddressSummary.fromJson(
      json['deliveryAddress'] as Map<String, dynamic>,
    ),
    costs: CostBreakdown.fromJson(json['costs'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'kind': kind.apiValue,
    'status': status.apiValue,
    'createdAt': createdAt.toIso8601String(),
    'retailer': retailer?.apiValue,
    'trackingNumber': trackingNumber,
    'itemCount': itemCount,
    'total': total.toJson(),
    'destinationCountryCode': destinationCountry.code,
    'items': items.map((e) => e.toJson()).toList(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'deliveryAddress': deliveryAddress.toJson(),
    'costs': costs.toJson(),
  };
}
