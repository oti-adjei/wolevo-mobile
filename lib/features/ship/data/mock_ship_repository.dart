import 'dart:math';

import '../../../core/models/money.dart';
import 'ship_models.dart';
import 'ship_repository.dart';

/// In-memory stand-in for the real registration endpoint. Keeps the same
/// latency feel as the rest of the mock layer (~800ms) so loading states are
/// exercised in development.
class MockShipRepository implements ShipRepository {
  MockShipRepository();

  final _random = Random();
  final List<RegisteredShipment> _registered = [];

  /// Everything registered in this session — useful for a future
  /// "your shipments" list without touching the network.
  List<RegisteredShipment> get registered => List.unmodifiable(_registered);

  @override
  Future<RegisteredShipment> registerPackage(PackageRegistration r) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    // ASSUMPTION: the site never showed a created shipment, so the ID format is
    // modelled on the `WLV-####` shape used elsewhere in the product copy.
    final id = 'WLV-${4000 + _random.nextInt(1000)}';
    final country = r.destinationCountry;

    final shipment = RegisteredShipment(
      id: id,
      trackingNumber: r.trackingNumber,
      status: ShipmentStatus.pending,
      createdAt: DateTime.now(),
      declaredValue: Money.mock(r.declaredValueUsd, country),
      destinationCountry: country,
    );
    _registered.add(shipment);
    return shipment;
  }
}
