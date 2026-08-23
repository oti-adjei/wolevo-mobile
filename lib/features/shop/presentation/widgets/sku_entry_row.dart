import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';

/// `Or enter a {Store} SKU number directly` — from the client's Shop mockup.
///
/// This is not new API surface: the product endpoint already takes an id
/// (`/shop/products/parse?retailer=&productId=`), and an Amazon ASIN or a Best
/// Buy SKU *is* that id. Pasting a link resolves to the same lookup, so this
/// row is simply the shorter path to it.
class SkuEntryRow extends StatelessWidget {
  const SkuEntryRow({
    super.key,
    required this.retailer,
    required this.onSubmit,
    this.onPasteLink,
  });

  final Retailer retailer;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onPasteLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_list_numbered,
                size: 18,
                color: AppColors.neutral1,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  'Or enter a ${retailer.label} SKU number directly',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              _EnterSkuButton(
                onTap: () => _openSheet(context),
              ),
            ],
          ),
          if (onPasteLink != null) ...[
            const SizedBox(height: AppSpace.sm),
            // Pasting a product link is the flow the live site actually ships,
            // so it stays reachable even though the mockup only shows SKU.
            AppTextLink(
              label: '🔗 Have a product link? Paste it instead',
              onPressed: onPasteLink,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final sku = await showAppSheet<String>(
      context: context,
      builder: (_) => _SkuSheet(retailer: retailer),
    );
    if (sku != null && sku.isNotEmpty) onSubmit(sku);
  }
}

class _EnterSkuButton extends StatelessWidget {
  const _EnterSkuButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.tertiary,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter SKU',
                style: AppText.body14Semibold.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkuSheet extends StatefulWidget {
  const _SkuSheet({required this.retailer});

  final Retailer retailer;

  @override
  State<_SkuSheet> createState() => _SkuSheetState();
}

class _SkuSheetState extends State<_SkuSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Example ids per store, so it is obvious what is being asked for.
  String get _hint => switch (widget.retailer) {
        Retailer.amazon => 'e.g. B088NRLMPV',
        Retailer.bestBuy => 'e.g. 6565837',
        Retailer.ebay => 'e.g. 235049283746',
        _ => 'Product ID',
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: 'Enter a ${widget.retailer.label} SKU',
              subtitle: 'We will pull the product details straight from the store.',
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
                  AppTextField(
                    label: 'SKU or product ID',
                    controller: _controller,
                    hint: _hint,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  PrimaryButton(
                    label: 'Find product',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text.trim()),
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
