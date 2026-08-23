import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/retailer_logo.dart';

/// `Select Store` — the logo chips at the top of Shop.
///
/// Follows the client's mockup: each store is a rounded chip carrying its logo,
/// and the selected one fills lime. Scrolls horizontally, so all six retailers
/// are reachable.
class StoreSelector extends StatelessWidget {
  const StoreSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Retailer selected;
  final ValueChanged<Retailer> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Text('Select Store', style: AppText.cardTitleMedium),
        ),
        const SizedBox(height: AppSpace.md),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            itemCount: Retailer.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
            itemBuilder: (context, index) {
              final retailer = Retailer.values[index];
              return _StoreChip(
                retailer: retailer,
                selected: retailer == selected,
                onTap: () => onSelected(retailer),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({
    required this.retailer,
    required this.selected,
    required this.onTap,
  });

  final Retailer retailer;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: retailer.label,
      child: Material(
        color: selected ? AppColors.tertiary : AppColors.background,
        borderRadius: AppRadius.rPill,
        child: InkWell(
          borderRadius: AppRadius.rPill,
          onTap: onTap,
          child: Container(
            width: 104,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rPill,
              border: Border.all(
                color: selected ? AppColors.tertiary : AppColors.surface4,
              ),
            ),
            child: RetailerLogo(retailer: retailer),
          ),
        ),
      ),
    );
  }
}
