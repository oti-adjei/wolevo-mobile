import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Dark-green hero at the top of `/ship`: lime pill, H1, supporting line.
/// Copy verbatim from discovery-notes.md § 2.2.
class ShipHero extends StatelessWidget {
  const ShipHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      // Ship is a tab root with no app bar, so the hero owns the status-bar
      // inset itself — without this the pill sits under the notch.
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: AppRadius.rPill,
              ),
              child: Text(
                'SHIP A PACKAGE',
                style: AppText.micro.copyWith(color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              'Get your US warehouse address',
              style: AppText.h1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'Ship from any US store or send packages to our warehouse. '
              'We deliver to your door.',
              style: AppText.body.copyWith(color: AppColors.secondary7),
            ),
          ],
        ),
      ),
    );
  }
}
