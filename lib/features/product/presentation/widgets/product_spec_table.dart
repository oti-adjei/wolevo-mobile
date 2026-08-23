import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Label / value rows separated by hairlines — the site's spec table
/// (`Seller`, `Brand`, `Condition`, `Product ID`) and the `Dimensions & Weight`
/// section share this layout.
///
/// Desktop puts label and value side by side; at 375px a long value would
/// crush, so the label sits above its value.
class SpecTable extends StatelessWidget {
  const SpecTable({super.key, required this.rows});

  final Map<String, String> rows;

  @override
  Widget build(BuildContext context) {
    final entries = rows.entries.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0)
            const Divider(height: 1, thickness: 1, color: AppColors.surface4),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
                const SizedBox(height: 2),
                Text(entry.value, style: AppText.body14Medium),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
