import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';

/// One numbered row inside an explainer card.
class ExplainerStep {
  const ExplainerStep(this.title, this.body);

  final String title;
  final String body;
}

/// The "three steps" explainer that sits under the intent cards for the
/// `yetToShop` and `someoneSending` modes. Copy is verbatim from the site.
class IntentExplainerCard extends StatelessWidget {
  const IntentExplainerCard({
    super.key,
    required this.title,
    required this.intro,
    required this.steps,
    required this.actions,
  });

  final String title;
  final String intro;
  final List<ExplainerStep> steps;

  /// Primary CTA + inline text link, already built by the caller so each mode
  /// keeps its own labels and behaviour.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.cardTitle),
          const SizedBox(height: AppSpace.sm),
          Text(intro, style: AppText.body14.copyWith(color: AppColors.neutral1)),
          const SizedBox(height: AppSpace.xl),
          for (var i = 0; i < steps.length; i++) ...[
            _NumberedStep(index: i + 1, step: steps[i]),
            if (i != steps.length - 1) const SizedBox(height: AppSpace.lg),
          ],
          const SizedBox(height: AppSpace.xl),
          ...actions,
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.step});

  final int index;
  final ExplainerStep step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          width: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary2,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: AppText.body14Semibold.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: AppText.body14Semibold),
              const SizedBox(height: 2),
              Text(
                step.body,
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
