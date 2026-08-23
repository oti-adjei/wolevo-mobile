import 'ship_models.dart';

/// The Ship data surface.
///
/// ASSUMPTION: the live site's `Next` button was deliberately never pressed
/// during discovery (it would have created a real shipment record), so the
/// endpoint below is inferred from the rest of the API's shape:
/// `POST /api/v1/shipments`, `multipart/form-data`, returning the created
/// shipment. Swap [MockShipRepository] for a Dio-backed implementation to go
/// live; the providers only ever see this interface.
abstract interface class ShipRepository {
  /// Registers a package the user has already shipped to their locker.
  Future<RegisteredShipment> registerPackage(PackageRegistration r);
}
