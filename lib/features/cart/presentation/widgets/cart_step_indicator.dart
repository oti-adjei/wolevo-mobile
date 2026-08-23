import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// The cart's two-node stepper: `1 Items` — `2 Delivery`.
///
/// Two short labels fit a 375px viewport comfortably, so unlike the five-node
/// ship journey this one stays horizontal, exactly as the web draws it.
class CartStepIndicator extends StatelessWidget {
  const CartStepIndicator({super.key, required this.currentIndex, this.onStepTapped});

  /// Zero-based: 0 = Items, 1 = Delivery.
  final int currentIndex;

  /// Only a passed step is tappable — the web does not let you skip ahead.
  final ValueChanged<int>? onStepTapped;

  static const _labels = <String>['Items', 'Delivery'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                color: i <= currentIndex ? AppColors.secondary : AppColors.surface4,
              ),
            ),
          _StepNode(
            index: i,
            label: _labels[i],
            completed: i < currentIndex,
            current: i == currentIndex,
            onTap: i < currentIndex && onStepTapped != null
                ? () => onStepTapped!(i)
                : null,
          ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.completed,
    required this.current,
    this.onTap,
  });

  final int index;
  final String label;
  final bool completed;
  final bool current;
  final VoidCallback? onTap;

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

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rPill,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 26,
              width: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: nodeColor, shape: BoxShape.circle),
              child: completed
                  ? Icon(Icons.check, size: 15, color: nodeForeground)
                  : Text(
                      '${index + 1}',
                      style: AppText.body14Semibold.copyWith(color: nodeForeground),
                    ),
            ),
            const SizedBox(width: AppSpace.sm),
            Text(
              label,
              style: current || completed
                  ? AppText.body14Semibold
                  : AppText.body14.copyWith(color: AppColors.neutral1),
            ),
          ],
        ),
      ),
    );
  }
}
