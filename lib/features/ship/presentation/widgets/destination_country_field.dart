import 'package:flutter/material.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';

/// `Destination Country *`. The web renders a native `<select>`; on a phone the
/// convention is a bottom sheet (see showAppSheet).
class DestinationCountryField extends StatelessWidget {
  const DestinationCountryField({
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
              title: 'Destination country',
              subtitle: 'Where are you shipping to?',
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
        const FieldLabel('Destination Country', required: true),
        const SizedBox(height: AppSpace.sm),
        InkWell(
          borderRadius: AppRadius.rInput,
          onTap: () => _open(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.rInput,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Text(value.flag, style: AppText.body),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(value.name, style: AppText.body)),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.neutral1,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Where are you shipping to?',
          style: AppText.caption.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}
