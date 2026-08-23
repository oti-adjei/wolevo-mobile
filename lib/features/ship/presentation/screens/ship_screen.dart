import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/locker_address_card.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/ship_models.dart';
import '../ship_providers.dart';
import '../widgets/intent_explainer.dart';
import '../widgets/intent_selector.dart';
import '../widgets/ship_hero.dart';
import '../widgets/ship_journey_stepper.dart';
import 'register_package_screen.dart';

/// `/ship` — the forwarding half of the product: hero, three intent modes,
/// the locker address, and the entry point into package registration.
class ShipScreen extends ConsumerStatefulWidget {
  const ShipScreen({super.key});

  @override
  ConsumerState<ShipScreen> createState() => _ShipScreenState();
}

class _ShipScreenState extends ConsumerState<ShipScreen> {
  final _addressKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _select(ShipIntent intent) {
    ref.read(shipIntentProvider.notifier).state = intent;
  }

  /// MOBILE ADAPTATION: on the web `View Your Address` scrolls the page down to
  /// the (already visible) address accordion. On a phone the accordion is
  /// below the fold, so we scroll it into view.
  void _scrollToAddress() {
    final context = _addressKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      alignment: 0.05,
    );
  }

  void _copyAddressBlock() {
    final address = ref.read(warehouseAddressProvider);
    Clipboard.setData(ClipboardData(text: address.asBlock));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Address copied — send it to them')),
      );
  }

  /// MOBILE ADAPTATION: on the web the registration form is an inline section
  /// that appears under the intent cards once `Already shipped` is picked. On a
  /// phone a five-field form plus an uploader below three cards, a locker
  /// accordion and a 5-step tracker is an unusable scroll, so the form is its
  /// own full-screen route pushed from here.
  void _openRegisterForm() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterPackageScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final intent = ref.watch(shipIntentProvider);
    final address = ref.watch(warehouseAddressProvider);

    return Scaffold(
      backgroundColor: AppColors.surface6,
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.zero,
        children: [
          const ShipHero(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xl,
              AppSpace.gutter,
              AppSpace.section,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntentSelector(selected: intent, onChanged: _select),
                const SizedBox(height: AppSpace.xl),
                _IntentContent(
                  intent: intent,
                  onViewAddress: _scrollToAddress,
                  onCopyAddress: _copyAddressBlock,
                  onHaveTracking: () => _select(ShipIntent.alreadyShipped),
                  onRegister: _openRegisterForm,
                ),
                const SizedBox(height: AppSpace.xl),
                KeyedSubtree(
                  key: _addressKey,
                  child: LockerAddressPanel(
                    address: address,
                    initiallyExpanded: intent != ShipIntent.alreadyShipped,
                  ),
                ),
                const SizedBox(height: AppSpace.section),
                const _SupportFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The part of the page that swaps with the selected intent.
class _IntentContent extends StatelessWidget {
  const _IntentContent({
    required this.intent,
    required this.onViewAddress,
    required this.onCopyAddress,
    required this.onHaveTracking,
    required this.onRegister,
  });

  final ShipIntent intent;
  final VoidCallback onViewAddress;
  final VoidCallback onCopyAddress;
  final VoidCallback onHaveTracking;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    switch (intent) {
      case ShipIntent.yetToShop:
        return IntentExplainerCard(
          title: 'Three steps before you register',
          intro:
              "Three steps and you're shopping any American store like you live there.",
          steps: const [
            ExplainerStep(
              'Open your Wolevo locker address',
              "It's a real Delaware address — tax-free. Use it at any US checkout.",
            ),
            ExplainerStep(
              'Shop any US store, ship to your locker',
              "USPS, UPS, FedEx, doesn't matter. Any carrier works. Relatives in the "
                  'States can send to it too.',
            ),
            ExplainerStep(
              'Come back with your tracking number',
              'Once it ships, register it here so we can match it when it lands.',
            ),
          ],
          actions: [
            PrimaryButton(label: 'View Your Address', onPressed: onViewAddress),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: AppTextLink(
                label: 'I actually have a tracking number →',
                onPressed: onHaveTracking,
              ),
            ),
          ],
        );

      case ShipIntent.someoneSending:
        return IntentExplainerCard(
          title: 'Getting a package from someone in the US',
          intro:
              'Family, friend, or anyone in the States — they ship, you receive it '
              'at your doorstep. Three steps:',
          steps: const [
            ExplainerStep(
              'Send them your locker address',
              'Copy it below and send it however you want — text, WhatsApp, email. '
                  'Make sure your locker ID is there.',
            ),
            ExplainerStep(
              'They ship it with your locker ID on the label',
              "USPS, UPS, FedEx, whatever. The locker ID tells us it's yours.",
            ),
            ExplainerStep(
              'Ask them for tracking + receipt',
              'Once it ships, get the tracking number and a photo of the receipt, '
                  'then register it here.',
            ),
          ],
          actions: [
            PrimaryButton(
              label: 'Copy address to send them',
              onPressed: onCopyAddress,
            ),
            const SizedBox(height: AppSpace.sm),
            Center(
              child: AppTextLink(
                label: 'They already shipped it →',
                onPressed: onHaveTracking,
              ),
            ),
          ],
        );

      case ShipIntent.alreadyShipped:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShipJourneyStepper(),
            const SizedBox(height: AppSpace.lg),
            PrimaryButton(
              label: 'Register package',
              trailingIcon: Icons.arrow_forward,
              onPressed: onRegister,
            ),
          ],
        );
    }
  }
}

/// The site keeps a support affordance on every step of the shipping flow —
/// WhatsApp from `/ship`, plus the help centre (discovery-notes.md § "Anything
/// else notable", item 6). The locker panel carries its own WhatsApp link; this
/// is the page-level fallback.
class _SupportFooter extends StatelessWidget {
  const _SupportFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Not sure about something?',
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        const SizedBox(height: 2),
        AppTextLink(
          label: 'Ask on WhatsApp or visit support →',
          // ASSUMPTION: the WhatsApp handoff on the web opens a wa.me deep link
          // whose number was not captured, so the app routes to its own support
          // screen, which owns the channel list.
          onPressed: () => context.push(AppRoutes.support),
        ),
      ],
    );
  }
}
