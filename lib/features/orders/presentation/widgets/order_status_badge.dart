import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../data/order_models.dart';

/// The status pill on a list card and in the detail app bar. Uses the shared
/// [MicroBadge] (10px/600 uppercase, letter-spaced) so it matches the site's
/// `PRIMARY` / `YOU'RE HERE` badges exactly.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    return MicroBadge(
      label: status.label,
      background: status.background,
      foreground: status.foreground,
    );
  }
}
