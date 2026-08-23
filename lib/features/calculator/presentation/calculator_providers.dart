import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

import '../data/calculator_models.dart';
import '../data/calculator_repository.dart';
import '../data/mock_calculator_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final calculatorRepositoryProvider = Provider<CalculatorRepository>(
  (ref) => MockCalculatorRepository(),
);

/// Estimate state for the calculator card. `null` data means "nothing quoted
/// yet", which is the placeholder state the panel renders before the first
/// `Get Estimate`.
class CalculatorController extends AutoDisposeAsyncNotifier<ShippingEstimate?> {
  @override
  Future<ShippingEstimate?> build() async => null;

  Future<void> submit(ShippingEstimateRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(calculatorRepositoryProvider).estimate(request),
    );

    if (state.valueOrNull case final estimate?) {
      // The calculator is public, so this often fires before signup — it is the
      // top of the funnel, not a logged-in action.
      ref
          .read(analyticsProvider)
          .track(
            AnalyticsEvents.shippingEstimated,
            properties: {
              'mode': request.mode.name,
              'destination': request.destinationCountryCode,
              'shipping_usd': estimate.shipping.usd,
            },
          );
    }
  }

  /// `Get Another Quote` — clears the result so the form comes back.
  void reset() => state = const AsyncValue.data(null);
}

final calculatorEstimateProvider =
    AutoDisposeAsyncNotifierProvider<CalculatorController, ShippingEstimate?>(
      CalculatorController.new,
    );
