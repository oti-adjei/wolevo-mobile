import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/cart_models.dart';
import '../cart_providers.dart';

/// `🏷️ Have a promo code? ⌄` — collapsed by default, exactly as the web
/// sidebar renders it. Expanding reveals a field and an `Apply` button.
///
/// The apply endpoint was never captured during discovery (see § "States not
/// reached"), so the mock accepts a single code and rejects everything else.
class PromoCodeDisclosure extends ConsumerStatefulWidget {
  const PromoCodeDisclosure({super.key, required this.appliedCode});

  final String? appliedCode;

  @override
  ConsumerState<PromoCodeDisclosure> createState() =>
      _PromoCodeDisclosureState();
}

class _PromoCodeDisclosureState extends ConsumerState<PromoCodeDisclosure> {
  final _controller = TextEditingController();
  bool _expanded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a promo code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(cartProvider.notifier).applyPromo(code);
      if (!mounted) return;
      setState(() => _busy = false);
    } on PromoCodeException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "That code couldn't be applied. Try again.";
      });
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    await ref.read(cartProvider.notifier).removePromo();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final applied = widget.appliedCode;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Row(
                children: [
                  Text('🏷️', style: AppText.body14),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      applied == null
                          ? 'Have a promo code?'
                          : 'Promo code applied',
                      style: AppText.body14Semibold,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.neutral1,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            const SizedBox(height: AppSpace.md),
            if (applied != null)
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.success2,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      '$applied applied',
                      style: AppText.body14Semibold.copyWith(
                        color: AppColors.success2,
                      ),
                    ),
                  ),
                  AppTextLink(
                    label: 'Remove',
                    color: AppColors.neutral1,
                    onPressed: _busy ? null : _remove,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.characters,
                      style: AppText.body,
                      decoration: const InputDecoration(hintText: 'Promo code'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  SecondaryButton(
                    label: 'Apply',
                    expand: false,
                    onPressed: _busy ? null : _apply,
                  ),
                ],
              ),
            if (_error case final message?) ...[
              const SizedBox(height: 6),
              FieldError(message),
            ],
            const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }
}
