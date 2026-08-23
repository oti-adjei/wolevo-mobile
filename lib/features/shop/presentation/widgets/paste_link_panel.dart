import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/shop_models.dart';
import '../shop_providers.dart';

/// `?mode=paste` — paste a retailer URL and Wolevo resolves it into a product.
///
/// The retailer scope selector sits above this panel on the screen, so the
/// panel itself is the field, the CTA and the site's four-step instructions
/// card.
class PasteLinkPanel extends ConsumerStatefulWidget {
  const PasteLinkPanel({
    super.key,
    required this.retailer,
    required this.onResolved,
  });

  final Retailer retailer;

  /// Fired once the URL resolves — the screen pushes the product route.
  final ValueChanged<ShopListing> onResolved;

  @override
  ConsumerState<PasteLinkPanel> createState() => _PasteLinkPanelState();
}

class _PasteLinkPanelState extends ConsumerState<PasteLinkPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    FocusScope.of(context).unfocus();
    final listing = await ref.read(pasteLinkProvider.notifier).submit(url);
    if (listing != null) widget.onResolved(listing);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pasteLinkProvider);
    final store = widget.retailer.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Product link',
          controller: _controller,
          hint: 'Paste a product URL (e.g., amazon.com/dp/…)',
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          errorText: state.errorMessage,
          enabled: !state.submitting,
          onChanged: (_) {
            if (state.errorMessage != null) {
              ref.read(pasteLinkProvider.notifier).reset();
            }
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton(
          label: 'Get Product',
          loading: state.submitting,
          onPressed: state.submitting ? null : _submit,
        ),
        const SizedBox(height: AppSpace.xl),
        _InstructionsCard(store: store),
      ],
    );
  }
}

/// The pale-lime card under the field. The four steps are the site's copy,
/// verbatim, with the store name following the selected retailer.
class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.store});

  final String store;

  @override
  Widget build(BuildContext context) {
    final steps = <String>[
      'Go to $store and find the product you want',
      "Copy the URL from your browser's address bar",
      'Paste it here and click "Get Product"',
      "We'll extract the details and you can add it to your cart",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: AppColors.tertiary3,
        borderRadius: AppRadius.rCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How it works', style: AppText.body14Semibold),
          const SizedBox(height: AppSpace.md),
          for (final (index, step) in steps.indexed) ...[
            if (index > 0) const SizedBox(height: AppSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 22,
                  width: 22,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary3,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppText.micro.copyWith(color: AppColors.background),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    step,
                    style: AppText.body14.copyWith(color: AppColors.secondary5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
