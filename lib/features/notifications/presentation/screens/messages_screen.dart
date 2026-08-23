import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../notifications_providers.dart';
import '../widgets/notification_row.dart';

/// `/messages` — the full notifications page behind the bell's
/// "View all notifications" action.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
    final list = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => ref
                .read(notificationsUnreadOnlyProvider.notifier)
                .update((value) => !value),
            style: TextButton.styleFrom(foregroundColor: AppColors.tertiary),
            child: Text(
              unreadOnly ? 'Show all' : 'Unread only',
              style: AppText.body14Semibold,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () =>
              ref.read(notificationsListProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.lg,
                    AppSpace.gutter,
                    AppSpace.md,
                  ),
                  child: Text(
                    'Stay updated on your orders and shipments',
                    style: AppText.body14.copyWith(color: AppColors.neutral1),
                  ),
                ),
              ),
              switch (list) {
                AsyncError(:final error) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(
                    message: '$error',
                    onRetry: () => ref.invalidate(notificationsListProvider),
                  ),
                ),
                AsyncData(:final value) when value.isEmpty => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.notifications_none,
                    title: unreadOnly
                        ? 'No unread notifications'
                        : 'Nothing here yet',
                    message: unreadOnly
                        ? "You're all caught up!"
                        : 'Updates about your orders and shipments will appear here.',
                  ),
                ),
                AsyncData(:final value) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    0,
                    AppSpace.gutter,
                    AppSpace.section,
                  ),
                  sliver: SliverList.separated(
                    itemCount: value.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (context, index) {
                      final n = value[index];
                      return NotificationRow(
                        notification: n,
                        onTap: () {
                          ref
                              .read(notificationsListProvider.notifier)
                              .markRead(n.id);
                          if (n.deepLink case final link?) context.push(link);
                        },
                      );
                    },
                  ),
                ),
                _ => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoader(),
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
