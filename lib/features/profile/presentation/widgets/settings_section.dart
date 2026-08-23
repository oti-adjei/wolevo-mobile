import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../appearance/presentation/widgets/app_icon_picker.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../profile_providers.dart';

/// Profile → Settings: Security, Email Preferences, Danger Zone.
class SettingsSection extends ConsumerStatefulWidget {
  const SettingsSection({super.key});

  @override
  ConsumerState<SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends ConsumerState<SettingsSection> {
  bool? _promoOverride;
  bool _savingPrefs = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final promo = _promoOverride ?? user.promotionalEmails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const EyebrowLabel('Appearance'),
        const SizedBox(height: AppSpace.md),
        const AppIconPicker(),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Security'),
        const SizedBox(height: AppSpace.md),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.lock_outline,
                title: 'Password',
                subtitle: 'Manage your account password',
                actionLabel: 'Change',
                onAction: () => _showChangePasswordSheet(context),
              ),
              const Divider(height: 1),
              _SettingRow(
                icon: Icons.verified_user_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security to your account',
                actionLabel: 'Enable',
                // ASSUMPTION: 2FA was never exercised during discovery — the
                // site only exposes an "Enable" affordance — so this is a stub.
                onAction: () => ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Two-factor auth is coming soon')),
                  ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Email preferences'),
        const SizedBox(height: AppSpace.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _promoOverride = !promo),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: promo,
                      onChanged: (v) => setState(() => _promoOverride = v ?? false),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text('Promotional emails', style: AppText.body14Semibold),
                          const SizedBox(height: 2),
                          Text(
                            'Receive deals, sales, and new retailer announcements',
                            style: AppText.caption.copyWith(color: AppColors.neutral1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'Order, payment, and shipment notifications are always sent and '
                'cannot be turned off.',
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Save Preferences',
                size: AppButtonSize.compact,
                expand: false,
                loading: _savingPrefs,
                onPressed: _promoOverride == null || _savingPrefs
                    ? null
                    : () => _savePreferences(promo),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        Row(
          children: [
            const Icon(Icons.warning_amber_outlined, size: 14, color: AppColors.error),
            const SizedBox(width: 6),
            EyebrowLabel('Danger zone', color: AppColors.error),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        AppCard(
          borderColor: AppColors.error,
          color: AppColors.error3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delete Account', style: AppText.body14Semibold),
              const SizedBox(height: 2),
              Text(
                'Permanently delete your account and all associated data',
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.lg),
              DestructiveButton(
                label: 'Delete Account',
                icon: Icons.delete_outline,
                onPressed: () => _showDeleteAccountSheet(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _savePreferences(bool promo) async {
    setState(() => _savingPrefs = true);
    try {
      await ref.read(profileRepositoryProvider).setPromotionalEmails(promo);
      final user = ref.read(currentUserProvider);
      ref.read(sessionProvider.notifier).applyUser(user.copyWith(promotionalEmails: promo));
      if (!mounted) return;
      setState(() => _promoOverride = null);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Preferences saved')));
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  Future<void> _showChangePasswordSheet(BuildContext context) {
    return showAppSheet<void>(
      context: context,
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  Future<void> _showDeleteAccountSheet(BuildContext context) {
    return showAppSheet<void>(
      context: context,
      builder: (_) => const _DeleteAccountSheet(),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.neutral1),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.body14Semibold),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          AppTextLink(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Same rules the signup form enforces.
  bool get _meetsRules {
    final v = _next.text;
    return v.length >= 8 &&
        v.contains(RegExp(r'[A-Z]')) &&
        v.contains(RegExp(r'\d')) &&
        v.contains(RegExp(r'[@#$%^&+=!]'));
  }

  Future<void> _submit() async {
    if (!_meetsRules) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Change password',
              subtitle: 'Use at least 8 characters with a capital, a digit and a symbol.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.xl,
                AppSpace.xl,
              ),
              child: Column(
                children: [
                  if (_error != null) ...[
                    ErrorBanner(
                      message: _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  AppTextField(
                    label: 'Current password',
                    controller: _current,
                    obscure: true,
                    hint: 'Enter your current password',
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppTextField(
                    label: 'New password',
                    controller: _next,
                    obscure: true,
                    hint: 'Enter your new password',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppTextField(
                    label: 'Confirm new password',
                    controller: _confirm,
                    obscure: true,
                    hint: 'Confirm your new password',
                  ),
                  const SizedBox(height: AppSpace.xl),
                  PrimaryButton(
                    label: 'Update password',
                    loading: _saving,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountSheet extends ConsumerStatefulWidget {
  const _DeleteAccountSheet();

  @override
  ConsumerState<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends ConsumerState<_DeleteAccountSheet> {
  final _confirmation = TextEditingController();
  bool _deleting = false;

  static const _phrase = 'DELETE';

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
      await ref.read(sessionProvider.notifier).logout();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _confirmation.text.trim().toUpperCase() == _phrase;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHeader(
              title: 'Delete account',
              subtitle: 'This permanently deletes your account and all associated data. '
                  'It cannot be undone.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                0,
                AppSpace.xl,
                AppSpace.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Type $_phrase to confirm',
                    controller: _confirmation,
                    hint: _phrase,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  DestructiveButton(
                    label: 'Permanently delete my account',
                    expand: true,
                    size: AppButtonSize.regular,
                    onPressed: canDelete && !_deleting ? _delete : null,
                  ),
                  const SizedBox(height: AppSpace.md),
                  SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
