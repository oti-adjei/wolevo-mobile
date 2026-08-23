import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../data/profile_models.dart';
import '../profile_providers.dart';

/// `?section=addresses` — the saved delivery addresses list.
class AddressesSection extends ConsumerWidget {
  const AddressesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(savedAddressesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Saved Addresses', style: AppText.cardTitle),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(
          label: 'Add Address',
          icon: Icons.add,
          // The web opened a centered modal; on mobile the 3-step flow is a
          // full-screen route so each step gets the whole viewport.
          onPressed: () => context.push(AppRoutes.addAddress),
        ),
        const SizedBox(height: AppSpace.xl),
        addresses.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.section),
            child: AppLoader(label: 'Loading addresses…'),
          ),
          error: (e, _) => ErrorRetry(
            message: '$e',
            onRetry: () => ref.read(savedAddressesProvider.notifier).refresh(),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.location_off_outlined,
                title: 'No saved addresses',
                message:
                    'Add a delivery address so we know where to send your orders.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final address in list) ...[
                  _AddressCard(address: address),
                  const SizedBox(height: AppSpace.md),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final SavedAddress address;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpace.lg),
            const SheetHeader(
              title: 'Delete this address?',
              subtitle: 'This cannot be undone.',
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
                  Text(
                    address.formatted,
                    style: AppText.body14.copyWith(color: AppColors.neutral1),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  DestructiveButton(
                    label: 'Delete Address',
                    expand: true,
                    size: AppButtonSize.regular,
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                  ),
                  const SizedBox(height: AppSpace.md),
                  SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(savedAddressesProvider.notifier).delete(address.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Address deleted')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (address.isPrimary) ...[
                const MicroBadge(label: 'Primary'),
                const SizedBox(width: AppSpace.sm),
              ],
              if (address.label != null && address.label!.trim().isNotEmpty)
                Expanded(
                  child: Text(
                    address.label!,
                    style: AppText.body14Semibold,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(address.formatted, style: AppText.body),
          if (address.nearestLandmark != null &&
              address.nearestLandmark!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              'Landmark: ${address.nearestLandmark}',
              style: AppText.caption.copyWith(color: AppColors.neutral1),
            ),
          ],
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              SecondaryButton(
                label: 'Edit',
                expand: false,
                size: AppButtonSize.compact,
                onPressed: () =>
                    context.push(AppRoutes.addAddress, extra: address),
              ),
              const SizedBox(width: AppSpace.md),
              DestructiveButton(
                label: 'Delete',
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
