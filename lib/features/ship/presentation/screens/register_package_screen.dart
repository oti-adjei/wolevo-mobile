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
import '../../../auth/presentation/auth_providers.dart';
import '../../data/ship_models.dart';
import '../ship_providers.dart';
import '../widgets/destination_country_field.dart';
import '../widgets/proof_of_purchase_field.dart';
import '../widgets/ship_journey_stepper.dart';

/// Step 2 of the shipping wizard — the `PACKAGE DETAILS` form.
///
/// MOBILE ADAPTATION: on the web this is an inline section of `/ship`. On a
/// phone it is its own route (pushed from ShipScreen) so the form owns the
/// full viewport and can carry a sticky submit bar.
class RegisterPackageScreen extends ConsumerStatefulWidget {
  const RegisterPackageScreen({super.key});

  @override
  ConsumerState<RegisterPackageScreen> createState() => _RegisterPackageScreenState();
}

class _RegisterPackageScreenState extends ConsumerState<RegisterPackageScreen> {
  final _trackingController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  DestinationCountry? _country;
  List<ProofFile> _proof = const [];

  @override
  void initState() {
    super.initState();
    _trackingController.addListener(_onFieldChanged);
    _valueController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFieldChanged() => setState(() {});

  double? get _declaredValue {
    final parsed = double.tryParse(_valueController.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  /// The site's `Next` stays disabled until country, tracking, value and at
  /// least one receipt are present.
  bool get _valid =>
      _country != null &&
      _trackingController.text.trim().isNotEmpty &&
      _declaredValue != null &&
      _proof.isNotEmpty;

  Future<void> _submit() async {
    final country = _country;
    final value = _declaredValue;
    if (country == null || value == null) return;

    FocusScope.of(context).unfocus();
    await ref.read(registerPackageProvider.notifier).submit(
          PackageRegistration(
            destinationCountryCode: country.code,
            trackingNumber: _trackingController.text.trim(),
            declaredValueUsd: value,
            notes: _notesController.text,
            proofOfPurchase: _proof,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Defaults to the user's own destination country, as the web select does.
    _country ??= ref.watch(currentUserProvider).destinationCountry;

    final submission = ref.watch(registerPackageProvider);
    final shipment = submission.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface6,
      appBar: AppBar(
        title: Text(shipment == null ? 'Register package' : 'Package registered'),
        leading: shipment == null
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
      ),
      body: shipment != null
          ? _RegistrationSuccess(shipment: shipment)
          : _buildForm(submission),
      bottomNavigationBar: shipment != null
          ? null
          : _StickyBar(
              enabled: _valid && !submission.isLoading,
              loading: submission.isLoading,
              onNext: _submit,
            ),
    );
  }

  Widget _buildForm(AsyncValue<RegisteredShipment?> submission) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        const ShipJourneyStepper(),
        const SizedBox(height: AppSpace.xl),
        if (submission.hasError) ...[
          ErrorBanner(message: submission.error.toString()),
          const SizedBox(height: AppSpace.lg),
        ],
        const EyebrowLabel('PACKAGE DETAILS'),
        const SizedBox(height: AppSpace.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DestinationCountryField(
                value: _country!,
                onChanged: (c) => setState(() => _country = c),
              ),
              const SizedBox(height: AppSpace.xl),
              AppTextField(
                label: 'Store tracking number',
                required: true,
                controller: _trackingController,
                hint: 'Enter tracking number',
                helper: 'From your carrier (USPS, UPS, FedEx, etc.)',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpace.xl),
              AppTextField(
                label: 'Total Value (USD)',
                required: true,
                controller: _valueController,
                hint: '0.00',
                helper: 'Total value of all items in the package',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.lg),
                  child: Icon(Icons.attach_money, size: 18, color: AppColors.neutral1),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              ProofOfPurchaseField(
                files: _proof,
                onChanged: (files) => setState(() => _proof = files),
              ),
              const SizedBox(height: AppSpace.xl),
              AppTextField(
                label: 'Notes',
                controller: _notesController,
                hint: 'e.g. Fragile items, repack request, special handling…',
                helper: 'Add any special instructions for your shipment',
                maxLines: 4,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky submit bar. The web keeps `Next →` at the bottom of the form; on a
/// phone it is pinned so it stays reachable while the form scrolls.
class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.enabled,
    required this.loading,
    required this.onNext,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onNext;

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
        child: PrimaryButton(
          label: 'Next',
          trailingIcon: Icons.arrow_forward,
          loading: loading,
          onPressed: enabled ? onNext : null,
        ),
      ),
    );
  }
}

/// ASSUMPTION: the live site's submit was never exercised (discovery-notes.md
/// § 3), so this confirmation screen is inferred from the surrounding patterns:
/// the 5-step journey (register → we receive & weigh → quote & pay →
/// delivered) and the `PENDING` status the `/orders` filters expose. What the
/// web actually renders after `Next` — a step 3, a redirect to `/orders`, or a
/// confirmation like this — is unknown.
class _RegistrationSuccess extends StatelessWidget {
  const _RegistrationSuccess({required this.shipment});

  final RegisteredShipment shipment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.section,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        const IconChip(icon: Icons.check_rounded, size: 56),
        const SizedBox(height: AppSpace.xl),
        Text('Package registered', style: AppText.h2),
        const SizedBox(height: AppSpace.sm),
        Text(
          "We're watching for it. Once it lands at the warehouse we'll weigh it and "
          'send you a quote.',
          style: AppText.body.copyWith(color: AppColors.neutral1),
        ),
        const SizedBox(height: AppSpace.xxl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: 'Shipment ID', value: shipment.id),
              _SummaryRow(label: 'Tracking number', value: shipment.trackingNumber),
              _SummaryRow(label: 'Destination', value: shipment.destinationCountry.name),
              _SummaryRow(label: 'Declared value', value: shipment.declaredValue.usdLabel),
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.md),
                child: Row(
                  children: [
                    const EyebrowLabel('STATUS'),
                    const Spacer(),
                    MicroBadge(
                      label: shipment.status.apiValue,
                      background: AppColors.secondary2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        PrimaryButton(
          label: 'View my orders',
          onPressed: () => context.go(AppRoutes.orders),
        ),
        const SizedBox(height: AppSpace.sm),
        SecondaryButton(
          label: 'Back to Ship',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EyebrowLabel(label),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.body14Semibold,
            ),
          ),
        ],
      ),
    );
  }
}
