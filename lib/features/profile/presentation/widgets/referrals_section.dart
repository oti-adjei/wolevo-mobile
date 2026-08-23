import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../profile_providers.dart';

/// Profile → Referrals. `GET /api/v1/user/referrals`.
class ReferralsSection extends ConsumerWidget {
  const ReferralsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(referralsProvider);

    return switch (async) {
      AsyncError(:final error) => ErrorRetry(
        message: '$error',
        onRetry: () => ref.invalidate(referralsProvider),
      ),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconChip(icon: Icons.card_giftcard_outlined),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Referral Code',
                            style: AppText.cardTitleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Share with friends to earn rewards',
                            style: AppText.caption.copyWith(
                              color: AppColors.neutral1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                _CodeField(value: value.code),
                const SizedBox(height: AppSpace.lg),
                const EyebrowLabel('Your referral link'),
                const SizedBox(height: AppSpace.sm),
                _LinkField(value: value.link),
                const SizedBox(height: AppSpace.lg),
                PrimaryButton(
                  label: 'Share with Friends',
                  icon: Icons.ios_share,
                  onPressed: () {
                    // The share sheet's outcome is not reported back by the
                    // OS, so this measures intent, not completed shares.
                    ref
                        .read(analyticsProvider)
                        .track(AnalyticsEvents.referralShared);
                    _share(value.code, value.link);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          const EyebrowLabel('How it works'),
          const SizedBox(height: AppSpace.md),
          const AppCard(
            child: Column(
              children: [
                _Step(number: 1, text: 'Share your code or link with friends'),
                SizedBox(height: AppSpace.lg),
                _Step(
                  number: 2,
                  text: 'They sign up and place their first order',
                ),
                SizedBox(height: AppSpace.lg),
                _Step(
                  number: 3,
                  text: 'Both of you get rewarded when the order ships',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          const EyebrowLabel('Referral activity'),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Friends who signed up with your code',
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
          const SizedBox(height: AppSpace.md),
          AppCard(
            child: value.entries.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                    child: Center(
                      child: Text(
                        'No referrals yet. Share your code to get started!',
                        textAlign: TextAlign.center,
                        style: AppText.body14.copyWith(
                          color: AppColors.neutral1,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < value.entries.length; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    value.entries[i].name,
                                    style: AppText.body14Medium,
                                  ),
                                  Text(
                                    'Joined ${DateFormat('d MMM yyyy').format(value.entries[i].joinedAt)}',
                                    style: AppText.caption.copyWith(
                                      color: AppColors.neutral1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            MicroBadge(
                              label: value.entries[i].rewarded
                                  ? 'Rewarded'
                                  : 'Pending',
                              background: value.entries[i].rewarded
                                  ? AppColors.secondary2
                                  : AppColors.surface3,
                            ),
                          ],
                        ),
                        if (i != value.entries.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpace.md,
                            ),
                            child: Divider(height: 1),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      _ => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpace.sectionLarge),
        child: AppLoader(),
      ),
    };
  }

  Future<void> _share(String code, String link) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Shop US stores and get it delivered in Ghana with Wolevo. '
            'Use my code $code — $link',
        subject: 'Join me on Wolevo',
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface6,
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        children: [
          Expanded(child: Text(value, style: AppText.mono)),
          _CopyChip(value: value, label: 'Referral code'),
        ],
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface6,
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.mono.copyWith(
                fontSize: 13,
                color: AppColors.neutral,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(
              Icons.copy_outlined,
              size: 18,
              color: AppColors.neutral1,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text('Referral link copied')),
                );
            },
          ),
        ],
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary2,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('$label copied')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.copy_outlined,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Copy',
                style: AppText.captionSemibold.copyWith(
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 26,
          width: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary2,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppText.captionSemibold.copyWith(
              color: AppColors.secondary3,
            ),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: AppText.body14)),
      ],
    );
  }
}
