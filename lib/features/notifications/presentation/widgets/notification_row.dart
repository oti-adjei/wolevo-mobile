import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/notification_models.dart';

/// One inbox row. Unread rows get a tinted background and a dot, matching the
/// convention the site uses for its unread count.
class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return Material(
      color: n.read ? AppColors.background : AppColors.secondary6,
      borderRadius: AppRadius.rCard,
      child: InkWell(
        borderRadius: AppRadius.rCard,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rCard,
            border: Border.all(
              color: n.read ? AppColors.surface4 : AppColors.secondary7,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: n.kind.tint,
                  borderRadius: AppRadius.rSm,
                ),
                child: Icon(n.kind.icon, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: n.read
                                ? AppText.body14Medium
                                : AppText.body14Semibold,
                          ),
                        ),
                        if (!n.read)
                          Container(
                            margin: const EdgeInsets.only(
                              left: AppSpace.sm,
                              top: 6,
                            ),
                            height: 8,
                            width: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary3,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.body,
                        style: AppText.caption.copyWith(
                          color: AppColors.neutral1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _relative(n.createdAt),
                      style: AppText.caption.copyWith(
                        color: AppColors.neutral2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _relative(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(at);
  }
}
