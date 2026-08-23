import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../widgets/calculator_panel.dart';

/// `/calculator` — public. Works with no session, exactly like the live site
/// (the estimate endpoint sits under `/public/`), so this screen never reads
/// the current user.
class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 210,
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.landing),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              background: _CalculatorHero(),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xl,
              AppSpace.gutter,
              AppSpace.section,
            ),
            sliver: SliverToBoxAdapter(child: CalculatorPanel()),
          ),
        ],
      ),
    );
  }
}

class _CalculatorHero extends StatelessWidget {
  const _CalculatorHero();

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
        // Scales down instead of overflowing while the app bar collapses.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const MicroBadge(label: 'Calculator'),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: 320,
                child: Text(
                  'Know your cost before you buy.',
                  textAlign: TextAlign.center,
                  style: AppText.h2.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: 320,
                child: Text(
                  'Paste a product link or enter package weight to get an instant '
                  'shipping estimate.',
                  textAlign: TextAlign.center,
                  style: AppText.body14.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
