import '../../../core/models/destination_country.dart';
import '../../../core/models/money.dart';

/// The three "how did the package get to us" intents the `/ship` page offers.
/// Selecting one swaps the content below the cards *and* the CTA labels — see
/// discovery-notes.md § 2.2 and § "Anything else notable", item 8.
enum ShipIntent {
  yetToShop(title: "I'm yet to shop", subtitle: 'Shop any US store'),
  someoneSending(
    title: 'Someone is sending to me',
    subtitle: 'Friend or family sending',
  ),
  alreadyShipped(
    title: 'Already shipped',
    subtitle: 'Have your tracking number',
  );

  const ShipIntent({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// A single receipt / invoice attached to a registration.
///
/// [path] is a local file path from `file_picker`. A real implementation
/// streams it as a multipart part rather than serialising it into JSON.
class ProofFile {
  const ProofFile({
    required this.name,
    required this.sizeBytes,
    required this.path,
  });

  final String name;
  final int sizeBytes;
  final String path;

  /// `1.4 MB` / `812 KB` — matches how the web uploader labels a picked file.
  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / 1024).ceil()} KB';
  }
}

/// The `PACKAGE DETAILS` form payload.
class PackageRegistration {
  const PackageRegistration({
    required this.destinationCountryCode,
    required this.trackingNumber,
    required this.declaredValueUsd,
    required this.proofOfPurchase,
    this.notes,
  });

  final String destinationCountryCode;
  final String trackingNumber;
  final double declaredValueUsd;
  final String? notes;
  final List<ProofFile> proofOfPurchase;

  DestinationCountry get destinationCountry =>
      DestinationCountry.fromCode(destinationCountryCode);

  /// ASSUMPTION: the submit endpoint was never exercised during discovery
  /// (discovery-notes.md § 3 — "Shipment registration submit … the POST
  /// endpoint is therefore unknown"), so both the field names and the shape
  /// below are inferred from the sibling payloads that *were* captured
  /// (`destinationCountryCode` on the shipping-estimate call, `pagination.*`
  /// on fulfillments).
  ///
  /// ASSUMPTION: in a real implementation this is sent as `multipart/form-data`
  /// — these scalar fields as form fields, and each [ProofFile] as its own
  /// `proofOfPurchase[]` file part. The map below is the field half only; the
  /// files are attached by the Dio repository, not encoded here.
  Map<String, dynamic> toJson() => {
    'destinationCountryCode': destinationCountryCode,
    'trackingNumber': trackingNumber,
    'declaredValueUsd': declaredValueUsd,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
    'proofOfPurchase': [
      for (final f in proofOfPurchase)
        {'name': f.name, 'sizeBytes': f.sizeBytes},
    ],
  };
}

/// ASSUMPTION: the status vocabulary is taken from the `/orders` status chips
/// that *were* captured (Pending · Purchased · Shipped · Delivered · Cancelled)
/// plus the 5-step journey stepper on `/ship`.
enum ShipmentStatus {
  pending('PENDING', 'Pending'),
  received('RECEIVED', 'Received & weighed'),
  quoted('QUOTED', 'Quote ready'),
  paid('PAID', 'Paid'),
  shipped('SHIPPED', 'Shipped'),
  delivered('DELIVERED', 'Delivered');

  const ShipmentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ShipmentStatus fromApi(String v) => values.firstWhere(
    (s) => s.apiValue == v.toUpperCase(),
    orElse: () => ShipmentStatus.pending,
  );
}

/// What the server hands back once a package has been registered.
class RegisteredShipment {
  const RegisteredShipment({
    required this.id,
    required this.trackingNumber,
    required this.status,
    required this.createdAt,
    required this.declaredValue,
    required this.destinationCountry,
  });

  final String id;
  final String trackingNumber;
  final ShipmentStatus status;
  final DateTime createdAt;
  final Money declaredValue;
  final DestinationCountry destinationCountry;

  factory RegisteredShipment.fromJson(Map<String, dynamic> json) =>
      RegisteredShipment(
        id: json['id'] as String,
        trackingNumber: json['trackingNumber'] as String,
        status: ShipmentStatus.fromApi(json['status'] as String? ?? 'PENDING'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        declaredValue: Money.fromJson(
          json['declaredValue'] as Map<String, dynamic>,
        ),
        destinationCountry: DestinationCountry.fromCode(
          json['destinationCountryCode'] as String? ?? 'GH',
        ),
      );
}
