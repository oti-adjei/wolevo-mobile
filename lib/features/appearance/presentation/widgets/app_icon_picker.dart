import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/wolevo_mark.dart';
import '../../data/app_icon_models.dart';
import '../appearance_providers.dart';

/// Settings → App icon. Lets the user pick a variant, and opt in or out of the
/// seasonal icons Wolevo pushes from the server.
class AppIconPicker extends ConsumerWidget {
  const AppIconPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(iconSwitchingSupportedProvider);
    final iconState = ref.watch(appIconProvider);

    // Never offer a control that silently does nothing: some Android launchers
    // and every desktop target lack alternate-icon support.
    if (supported.valueOrNull == false) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: AppColors.neutral1),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                "This device doesn't support changing the app icon.",
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
            ),
          ],
        ),
      );
    }

    final state = iconState.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App icon', style: AppText.cardTitleMedium),
              const SizedBox(height: 2),
              Text(
                'Pick the icon that appears on your home screen.',
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              if (state?.appliedCampaign case final campaign?) ...[
                const SizedBox(height: AppSpace.lg),
                InfoCallout(
                  leading: '✨',
                  child: Text(
                    '${campaign.name ?? 'A seasonal icon'} is running, so your '
                    'icon changed automatically. Pick one below to keep it.',
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: AppSpace.md,
                mainAxisSpacing: AppSpace.md,
                childAspectRatio: 0.72,
                children: [
                  for (final variant in AppIconVariant.values)
                    _IconOption(
                      variant: variant,
                      selected: state?.selected == variant,
                      onTap: () =>
                          ref.read(appIconProvider.notifier).select(variant),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.lg),
                child: Divider(height: 1),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seasonal icons', style: AppText.body14Semibold),
                        const SizedBox(height: 2),
                        Text(
                          'Let Wolevo switch your icon for holidays and events.',
                          style: AppText.caption.copyWith(
                            color: AppColors.neutral1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state?.followsCampaigns ?? true,
                    onChanged: (value) => ref
                        .read(appIconProvider.notifier)
                        .setFollowsCampaigns(value),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  final AppIconVariant variant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rCard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // Drawn from the same vector the real launcher icon is rendered
              // from, so the swatch always matches what lands on the home
              // screen — no separate preview assets to fall out of date.
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  color: variant.background,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected ? AppColors.secondary3 : AppColors.surface4,
                    width: selected ? 2.5 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: WolevoMark(width: 32, color: variant.mark),
              ),
              if (selected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            variant.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              color: selected ? AppColors.secondary : AppColors.neutral1,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
