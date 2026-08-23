import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/home_models.dart';
import '../home_providers.dart';
import '../widgets/deal_carousel.dart';
import '../widgets/active_shipments_card.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/retailer_chip_row.dart';

/// `/home` — the authenticated storefront.
///
/// Layout follows the client's app mockups: a flat green bar carrying the
/// wordmark and greeting, then one lime hero card for shipments in flight, then
/// white content. Exactly one element is allowed to shout, which is what makes
/// the screen read as calm.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      backgroundColor: AppColors.surface6,
      appBar: HomeAppBar(
        firstName: user.firstName,
        cartCount: ref.watch(cartItemCountProvider),
        unreadCount: ref.watch(unreadNotificationsProvider),
      ),
      body: RefreshIndicator(
        color: AppColors.secondary,
        onRefresh: () => ref.read(homeFeedProvider.notifier).refresh(),
        child: CustomScrollView(
          // Always scrollable so pull-to-refresh works on the error state too.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.lg,
                AppSpace.gutter,
                AppSpace.xxl,
              ),
              sliver: const SliverToBoxAdapter(child: ActiveShipmentsCard()),
            ),
            const SliverToBoxAdapter(child: _BrowseStores()),
            ...switch (feed) {
              AsyncData(:final value) => _feedSlivers(value),
              AsyncError() => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorRetry(
                      message: _feedErrorMessage,
                      onRetry: () => ref.read(homeFeedProvider.notifier).refresh(),
                    ),
                  ),
                ],
              _ => const [SliverToBoxAdapter(child: _FeedSkeleton())],
            },
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.section)),
          ],
        ),
      ),
    );
  }

  List<Widget> _feedSlivers(HomeFeed feed) {
    if (feed.sections.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No deals right now',
            message: 'Pull down to refresh, or browse a store above.',
          ),
        ),
      ];
    }
    return [
      SliverList.separated(
        itemCount: feed.sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.section),
        itemBuilder: (context, index) => HomeSectionView(section: feed.sections[index]),
      ),
    ];
  }

  // ASSUMPTION: the mock repository never throws, so this only ever renders for
  // a real transport failure once Dio is wired in. The raw exception is not
  // surfaced — the web app shows a generic retry line.
  static const _feedErrorMessage =
      'We could not load today\'s deals. Check your connection and try again.';
}

/// `Browse Top U.S Stores` label plus the retailer pill row.
class _BrowseStores extends StatelessWidget {
  const _BrowseStores();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading and `View All` on one line, tiles beneath — the mockup's
        // arrangement, replacing the eyebrow label + scrolling pill strip.
        const BrowseStoresHeader(),
        const RetailerChipRow(),
        const SizedBox(height: AppSpace.section),
      ],
    );
  }
}

/// Two placeholder rows while the feed loads — enough to fill a phone viewport
/// without pretending to know the real section count.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
              child: Container(
                height: 22,
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface3,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            const DealCarouselSkeleton(),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(),
        const SizedBox(height: AppSpace.section),
        row(),
        const SizedBox(height: AppSpace.xxl),
        Center(
          child: Text(
            'Loading deals…',
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ),
      ],
    );
  }
}
