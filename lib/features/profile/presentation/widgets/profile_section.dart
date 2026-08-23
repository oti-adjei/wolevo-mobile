import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/locker_address_card.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/verify_email_sheet.dart';
import '../profile_providers.dart';

/// `?section=profile` — identity header, the read-only Account Information
/// list, and the shared warehouse-address panel.
class ProfileInfoSection extends ConsumerWidget {
  const ProfileInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dob = user.dateOfBirth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _InitialAvatar(initials: user.initials),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: AppText.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: AppText.body14.copyWith(color: AppColors.neutral1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.accountType.label} Account',
                          style: AppText.caption.copyWith(color: AppColors.neutral1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              Row(
                children: [
                  Expanded(child: Text('Account Information', style: AppText.cardTitleMedium)),
                  SecondaryButton(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    expand: false,
                    size: AppButtonSize.compact,
                    onPressed: () => showEditProfileSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),

              // The web renders these as a two-column grid. At 375px a grid
              // truncates every value, so the mobile adaptation stacks them
              // into a single column of label-over-value rows.
              InfoRow(label: 'First Name', value: user.firstName),
              InfoRow(label: 'Last Name', value: user.lastName),
              InfoRow(
                label: 'Email',
                value: user.email,
                helper: user.emailVerified
                    ? null
                    : 'Order updates and your final bill are sent here. '
                        'Verify it so nothing gets missed.',
                trailing: user.emailVerified
                    ? const _VerifiedChip()
                    : AppTextLink(
                        label: 'Verify email',
                        onPressed: () => showVerifyEmailSheet(context),
                      ),
              ),
              InfoRow(label: 'Phone Number', value: user.phoneNumber),
              InfoRow(
                label: 'Date of Birth',
                value: dob == null ? 'Not provided' : DateFormat.yMMMd().format(dob),
                muted: dob == null,
              ),
              InfoRow(
                label: 'Destination Country',
                value: '${user.destinationCountry.flag}  ${user.destinationCountry.name}',
                helper: 'Used to display prices in local currency if supported',
              ),
              InfoRow(label: 'Account Type', value: user.accountType.label),
              InfoRow(
                label: 'Locker ID',
                value: user.lockerId,
                helper: 'Your unique warehouse locker identifier',
                trailing: CopyChip(value: user.lockerId, label: 'Locker ID'),
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        Text('Warehouse Address', style: AppText.cardTitle),
        const SizedBox(height: AppSpace.md),
        LockerAddressPanel(address: ref.watch(warehouseAddressProvider)),
      ],
    );
  }
}

/// One stacked read-only row: small label, value below, optional helper line
/// and a trailing affordance (chip / link).
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.trailing,
    this.muted = false,
    this.last = false,
  });

  final String label;
  final String value;
  final String? helper;
  final Widget? trailing;
  final bool muted;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.surface3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.micro.copyWith(color: AppColors.neutral1)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppText.bodyMedium.copyWith(
                    color: muted ? AppColors.neutral2 : AppColors.bodyText,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpace.sm),
                trailing!,
              ],
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: AppText.caption.copyWith(color: AppColors.neutral1)),
          ],
        ],
      ),
    );
  }
}

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.secondary2,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 12, color: AppColors.success2),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: AppText.captionSemibold.copyWith(color: AppColors.success2),
          ),
        ],
      ),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Text(initials, style: AppText.h3.copyWith(color: Colors.white)),
    );
  }
}

/// The web's `Edit` opens an inline form; on mobile it becomes a bottom sheet.
/// Email is deliberately absent — the site states it cannot be changed.
Future<void> showEditProfileSheet(BuildContext context) {
  return showAppSheet<void>(context: context, builder: (_) => const _EditProfileSheet());
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final WolevoUser _user = ref.read(currentUserProvider);
  late final TextEditingController _first = TextEditingController(text: _user.firstName);
  late final TextEditingController _last = TextEditingController(text: _user.lastName);
  late DateTime? _dob = _user.dateOfBirth;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Date of Birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final first = _first.text.trim();
    final last = _last.text.trim();
    if (first.isEmpty || last.isEmpty) {
      setState(() => _error = 'First and last name are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            firstName: first,
            lastName: last,
            dateOfBirth: _dob,
          );
      ref.read(sessionProvider.notifier).applyUser(
            _user.copyWith(firstName: first, lastName: last, dateOfBirth: _dob),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpace.lg),
            const SheetHeader(
              title: 'Edit Profile',
              subtitle: 'Email cannot be changed',
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
                  if (_error != null) ...[
                    ErrorBanner(message: _error!, onDismiss: () => setState(() => _error = null)),
                    const SizedBox(height: AppSpace.lg),
                  ],
                  AppTextField(
                    label: 'First Name',
                    required: true,
                    controller: _first,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppTextField(
                    label: 'Last Name',
                    required: true,
                    controller: _last,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const FieldLabel('Date of Birth'),
                  const SizedBox(height: AppSpace.sm),
                  InkWell(
                    borderRadius: AppRadius.rInput,
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.lg,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.rInput,
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _dob == null
                                  ? 'Not provided'
                                  : DateFormat.yMMMd().format(_dob!),
                              style: AppText.body.copyWith(
                                color: _dob == null ? AppColors.neutral2 : AppColors.bodyText,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.neutral1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  PrimaryButton(
                    label: 'Save Changes',
                    loading: _saving,
                    onPressed: _saving ? null : _save,
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
