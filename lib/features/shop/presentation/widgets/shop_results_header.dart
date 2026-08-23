import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// Browse heading — `Amazon Deals & Featured Products` with the item count
/// beside it, exactly as the web app prints it. The retailer name tracks the
/// scope selector.
class BrowseResultsHeader extends StatelessWidget {
  const BrowseResultsHeader({
    super.key,
    required this.retailerLabel,
    required this.countLabel,
    this.loading = false,
  });

  final String retailerLabel;
  final String countLabel;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            '$retailerLabel Deals & Featured Products',
            style: AppText.cardTitle,
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Text(
          loading ? '' : countLabel,
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}

/// Search heading — `"usb c cable"` + `× Clear` + `20 items`, the site's exact
/// arrangement. Stacked on a phone so a long query never squeezes the count.
class SearchResultsHeader extends StatelessWidget {
  const SearchResultsHeader({
    super.key,
    required this.query,
    required this.countLabel,
    required this.onClear,
    this.loading = false,
  });

  final String query;
  final String countLabel;
  final VoidCallback onClear;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '"$query"',
                style: AppText.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            _ClearControl(onPressed: onClear),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          loading ? 'Searching…' : countLabel,
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}

class _ClearControl extends StatelessWidget {
  const _ClearControl({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface3,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.close, size: 14, color: AppColors.neutral1),
              const SizedBox(width: 4),
              Text(
                'Clear',
                style: AppText.body14Medium.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
