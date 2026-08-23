import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../notifications_providers.dart';
import 'notification_row.dart';

/// The bell dropdown. On the web this was an anchored popover; on a phone it
/// becomes a bottom sheet.
Future<void> showNotificationsSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentNotificationsProvider);

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(title: 'Notifications'),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: switch (recent) {
              AsyncError(:final error) => Padding(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: Text(
                  '$error',
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
                ),
              ),
              AsyncData(:final value) when value.isEmpty => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.section),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 40,
                      color: AppColors.surface4,
                    ),
                    SizedBox(height: AppSpace.md),
                    _CaughtUpText(),
                  ],
                ),
              ),
              AsyncData(:final value) => ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                itemCount: value.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                itemBuilder: (context, index) {
                  final n = value[index];
                  return NotificationRow(
                    notification: n,
                    onTap: () {
                      ref
                          .read(notificationsListProvider.notifier)
                          .markRead(n.id);
                      Navigator.of(context).pop();
                      if (n.deepLink case final link?) context.push(link);
                    },
                  );
                },
              ),
              _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpace.section),
                child: AppLoader(),
              ),
            },
          ),
          const Divider(height: AppSpace.xxl),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.lg,
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.messages);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondary,
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(
                'View all notifications',
                style: AppText.body14Semibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaughtUpText extends StatelessWidget {
  const _CaughtUpText();

  @override
  Widget build(BuildContext context) {
    return Text(
      "You're all caught up",
      style: AppText.body14.copyWith(color: AppColors.neutral1),
    );
  }
}
