import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'routes.dart';

/// The five bottom-tab destinations.
///
/// The web app's mobile shell had four (Home · Shop · Ship · Orders) and hung
/// the account behind an avatar in the header. Here the account is a tab of its
/// own, so the header no longer duplicates a destination the nav already owns.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_TabSpec>[
    _TabSpec(AppRoutes.home, 'Home', Icons.home_outlined, Icons.home),
    _TabSpec(
      AppRoutes.shop,
      'Shop',
      Icons.shopping_bag_outlined,
      Icons.shopping_bag,
    ),
    _TabSpec(
      AppRoutes.ship,
      'Ship',
      Icons.local_shipping_outlined,
      Icons.local_shipping,
    ),
    _TabSpec(
      AppRoutes.orders,
      'Track',
      Icons.pin_drop_outlined,
      Icons.pin_drop,
    ),
    _TabSpec(AppRoutes.account, 'Account', Icons.person_outline, Icons.person),
  ];

  void _onTap(int index) {
    // Tapping the active tab pops that branch back to its root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials =
        ref.watch(sessionProvider).valueOrNull?.user.initials ?? '?';
    final current = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surface4)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  _NavItem(
                    spec: _tabs[i],
                    active: i == current,
                    initials: initials,
                    onTap: () => _onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab. Only the active one shows its label, inside a lime pill — the style
/// the client's mockups use. Inactive tabs are icon-only, which keeps five
/// destinations comfortable at 375pt where five labels would not fit.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.initials,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAccount = spec.path == AppRoutes.account;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rPill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.tertiary : Colors.transparent,
            borderRadius: AppRadius.rPill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAccount)
                _AvatarTabIcon(initials: initials, active: active)
              else
                Icon(
                  active ? spec.activeIcon : spec.icon,
                  size: 22,
                  color: active ? AppColors.secondary : AppColors.neutral1,
                ),
              if (active) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    spec.label,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: AppText.caption.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The account tab renders the user's initials rather than a generic glyph —
/// the same affordance the web header used, moved into the nav.
class _AvatarTabIcon extends StatelessWidget {
  const _AvatarTabIcon({required this.initials, required this.active});

  final String initials;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.secondary : AppColors.surface3,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppText.micro.copyWith(
          color: active ? Colors.white : AppColors.neutral1,
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.path, this.label, this.icon, this.activeIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
