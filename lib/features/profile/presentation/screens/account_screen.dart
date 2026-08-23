import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/verify_email_sheet.dart';
import '../profile_providers.dart';

/// `/account` — the fifth bottom-tab destination and the entry point to
/// everything the web app hid behind `/profile?section=…`.
///
/// The desktop sidebar became a horizontal segmented strip in the first pass,
/// which crammed five sections into a scrolling row and pushed most of them off
/// screen. A grouped list hub is the native equivalent: every destination is
/// visible at once and each one opens as its own route.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push(AppRoutes.messages),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          0,
          AppSpace.gutter,
          AppSpace.section,
        ),
        children: [
          const SizedBox(height: AppSpace.lg),
          const _IdentityCard(),
          const SizedBox(height: AppSpace.xxl),
          _Group(
            title: 'Account',
            rows: [
              _RowSpec(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => context.push(AppRoutes.accountSection(ProfileSection.profile.name)),
              ),
              _RowSpec(
                icon: Icons.location_on_outlined,
                label: 'Addresses',
                onTap: () =>
                    context.push(AppRoutes.accountSection(ProfileSection.addresses.name)),
              ),
              _RowSpec(
                icon: Icons.card_giftcard_outlined,
                label: 'Referrals',
                onTap: () =>
                    context.push(AppRoutes.accountSection(ProfileSection.referrals.name)),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          _Group(
            title: 'Preferences',
            rows: [
              _RowSpec(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () =>
                    context.push(AppRoutes.accountSection(ProfileSection.settings.name)),
              ),
              _RowSpec(
                icon: Icons.notifications_none,
                label: 'Notifications',
                onTap: () => context.push(AppRoutes.messages),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          _Group(
            title: 'More',
            rows: [
              _RowSpec(
                icon: Icons.help_outline,
                label: 'Help Center',
                onTap: () => context.push(AppRoutes.help),
              ),
              _RowSpec(
                icon: Icons.support_agent_outlined,
                label: 'Support',
                onTap: () =>
                    context.push(AppRoutes.accountSection(ProfileSection.support.name)),
              ),
              _RowSpec(
                icon: Icons.receipt_long_outlined,
                label: 'Pricing',
                onTap: () => context.push(AppRoutes.pricing),
              ),
            ],
          ),
          if (!user.emailVerified) ...[
            const SizedBox(height: AppSpace.xl),
            _VerifyEmailPrompt(email: user.email),
          ],
          const SizedBox(height: AppSpace.sectionLarge),
          const _LogoutRow(),
        ],
      ),
    );
  }
}

/// Replaces the reference design's "Premium Membership" banner.
///
/// Wolevo has no premium tier, so rather than invent one this slot carries the
/// single most important object in the product: who you are and your locker ID,
/// which is the only thing distinguishing your parcels at the US warehouse.
class _IdentityCard extends ConsumerWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.rCardLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 52,
                width: 52,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  user.initials,
                  style: AppText.cardTitle.copyWith(color: AppColors.secondary),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: AppText.cardTitle.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: AppColors.secondary7),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.md,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: AppRadius.rCard,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR LOCKER ID',
                        style: AppText.micro.copyWith(color: AppColors.tertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.lockerId,
                        style: AppText.bodySemibold.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                _CopyLockerButton(lockerId: user.lockerId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyLockerButton extends StatelessWidget {
  const _CopyLockerButton({required this.lockerId});

  final String lockerId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tertiary,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () {
          Clipboard.setData(ClipboardData(text: lockerId));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Locker ID copied')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            'Copy',
            style: AppText.captionSemibold.copyWith(color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _RowSpec {
  const _RowSpec({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<_RowSpec> rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.lg,
              AppSpace.xl,
              AppSpace.md,
            ),
            child: Text(title, style: AppText.cardTitle),
          ),
          const Divider(height: 1),
          for (var i = 0; i < rows.length; i++) ...[
            _AccountRow(spec: rows[i]),
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.spec});

  final _RowSpec spec;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: spec.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.xl,
          vertical: AppSpace.lg,
        ),
        child: Row(
          children: [
            Icon(spec.icon, size: 22, color: AppColors.neutral1),
            const SizedBox(width: AppSpace.lg),
            Expanded(child: Text(spec.label, style: AppText.body)),
            const Icon(Icons.chevron_right, size: 22, color: AppColors.neutral2),
          ],
        ),
      ),
    );
  }
}

class _VerifyEmailPrompt extends StatelessWidget {
  const _VerifyEmailPrompt({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return InfoCallout(
      leading: '✉️',
      background: AppColors.tertiary3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verify your email', style: AppText.body14Semibold),
          const SizedBox(height: 2),
          Text(
            'Order updates and your final bill are sent to $email. '
            'Verify it so nothing gets missed.',
            style: AppText.caption.copyWith(color: AppColors.neutral),
          ),
          const SizedBox(height: AppSpace.md),
          InkWell(
            onTap: () => showVerifyEmailSheet(context),
            child: Text(
              'Verify email',
              style: AppText.body14Semibold.copyWith(
                color: AppColors.secondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutRow extends ConsumerWidget {
  const _LogoutRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          await ref.read(sessionProvider.notifier).logout();
          if (context.mounted) context.go(AppRoutes.landing);
        },
        icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
        label: Text(
          'Log out',
          style: AppText.bodySemibold.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}
