import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_models.dart';
import '../analytics/analytics.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

/// The locker address block — the single most important object in the product.
/// Shared by Ship and Profile, so it lives in core rather than in either
/// feature. Copy is verbatim from the site; the warnings are load-bearing, not
/// boilerplate (a parcel without the locker ID cannot be matched to a user).
class LockerAddressPanel extends ConsumerStatefulWidget {
  const LockerAddressPanel({
    super.key,
    required this.address,
    this.initiallyExpanded = false,
  });

  final WarehouseAddress address;
  final bool initiallyExpanded;

  @override
  ConsumerState<LockerAddressPanel> createState() => _LockerAddressPanelState();
}

class _LockerAddressPanelState extends ConsumerState<LockerAddressPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final a = widget.address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lime header bar.
        Material(
          color: AppColors.tertiary,
          borderRadius: _expanded
              ? const BorderRadius.vertical(top: AppRadius.card)
              : AppRadius.rCard,
          child: InkWell(
            borderRadius: _expanded
                ? const BorderRadius.vertical(top: AppRadius.card)
                : AppRadius.rCard,
            onTap: () {
              setState(() => _expanded = !_expanded);
              // Only the open counts: this is the step that tells us whether
              // people actually reach their US address.
              if (_expanded) {
                ref.read(analyticsProvider).track(
                      AnalyticsEvents.lockerAddressViewed,
                    );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  const IconChip(
                    icon: Icons.location_on_outlined,
                    background: AppColors.secondary,
                    foreground: AppColors.tertiary,
                    size: 40,
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR US SHIPPING ADDRESS · TAX-FREE',
                          style: AppText.micro.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to view — copy each field into checkout',
                          style: AppText.caption.copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(bottom: AppRadius.card),
              border: Border(
                left: BorderSide(color: AppColors.surface4),
                right: BorderSide(color: AppColors.surface4),
                bottom: BorderSide(color: AppColors.surface4),
              ),
            ),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CopyRow(label: 'Name', value: a.name),
                _CopyRow(label: 'Address line 1', value: a.addressLine1),
                _CopyRow(label: 'Address line 2', value: a.addressLine2),
                _CopyRow(label: 'City', value: a.city),
                _CopyRow(label: 'State', value: a.stateCode, trailing: '(${a.stateName})'),
                _CopyRow(label: 'Zip code', value: a.zipCode),
                _CopyRow(label: 'Country', value: a.countryCode),
                _CopyRow(label: 'Phone', value: a.phone, last: true),
                const SizedBox(height: AppSpace.lg),
                _WarningBlock(
                  title: '${a.addressLine2} must be on your address',
                  lines: [
                    'If the store has no second address line, add it to the end of the first: '
                        '"${a.addressLine1} ${a.addressLine2}".',
                    "A package sent without it may not reach our warehouse, and we can't take "
                        'responsibility for it.',
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                _WarningBlock(
                  title: 'Use this exact name',
                  lines: [
                    'A package that arrives without "${a.name}" cannot be matched to you, and we '
                        "can't take responsibility for it. Use it even if it isn't your own name.",
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                _RetailerNameSplit(address: a),
              ],
            ),
          ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    this.trailing,
    this.last = false,
  });

  final String label;
  final String value;
  final String? trailing;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.surface3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppText.micro.copyWith(color: AppColors.neutral1)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(child: Text(value, style: AppText.bodySemibold)),
                    if (trailing != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        trailing!,
                        style: AppText.body14.copyWith(color: AppColors.neutral1),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          CopyChip(value: value, label: label),
        ],
      ),
    );
  }
}

/// Mint "Copy" pill that writes to the clipboard and confirms with a snackbar.
class CopyChip extends ConsumerWidget {
  const CopyChip({super.key, required this.value, this.label, this.text = 'Copy'});

  final String value;
  final String? label;
  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.secondary2,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('${label ?? 'Value'} copied')),
            );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            text,
            style: AppText.captionSemibold.copyWith(color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _WarningBlock extends StatelessWidget {
  const _WarningBlock({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.tertiary3,
        borderRadius: AppRadius.rCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.body14Semibold),
          const SizedBox(height: 6),
          for (final line in lines) ...[
            Text(line, style: AppText.caption.copyWith(color: AppColors.neutral)),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _RetailerNameSplit extends StatelessWidget {
  const _RetailerNameSplit({required this.address});

  final WarehouseAddress address;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.lg),
      color: AppColors.surface6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📋 IF RETAILER ASKS FOR SEPARATE NAMES:',
            style: AppText.micro.copyWith(color: AppColors.neutral),
          ),
          const SizedBox(height: AppSpace.md),
          _CopyRow(label: 'First name', value: address.retailerFirstName),
          _CopyRow(label: 'Last name', value: address.retailerLastName, last: true),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Your locker ID must appear on the package. Keep it in the name field '
            '(e.g., "Wolevo ABC1234") or address line 2.',
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ],
      ),
    );
  }
}
