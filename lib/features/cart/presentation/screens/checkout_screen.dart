// INFERRED SCREEN: the live Checkout button leads to a real payment flow that
//  was deliberately not exercised during discovery (see discovery-notes.md
//  § "States not reached"). The rails below are the three the product page
//  advertises: Card, Mobile Money and Bank Transfer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/widgets/phone_field.dart';
import '../../../profile/data/profile_models.dart';
import '../../../profile/presentation/profile_providers.dart';
import '../../data/cart_models.dart';
import '../cart_providers.dart';
import '../widgets/cart_cost_summary.dart';
import '../widgets/cart_support_note.dart';

/// The mobile-money networks Wolevo's Ghana/Nigeria customers actually use.
// ASSUMPTION: invented — the payment step was never reached, so the network
// list comes from the country's live MoMo providers, not from the site.
enum MobileMoneyNetwork {
  mtn('MTN'),
  telecel('Telecel'),
  airtelTigo('AirtelTigo');

  const MobileMoneyNetwork(this.label);

  final String label;
}

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.mobileMoney;
  MobileMoneyNetwork _network = MobileMoneyNetwork.mtn;
  String _momoPhone = '';

  @override
  Widget build(BuildContext context) {
    final checkout = ref.watch(checkoutControllerProvider);
    final result = checkout.valueOrNull;

    if (result != null) {
      return _SuccessScreen(result: result);
    }

    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.surface6,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.cart),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Checkout', style: AppText.cardTitle),
            Text(
              'Choose how you want to pay',
              style: AppText.caption.copyWith(color: AppColors.neutral1),
            ),
          ],
        ),
      ),
      body: switch (cartAsync) {
        AsyncError(:final error) => ErrorRetry(
            message: '$error',
            onRetry: () => ref.read(cartProvider.notifier).refresh(),
          ),
        AsyncData(:final value) => value.isEmpty
            ? const EmptyState(
                icon: Icons.shopping_cart_outlined,
                title: 'Your cart is empty',
                message: 'There is nothing left to pay for.',
              )
            : _buildBody(value, checkout),
        _ => const AppLoader(),
      },
      bottomNavigationBar: switch (cartAsync) {
        AsyncData(:final value) when !value.isEmpty => _PayBar(
            label: 'Pay ${value.totals.estimatedTotal.usdLabel}',
            localLabel: value.totals.estimatedTotal.localLabel,
            loading: checkout.isLoading,
            onPay: _canPay ? _pay : null,
          ),
        _ => null,
      },
    );
  }

  bool get _canPay =>
      _method != PaymentMethod.mobileMoney || _momoPhone.trim().length >= 9;

  Future<void> _pay() async {
    await ref.read(checkoutControllerProvider.notifier).pay(_method);
    if (!mounted) return;
    final state = ref.read(checkoutControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Payment failed: ${state.error}')),
        );
    }
  }

  Widget _buildBody(Cart cart, AsyncValue<CheckoutResult?> checkout) {
    final delivery = ref.watch(deliveryDetailsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        if (checkout.hasError) ...[
          ErrorBanner(message: '${checkout.error}'),
          const SizedBox(height: AppSpace.lg),
        ],
        _OrderRecap(cart: cart, delivery: delivery),
        const SizedBox(height: AppSpace.lg),
        CartCostSummary(
          totals: cart.totals,
          itemCount: cart.itemCount,
          destinationName: cart.destinationCountry.name,
          promoCode: cart.promoCode,
        ),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Payment method'),
        const SizedBox(height: AppSpace.md),
        for (final method in PaymentMethod.values) ...[
          SelectableCard(
            selected: _method == method,
            onTap: () => setState(() => _method = method),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconChip(icon: _iconFor(method), size: 40),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(method.label, style: AppText.body14Semibold),
                      const SizedBox(height: 2),
                      Text(
                        method.subtitle,
                        style: AppText.caption.copyWith(color: AppColors.neutral1),
                      ),
                      if (_method == method) ...[
                        const SizedBox(height: AppSpace.sm),
                        const SelectedMarker(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        const SizedBox(height: AppSpace.sm),
        switch (_method) {
          PaymentMethod.mobileMoney => _MobileMoneyPanel(
              network: _network,
              onNetworkChanged: (n) => setState(() => _network = n),
              destination: cart.destinationCountry,
              onPhoneChanged: (v) => setState(() => _momoPhone = v),
            ),
          PaymentMethod.card => const _CardPanel(),
          PaymentMethod.bankTransfer => const _BankTransferPanel(),
        },
        const SizedBox(height: AppSpace.xxl),
        const CartSupportNote(),
      ],
    );
  }

  IconData _iconFor(PaymentMethod method) => switch (method) {
        PaymentMethod.card => Icons.credit_card,
        PaymentMethod.mobileMoney => Icons.smartphone,
        PaymentMethod.bankTransfer => Icons.account_balance,
      };
}

class _OrderRecap extends ConsumerWidget {
  const _OrderRecap({required this.cart, required this.delivery});

  final Cart cart;
  final DeliveryDetails delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(savedAddressesProvider).valueOrNull ?? const [];
    SavedAddress? address;
    for (final a in addresses) {
      if (a.id == delivery.addressId) address = a;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Your order', style: AppText.cardTitle)),
              Text(
                '${cart.itemCount} items',
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpace.md),
          const EyebrowLabel('Delivering to'),
          const SizedBox(height: 4),
          if (address == null)
            Text(
              delivery.destinationCountry.name,
              style: AppText.body14.copyWith(color: AppColors.neutral1),
            )
          else
            Text(address.formatted, style: AppText.body14),
          if (delivery.differentReceiver &&
              (delivery.receiverName?.isNotEmpty ?? false)) ...[
            const SizedBox(height: AppSpace.md),
            const EyebrowLabel('Receiver'),
            const SizedBox(height: 4),
            Text(delivery.receiverName!, style: AppText.body14),
          ],
        ],
      ),
    );
  }
}

