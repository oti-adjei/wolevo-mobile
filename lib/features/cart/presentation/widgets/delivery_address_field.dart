import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../profile/data/profile_models.dart';
import '../../../profile/presentation/profile_providers.dart';

/// `Destination country` select for step 2. The web renders a native
/// `<select>`; the mobile convention is a bottom sheet.
class DeliveryCountryField extends StatelessWidget {
  const DeliveryCountryField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DestinationCountry value;
  final ValueChanged<DestinationCountry> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showAppSheet<DestinationCountry>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpace.lg),
            const SheetHeader(
              title: 'Country',
              subtitle: 'Where is this order going?',
            ),
            for (final country in DestinationCountry.values)
              ListTile(
                onTap: () => Navigator.of(ctx).pop(country),
                leading: Text(country.flag, style: AppText.h3),
                title: Text(country.name, style: AppText.bodyMedium),
                trailing: country == value
                    ? const Icon(Icons.check, color: AppColors.secondary)
                    : null,
              ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Country', required: true),
        const SizedBox(height: AppSpace.sm),
        _SelectShell(
          onTap: () => _open(context),
          child: Row(
            children: [
              Text(value.flag, style: AppText.body),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(value.name, style: AppText.body)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Showing addresses in ${value.name}',
          style: AppText.caption.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}

/// `Delivery Address` select. Opens a sheet listing the saved addresses in the
/// chosen country, plus a row that pushes the add-address flow.
class DeliveryAddressField extends ConsumerWidget {
  const DeliveryAddressField({
    super.key,
    required this.country,
    required this.selectedId,
    required this.onSelected,
  });

  final DestinationCountry country;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savedAddressesProvider);
    final addresses = _inCountry(async.valueOrNull ?? const []);
    SavedAddress? selected;
    for (final a in addresses) {
      if (a.id == selectedId) selected = a;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Delivery Address', required: true),
        const SizedBox(height: AppSpace.sm),
        _SelectShell(
          onTap: () => _open(context, ref, addresses),
          child: selected == null
              ? Text(
                  async.isLoading ? 'Loading addresses…' : 'Select a delivery address',
                  style: AppText.body.copyWith(color: AppColors.neutral2),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.formatted.replaceAll('\n', ', '),
                      style: AppText.body14Medium,
                    ),
                    if (selected.nearestLandmark case final landmark?) ...[
                      const SizedBox(height: 2),
                      Text(
                        landmark,
                        style: AppText.caption.copyWith(color: AppColors.neutral1),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<SavedAddress> _inCountry(List<SavedAddress> all) => [
        for (final a in all)
          if (a.countryCode.toUpperCase() == country.code) a,
      ];

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    List<SavedAddress> addresses,
  ) async {
    final picked = await showAppSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpace.lg),
              SheetHeader(
                title: 'Delivery address',
                subtitle: 'Showing addresses in ${country.name}',
              ),
              if (addresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.xl,
                    vertical: AppSpace.md,
                  ),
                  child: Text(
                    'No saved addresses in ${country.name} yet.',
                    style: AppText.body14.copyWith(color: AppColors.neutral1),
                  ),
                ),
              for (final address in addresses)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.xl,
                    0,
                    AppSpace.xl,
                    AppSpace.md,
                  ),
                  child: SelectableCard(
                    selected: address.id == selectedId,
                    onTap: () => Navigator.of(ctx).pop(address.id),
                    child: _AddressBody(address: address),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.xl,
                  0,
                  AppSpace.xl,
                  AppSpace.xl,
                ),
                child: InkWell(
                  borderRadius: AppRadius.rCard,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.push(AppRoutes.addAddress);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 18, color: AppColors.secondary),
                        const SizedBox(width: AppSpace.sm),
                        Text(
                          'Add a new address',
                          style: AppText.body14Semibold
                              .copyWith(color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null) onSelected(picked);
    // A new address may have been saved while the sheet was open.
    ref.invalidate(savedAddressesProvider);
  }
}

class _AddressBody extends StatelessWidget {
  const _AddressBody({required this.address});

  final SavedAddress address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                address.label ?? address.city,
                style: AppText.body14Semibold,
              ),
            ),
            if (address.isPrimary) const MicroBadge(label: 'Primary'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          address.formatted,
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        if (address.nearestLandmark case final landmark?) ...[
          const SizedBox(height: 4),
          Text(
            'Near $landmark',
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ],
      ],
    );
  }
}

/// The input-shaped tap target shared by both selects above.
class _SelectShell extends StatelessWidget {
  const _SelectShell({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.rInput,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.rInput,
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral1),
          ],
        ),
      ),
    );
  }
}
