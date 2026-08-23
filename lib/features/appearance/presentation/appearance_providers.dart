import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/logging/app_logger.dart';
import '../data/app_icon_models.dart';
import '../data/app_icon_repository.dart';
import '../data/appearance_repository.dart';

final appIconRepositoryProvider = Provider<AppIconRepository>(
  (ref) => PlatformAppIconRepository(logger: ref.watch(loggerProvider)),
);

/// Swap for a Dio-backed implementation to drive icons from the server.
final appearanceRepositoryProvider = Provider<AppearanceRepository>(
  (ref) => MockAppearanceRepository(),
);

final iconSwitchingSupportedProvider = FutureProvider<bool>(
  (ref) => ref.watch(appIconRepositoryProvider).isSupported(),
);

/// The campaign the server is advertising, if any, and only while it is inside
/// its window.
final activeCampaignProvider = FutureProvider<IconCampaign?>((ref) async {
  final campaign = await ref
      .watch(appearanceRepositoryProvider)
      .currentCampaign();
  if (campaign == null) return null;
  return campaign.isActiveAt(DateTime.now()) ? campaign : null;
});

/// What the user has chosen, plus whether they let campaigns change it.
class AppIconState {
  const AppIconState({
    required this.selected,
    required this.followsCampaigns,
    this.appliedCampaign,
  });

  final AppIconVariant selected;
  final bool followsCampaigns;

  /// Set when the current icon came from a campaign rather than a manual pick,
  /// so Settings can explain why it changed.
  final IconCampaign? appliedCampaign;

  AppIconState copyWith({
    AppIconVariant? selected,
    bool? followsCampaigns,
    IconCampaign? appliedCampaign,
    bool clearCampaign = false,
  }) {
    return AppIconState(
      selected: selected ?? this.selected,
      followsCampaigns: followsCampaigns ?? this.followsCampaigns,
      appliedCampaign: clearCampaign
          ? null
          : appliedCampaign ?? this.appliedCampaign,
    );
  }
}

/// Resolves which icon should be showing, and applies it.
///
/// Precedence, deliberately in this order:
///   1. A forced campaign — reserved for a rebrand, not a season.
///   2. The user's own choice, if they have ever made one.
///   3. An ordinary campaign, when the user has not opted out.
///   4. The default.
class AppIconController extends AsyncNotifier<AppIconState> {
  AppIconRepository get _repo => ref.read(appIconRepositoryProvider);

  @override
  Future<AppIconState> build() async {
    final manual = await _repo.manualChoice();
    final follows = await _repo.followsCampaigns();
    final campaign = await ref.watch(activeCampaignProvider.future);

    final campaignApplies =
        campaign != null && (campaign.force || (follows && manual == null));

    if (campaignApplies) {
      await _repo.applyCampaign(campaign.variant);
      return AppIconState(
        selected: campaign.variant,
        followsCampaigns: follows,
        appliedCampaign: campaign,
      );
    }

    return AppIconState(
      selected: manual ?? AppIconVariant.wolevo,
      followsCampaigns: follows,
    );
  }

  Future<void> select(AppIconVariant variant) async {
    final current = state.valueOrNull;
    // Optimistic: the OS swap is slow and the alert is modal, so reflect the
    // choice immediately rather than leaving the grid unresponsive.
    state = AsyncValue.data(
      (current ??
              const AppIconState(
                selected: AppIconVariant.wolevo,
                followsCampaigns: true,
              ))
          .copyWith(selected: variant, clearCampaign: true),
    );
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvents.appIconChanged,
          properties: {'variant': variant.id},
        );
    await _repo.apply(variant);
  }

  Future<void> setFollowsCampaigns(bool value) async {
    await _repo.setFollowsCampaigns(value);
    ref.invalidateSelf();
  }
}

final appIconProvider = AsyncNotifierProvider<AppIconController, AppIconState>(
  AppIconController.new,
);
