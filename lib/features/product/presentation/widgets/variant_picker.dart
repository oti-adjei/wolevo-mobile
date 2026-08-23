import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/product_models.dart';

/// One variant group, rendered as wrap-laid-out chips.
///
/// Selected uses Phase 1's [SelectableCard] treatment — mint fill
/// (`--secondary-2`) with a `--secondary-3` border. Groups with more than six
/// options collapse behind the site's `See more (n more)` affordance.
class VariantPicker extends StatefulWidget {
  const VariantPicker({
    super.key,
    required this.group,
    required this.onSelected,
  });

  final VariantGroup group;
  final ValueChanged<String> onSelected;

  /// The site showed six `Size` swatches before `See more (1 more)`.
  static const collapsedCount = 6;

  @override
  State<VariantPicker> createState() => _VariantPickerState();
}

class _VariantPickerState extends State<VariantPicker> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.group.options;
    final overflow = options.length - VariantPicker.collapsedCount;
    final visible = _expanded || overflow <= 0
        ? options
        : options.take(VariantPicker.collapsedCount).toList(growable: false);
    final selectedLabel = widget.group.selectedOption?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${widget.group.displayName}:', style: AppText.body14Semibold),
            if (selectedLabel != null) ...[
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: Text(
                  selectedLabel,
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final option in visible)
              _VariantChip(
                option: option,
                onTap: option.available ? () => widget.onSelected(option.id) : null,
              ),
          ],
        ),
        if (overflow > 0) ...[
          const SizedBox(height: AppSpace.sm),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadius.rSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                _expanded ? 'See less' : 'See more ($overflow more)',
                style: AppText.body14Semibold.copyWith(color: AppColors.secondary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  const _VariantChip({required this.option, this.onTap});

  final VariantOption option;
  final VoidCallback? onTap;

  /// Colour swatches on the live site are the retailer's own thumbnails. With
  /// no reachable imagery the chip paints the named colour instead, falling
  /// back to a neutral dot for names we cannot map.
  //
  // ASSUMPTION: the mapping below covers the colour names in the mock
  // catalogue only, and every swatch is a brand token rather than a literal so
  // the picker stays inside the design system.
  static const _swatches = <String, Color>{
    'black': AppColors.secondary5,
    'white': AppColors.background,
    'red': AppColors.error,
    'green': AppColors.primary3,
    'silver': AppColors.surface5,
  };

  @override
  Widget build(BuildContext context) {
    final selected = option.selected;
    final swatch = option.kind == VariantOptionKind.color
        ? _swatches[option.label.toLowerCase()]
        : null;

    return Opacity(
      opacity: option.available ? 1 : 0.4,
      child: Material(
        color: selected ? AppColors.secondary2 : AppColors.background,
        borderRadius: AppRadius.rInput,
        child: InkWell(
          borderRadius: AppRadius.rInput,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md,
              vertical: AppSpace.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.rInput,
              border: Border.all(
                color: selected ? AppColors.secondary3 : AppColors.surface4,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (swatch != null) ...[
                  Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface4),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Text(
                  option.label,
                  style: AppText.body14Medium.copyWith(
                    color: selected ? AppColors.secondary : AppColors.secondary5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
