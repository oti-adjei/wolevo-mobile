import 'calculator_models.dart';

/// Backed by `POST /api/v1/public/shipping-estimate`.
///
/// This endpoint sits under `public/`, so it works logged out — the calculator
/// is reachable at `/calculator` and embedded on the landing page without a
/// session (discovery-notes.md § 2.9, § "Logged-out").
abstract interface class CalculatorRepository {
  Future<ShippingEstimate> estimate(ShippingEstimateRequest request);
}
