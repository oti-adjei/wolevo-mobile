import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../../auth/presentation/widgets/phone_field.dart';
import '../../data/cart_models.dart';
import '../cart_providers.dart';
import '../widgets/cart_cost_summary.dart';
import '../widgets/cart_item_row.dart';
import '../widgets/cart_step_indicator.dart';
import '../widgets/cart_support_note.dart';
import '../widgets/delivery_address_field.dart';
import '../widgets/promo_code_disclosure.dart';

/// `/cart` — Order Summary.
///
/// Two steps live on one route, exactly as the web app does it: `1 Items` and
/// `2 Delivery` swap the panel in place without a navigation, driven by local
/// state. Step 2's `Checkout` hands off to [CheckoutScreen].
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  /// 0 = Items, 1 = Delivery.
  int _step = 0;

  /// True while a cart mutation is in flight, so steppers cannot be
  /// double-tapped into an inconsistent quantity.
  bool _mutating = false;

  /// Guards against re-firing `checkout_started` when the user bounces between
  /// the two steps.
  bool _checkoutStartedReported = false;

  /// Moving to the delivery step is the real intent signal — the Checkout
  /// button itself is blocked until an address is chosen, so measuring there
  /// would miss everyone who dropped out at address selection.
  void _goToDelivery(Cart cart) {
    setState(() => _step = 1);
    if (_checkoutStartedReported) return;
    _checkoutStartedReported = true;
    ref
        .read(analyticsProvider)
        .track(
          AnalyticsEvents.checkoutStarted,
          properties: {
            'item_count': cart.itemCount,
            'subtotal_usd': cart.totals.subtotal.usd,
            'destination': cart.destinationCountry.code,
          },
        );
  }

  final _receiverNameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _receiverNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _mutating = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showAppSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.xl,
            AppSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Clear your list?', style: AppText.cardTitle),
              const SizedBox(height: AppSpace.sm),
              Text(
                'This removes every item from your cart. You can always add them again.',
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.xl),
              DestructiveButton(
                label: 'Clear List',
                expand: true,
                size: AppButtonSize.regular,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: AppSpace.sm),
              SecondaryButton(
                label: 'Keep my items',
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _run(() => ref.read(cartProvider.notifier).clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(cartProvider);
    final cart = async.valueOrNull;
    final itemCount = cart?.itemCount ?? 0;
    final isEmpty = cart != null && cart.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface6,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.shop);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order Summary', style: AppText.cardTitle),
            Text(
              _step == 0
                  ? '$itemCount items • Review your items'
                  : 'Set your delivery details',
              style: AppText.caption.copyWith(color: AppColors.neutral1),
            ),
          ],
        ),
      ),
      body: switch (async) {
        AsyncError(:final error) => ErrorRetry(
          message: '$error',
          onRetry: () => ref.read(cartProvider.notifier).refresh(),
        ),
        AsyncData(:final value) =>
          value.isEmpty
              ? const _EmptyCart()
              : (_step == 0
                    ? _buildItemsStep(value)
                    : _buildDeliveryStep(value)),
        _ => const AppLoader(),
      },
      bottomNavigationBar: cart == null || isEmpty
          ? null
          : (_step == 0 ? _buildItemsBar() : _buildDeliveryBar()),
    );
  }

  // ---------------------------------------------------------------- step 1

  Widget _buildItemsStep(Cart cart) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        const CartStepIndicator(currentIndex: 0),
        const SizedBox(height: AppSpace.xl),
        for (final group in cart.groups) ...[
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.retailer.label,
                          style: AppText.cardTitle,
                        ),
                      ),
                      Text(
                        '(${group.itemCount} items)',
                        style: AppText.body14.copyWith(
                          color: AppColors.neutral1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                for (var i = 0; i < group.items.length; i++) ...[
                  CartItemRow(
                    item: group.items[i],
                    busy: _mutating,
                    onQuantityChanged: (q) => _run(
                      () => ref
                          .read(cartProvider.notifier)
                          .updateQuantity(group.items[i].id, q),
                    ),
                    onRemove: () => _run(
                      () => ref
                          .read(cartProvider.notifier)
                          .removeItem(group.items[i].id),
                    ),
                  ),
                  if (i != group.items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        Row(
          children: [
            DestructiveButton(
              label: 'Clear List',
              icon: Icons.delete_outline,
              onPressed: _mutating ? null : _confirmClear,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: SecondaryButton(
                label: '+ Add More Items',
                size: AppButtonSize.compact,
                onPressed: () => context.go(AppRoutes.shop),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xxl),
        // MOBILE ADAPTATION: the web keeps this in a sticky sidebar; on a phone
        // it becomes a single column below the items.
        CartCostSummary(
          totals: cart.totals,
          itemCount: cart.itemCount,
          destinationName: cart.destinationCountry.name,
          promoCode: cart.promoCode,
        ),
        const SizedBox(height: AppSpace.lg),
        const CartCurrencyNote(),
      ],
    );
  }

  Widget _buildItemsBar() {
    final cart = ref.read(cartProvider).valueOrNull;
    return _StickyBar(
      children: [
        PrimaryButton(
          label: 'Continue',
          trailingIcon: Icons.arrow_forward,
          onPressed: _mutating || cart == null
              ? null
              : () => _goToDelivery(cart),
        ),
        const SizedBox(height: AppSpace.sm),
        SecondaryButton(
          label: 'Add More Items',
          size: AppButtonSize.compact,
          onPressed: () => context.go(AppRoutes.shop),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- step 2

  Widget _buildDeliveryStep(Cart cart) {
    final delivery = ref.watch(deliveryDetailsProvider);
    final controller = ref.read(deliveryDetailsProvider.notifier);
    final user = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        CartStepIndicator(
          currentIndex: 1,
          onStepTapped: (i) => setState(() => _step = i),
        ),
        const SizedBox(height: AppSpace.xl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Details', style: AppText.cardTitle),
              const SizedBox(height: AppSpace.lg),
              DeliveryCountryField(
                value: delivery.destinationCountry,
                onChanged: controller.setCountry,
              ),
              const SizedBox(height: AppSpace.lg),
              DeliveryAddressField(
                country: delivery.destinationCountry,
                selectedId: delivery.addressId,
                onSelected: controller.setAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Information', style: AppText.cardTitle),
              const SizedBox(height: AppSpace.lg),
              PhoneField(
                label: 'Phone Number',
                initialDestination: delivery.destinationCountry,
                // Prefilled from the account, exactly as the web's contact
                // field arrives populated.
                initialValue: user.phoneNumber,
                onChanged: (value) => controller.setPhone(
                  value.isEmpty ? user.phoneNumber : value,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We'll use this to contact you about your order",
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpace.sm),
              _ReceiverToggle(
                value: delivery.differentReceiver,
                onChanged: controller.setDifferentReceiver,
              ),
              if (delivery.differentReceiver) ...[
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Receiver Name',
                  required: true,
                  controller: _receiverNameController,
                  hint: 'Who is receiving this delivery?',
                  textCapitalization: TextCapitalization.words,
                  onChanged: controller.setReceiverName,
                ),
                const SizedBox(height: AppSpace.lg),
                PhoneField(
                  label: 'Receiver Phone',
                  initialDestination: delivery.destinationCountry,
                  onChanged: controller.setReceiverPhone,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          child: AppTextField(
            label: 'Order Notes',
            controller: _notesController,
            hint: 'e.g. Handle with care, specific packaging requests...',
            maxLines: 4,
            minLines: 3,
            onChanged: controller.setOrderNotes,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        PromoCodeDisclosure(appliedCode: cart.promoCode),
        const SizedBox(height: AppSpace.lg),
        CartCostSummary(
          totals: cart.totals,
          itemCount: cart.itemCount,
          destinationName: cart.destinationCountry.name,
          promoCode: cart.promoCode,
          onRemovePromo: cart.promoCode == null
              ? null
              : () => _run(() => ref.read(cartProvider.notifier).removePromo()),
        ),
        const SizedBox(height: AppSpace.lg),
        const CartCurrencyNote(),
      ],
    );
  }

  Widget _buildDeliveryBar() {
    final delivery = ref.watch(deliveryDetailsProvider);
    final canCheckout = delivery.isValid;

    return _StickyBar(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppTextLink(
            label: '← Back to Items',
            onPressed: () => setState(() => _step = 0),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        PrimaryButton(
          label: 'Checkout',
          onPressed: canCheckout
              ? () => context.push(AppRoutes.checkout)
              : null,
        ),
        if (!canCheckout) ...[
          const SizedBox(height: 6),
          Text(
            'Please select a delivery address',
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        const CartSupportNote(),
      ],
    );
  }
}

class _ReceiverToggle extends StatelessWidget {
  const _ReceiverToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: AppRadius.rSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.secondary,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Different receiver? (optional)',
                    style: AppText.body14Medium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Check this if someone else will receive the delivery',
                    style: AppText.caption.copyWith(color: AppColors.neutral1),
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      title: 'Your cart is empty',
      message: 'Browse US stores and add what you want shipped to your door.',
      actionLabel: 'Start Shopping',
      onAction: () => context.go(AppRoutes.shop),
    );
  }
}

/// Shared sticky footer: the web's sidebar buttons, moved to the bottom of the
/// viewport where a phone expects them.
class _StickyBar extends StatelessWidget {
  const _StickyBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface4)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.md,
          AppSpace.gutter,
          AppSpace.md,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