class _MobileMoneyPanel extends StatelessWidget {
  const _MobileMoneyPanel({
    required this.network,
    required this.onNetworkChanged,
    required this.destination,
    required this.onPhoneChanged,
  });

  final MobileMoneyNetwork network;
  final ValueChanged<MobileMoneyNetwork> onNetworkChanged;
  final DestinationCountry destination;
  final ValueChanged<String> onPhoneChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FieldLabel('Network', required: true),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final option in MobileMoneyNetwork.values)
                _NetworkChip(
                  label: option.label,
                  selected: option == network,
                  onTap: () => onNetworkChanged(option),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          PhoneField(
            label: 'Mobile Money Number',
            initialDestination: destination,
            onChanged: onPhoneChanged,
          ),
          const SizedBox(height: 6),
          Text(
            "You'll get a prompt on this number to approve the payment",
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ],
      ),
    );
  }
}

class _NetworkChip extends StatelessWidget {
  const _NetworkChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary2 : AppColors.background,
          borderRadius: AppRadius.rPill,
          border: Border.all(
            color: selected ? AppColors.secondary3 : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: selected
              ? AppText.body14Semibold.copyWith(color: AppColors.secondary)
              : AppText.body14,
        ),
      ),
    );
  }
}

/// Card payments hand off to the provider's hosted page.
///
/// Collecting raw card numbers in-app is deliberately out of scope: it drags
/// PCI-DSS scope into the client and the live flow was never observed, so there
/// is nothing to copy. The redirect is the safe, conventional shape.
class _CardPanel extends StatelessWidget {
  const _CardPanel();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppColors.secondary),
              SizedBox(width: AppSpace.sm),
              Text("You'll be redirected to pay"),
            ],
          ),
          SizedBox(height: AppSpace.sm),
          Text(
            'Wolevo never handles your card details. Tapping Pay opens the '
            'payment provider’s secure page, where you enter your Visa or '
            'Mastercard details and approve the charge.',
          ),
          SizedBox(height: AppSpace.sm),
          Text(
            "You'll come straight back here once the payment clears.",
          ),
        ],
      ),
    );
  }
}

/// Bank transfer: show where to send the money and set the expectation that
/// nothing ships until it lands.
// ASSUMPTION: the account details below are placeholders — no bank details were
// observed anywhere in the live app.
class _BankTransferPanel extends StatelessWidget {
  const _BankTransferPanel();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transfer to', style: AppText.cardTitleMedium),
          const SizedBox(height: AppSpace.md),
          const _CopyRow(label: 'Bank', value: 'Ecobank Ghana'),
          const Divider(height: AppSpace.xl),
          const _CopyRow(label: 'Account name', value: 'Wolevo Logistics Ltd'),
          const Divider(height: AppSpace.xl),
          const _CopyRow(label: 'Account number', value: '1441000123456'),
          const SizedBox(height: AppSpace.lg),
          const InfoCallout(
            leading: 'ℹ️',
            child: Text(
              'Use your order reference as the transfer narration. Your order '
              'ships once the transfer clears — usually within one business day.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EyebrowLabel(label),
              const SizedBox(height: 2),
              Text(value, style: AppText.body14Semibold),
            ],
          ),
        ),
        Material(
          color: AppColors.secondary2,
          borderRadius: AppRadius.rSm,
          child: InkWell(
            borderRadius: AppRadius.rSm,
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text('$label copied')));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                'Copy',
                style: AppText.captionSemibold.copyWith(color: AppColors.secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({
    required this.label,
    required this.localLabel,
    required this.loading,
    required this.onPay,
  });

  final String label;
  final String localLabel;
  final bool loading;
  final VoidCallback? onPay;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(label: label, loading: loading, onPressed: onPay),
            const SizedBox(height: 6),
            Text(
              'Approximately $localLabel',
              style: AppText.caption.copyWith(color: AppColors.neutral1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post-payment confirmation. Replaces the whole screen so there is nothing
/// left to pay for behind it.
class _SuccessScreen extends StatelessWidget {
  const _SuccessScreen({required this.result});

  final CheckoutResult result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface6,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: IconChip(icon: Icons.check, size: 72),
              ),
              const SizedBox(height: AppSpace.xl),
              Text(
                'Payment received',
                textAlign: TextAlign.center,
                style: AppText.h3,
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'We’re buying your items now. You’ll get updates as your parcel '
                'moves through our US warehouse.',
                textAlign: TextAlign.center,
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.xl),
              AppCard(
                child: Column(
                  children: [
                    const EyebrowLabel('Order reference'),
                    const SizedBox(height: 4),
                    Text(result.orderReference, style: AppText.cardTitle),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      '${result.paidAmount.usdLabel} · ${result.paidAmount.localLabel}',
                      style: AppText.body14.copyWith(color: AppColors.neutral1),
                    ),
                    Text(
                      'Paid by ${result.method.label}',
                      style: AppText.caption.copyWith(color: AppColors.neutral1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              PrimaryButton(
                label: 'Track your order',
                onPressed: () => context.go(AppRoutes.orders),
              ),
              const SizedBox(height: AppSpace.sm),
              SecondaryButton(
                label: 'Keep shopping',
                onPressed: () => context.go(AppRoutes.shop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
