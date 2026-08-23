import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// The 5-step package journey shown once the user is registering a package.
///
/// MOBILE ADAPTATION: the web draws this as a horizontal rail of five numbered
/// nodes joined by connector lines. Five labelled nodes do not fit a 375px
/// viewport (each label is 2–3 words), so on a phone it is rendered vertically,
/// with the connector running down the left gutter between the nodes.
class ShipJourneyStepper extends StatelessWidget {
  const ShipJourneyStepper({super.key, this.currentIndex = 1});

  /// Zero-based. Step 1 (`Shop & ship to locker`) is complete by the time the
  /// user reaches this screen, so step 2 is the default "you are here".
  final int currentIndex;

  static const steps = <String>[
    'Shop & ship to locker',
    'Register package',
    'We receive & weigh',
    'Quote & pay',
    'Delivered to you',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            _JourneyRow(
              index: i,
              label: steps[i],
              completed: i < currentIndex,
              current: i == currentIndex,
              last: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.index,
    required this.label,
    required this.completed,
    required this.current,
    required this.last,
  });

  final int index;
  final String label;
  final bool completed;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final Color nodeColor = completed
        ? AppColors.secondary
        : current
            ? AppColors.tertiary
            : AppColors.surface3;
    final Color nodeForeground = completed
        ? Colors.white
        : current
            ? AppColors.secondary
            : AppColors.neutral2;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                height: 28,
                width: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: nodeColor, shape: BoxShape.circle),
                child: completed
                    ? Icon(Icons.check, size: 16, color: nodeForeground)
                    : Text(
                        '${index + 1}',
                        style: AppText.body14Semibold.copyWith(color: nodeForeground),
                      ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: completed ? AppColors.secondary2 : AppColors.surface3,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 4, bottom: last ? 0 : AppSpace.lg),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: current || completed
                          ? AppText.body14Semibold
                          : AppText.body14.copyWith(color: AppColors.neutral1),
                    ),
                  ),
                  if (current) ...[
                    const SizedBox(width: AppSpace.sm),
                    const MicroBadge(label: "YOU'RE HERE"),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
