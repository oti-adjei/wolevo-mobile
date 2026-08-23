import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

import '../data/mock_ship_repository.dart';
import '../data/ship_models.dart';
import '../data/ship_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final shipRepositoryProvider = Provider<ShipRepository>(
  (ref) => MockShipRepository(),
);

/// Which of the three intent cards is selected on the Ship screen. Lives in a
/// provider rather than in the screen's State so that a deep link (e.g. the
/// `Create Shipment` button on `/orders`) can preselect "Already shipped"
/// before the screen builds.
final shipIntentProvider = StateProvider<ShipIntent>(
  (ref) => ShipIntent.yetToShop,
);

/// Submission state for the registration form. `null` data means "not
/// submitted yet"; a value means the success state should render.
class RegisterPackageController
    extends AutoDisposeAsyncNotifier<RegisteredShipment?> {
  @override
  Future<RegisteredShipment?> build() async => null;

  Future<void> submit(PackageRegistration registration) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(shipRepositoryProvider).registerPackage(registration),
    );

    if (state.valueOrNull case final shipment?) {
      ref
          .read(analyticsProvider)
          .track(
            AnalyticsEvents.packageRegistered,
            properties: {
              'destination': shipment.destinationCountry.code,
              // Value is the number the warehouse quotes against, so it is worth
              // having; the tracking number is not, it identifies a real parcel.
              'declared_value_usd': registration.declaredValueUsd,
              'proof_files': registration.proofOfPurchase.length,
              'has_notes': registration.notes?.isNotEmpty ?? false,
            },
          );
    }
  }
}

final registerPackageProvider =
    AutoDisposeAsyncNotifierProvider<
      RegisterPackageController,
      RegisteredShipment?
    >(RegisterPackageController.new);
