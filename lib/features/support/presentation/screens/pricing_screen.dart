import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/support_content.dart';

/// `/pricing` — public. "How We Calculate Shipping Costs".
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  /// The site opens with the first accordion expanded.
  int _open = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 190,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.landing),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              background: _PricingHero(),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xl,
              AppSpace.gutter,
              AppSpace.section,
            ),
            sliver: SliverList.list(
              children: [
                for (var i = 0; i < SupportContent.pricing.length; i++) ...[
                  _PricingAccordion(
                    section: SupportContent.pricing[i],
                    expanded: _open == i,
                    onToggle: () => setState(() => _open = _open == i ? -1 : i),
                  ),
                  const SizedBox(height: AppSpace.md),
                ],
                const SizedBox(height: AppSpace.lg),
                SecondaryButton(
                  label: 'Estimate my shipping cost',
                  icon: Icons.calculate_outlined,
                  onPressed: () => context.push(AppRoutes.calculator),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PricingHero extends StatelessWidget {
  const _PricingHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sectionLarge,
        AppSpace.gutter,
        AppSpace.xl,
      ),
      child: SafeArea(
        bottom: false,
        // The hero shrinks as the sliver app bar collapses; scale the content
        // down rather than overflowing mid-animation.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const MicroBadge(label: 'Pricing'),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: 320,
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'How We Calculate ',
                    style: AppText.h2.copyWith(color: Colors.white),
                    children: [
                      TextSpan(
                        text: 'Shipping Costs',
                        style: AppText.h2.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingAccordion extends StatelessWidget {
  const _PricingAccordion({
    required this.section,
    required this.expanded,
    required this.onToggle,
  });

  final PricingSection section;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.cardPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: AppText.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          section.subtitle,
                          style: AppText.body14.copyWith(
                            color: AppColors.neutral1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.remove : Icons.add,
                    size: 20,
                    color: AppColors.neutral1,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.cardPadding,
                0,
                AppSpace.cardPadding,
                AppSpace.cardPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final block in section.blocks) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 36,
                          width: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.secondary2,
                            borderRadius: AppRadius.rSm,
                          ),
                          child: Text(block.icon, style: AppText.body14),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(block.title, style: AppText.body14Semibold),
                              const SizedBox(height: 2),
                              Text(
                                block.body,
                                style: AppText.body14.copyWith(
                                  color: AppColors.neutral1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  if (section.footnote case final note?)
                    Text(note, style: AppText.body14Semibold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
