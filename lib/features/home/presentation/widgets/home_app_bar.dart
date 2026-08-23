import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// The deep-green top bar: logo, search, cart, bell.
///
/// The web header also carried a `Ship` pill and an account avatar. Both are
/// bottom-tab destinations here, so repeating them in the header would be a
/// second route to the same place — they were removed rather than duplicated.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({
    super.key,
    required this.firstName,
    this.cartCount = 0,
    this.unreadCount = 0,
  });

  final String firstName;
  final int cartCount;
  final int unreadCount;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleSpacing: AppSpace.gutter,
      // The greeting used to sit in a separate lime band below the bar. Three
      // stacked full-width blocks (bar + band + content) is what made Home feel
      // heavy, so the greeting moved up here and the band was deleted.
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'wolevo',
            style: AppText.cardTitle.copyWith(
              color: AppColors.primary,
              letterSpacing: -0.6,
            ),
          ),
          Text(
            'Hello, $firstName 👋',
            style: AppText.caption.copyWith(color: AppColors.secondary7),
          ),
        ],
      ),
      actions: [
        _BarIcon(
          icon: Icons.search,
          tooltip: 'Search',
          onTap: () => context.push(AppRoutes.search),
        ),
        _BarIcon(
          icon: Icons.shopping_cart_outlined,
          tooltip: 'Cart',
          // The cart feature lands in Phase 2 — the badge count is hardcoded to
          // 0 until `GET /carts/active` is wired up.
          badge: cartCount,
          onTap: () => context.push(AppRoutes.cart),
        ),
        _BarIcon(
          icon: Icons.notifications_none,
          tooltip: 'Notifications',
          badge: unreadCount,
          onTap: () => context.push(AppRoutes.messages),
        ),
        const SizedBox(width: AppSpace.sm),
      ],
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 22, color: Colors.white),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  textAlign: TextAlign.center,
                  style: AppText.micro.copyWith(color: AppColors.secondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
