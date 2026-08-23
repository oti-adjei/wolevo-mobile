import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/calculator_models.dart';
import '../calculator_providers.dart';

/// The shipping calculator card.
///
/// Deliberately self-contained and Scaffold-free: the same widget is embedded
/// inline on the landing page (`/#shipping-calculator`, fully usable logged
/// out) and wrapped by [CalculatorScreen] for the standalone `/calculator`
/// route — discovery-notes.md § 2.9 and § "Landing", item 11.
class CalculatorPanel extends ConsumerStatefulWidget {
  const CalculatorPanel({super.key});

  @override
  ConsumerState<CalculatorPanel> createState() => _CalculatorPanelState();
}

class _CalculatorPanelState extends ConsumerState<CalculatorPanel> {
  EstimateMode _mode = EstimateMode.link;

  /// Null until the user picks. The web select opens on `-Select Country-`,
  /// and this route is public so there is no profile country to fall back to.
  DestinationCountry? _destination;

  final _urlController = TextEditingController();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();

  WeightUnit _weightUnit = WeightUnit.lbs;
  DimensionUnit _dimensionUnit = DimensionUnit.cm;

  @override
  void dispose() {
    _urlController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim());

  bool get _canSubmit {
    if (_destination == null) return false;
    return switch (_mode) {
      EstimateMode.link => _urlController.text.trim().isNotEmpty,
      EstimateMode.weight => (_parse(_weightController) ?? 0) > 0,
    };
  }

  void _setMode(EstimateMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    // Switching tabs abandons the previous quote — the web card swaps the whole
    // form, so a stale result would describe inputs that are no longer visible.
    ref.read(calculatorEstimateProvider.notifier).reset();
  }

  Future<void> _pickCountry() async {
    // The web uses a native `<select>` with a `-Select Country-` placeholder;
    // on a phone every dropdown becomes a bottom sheet.
    final picked = await showAppSheet<Object>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpace.lg),
            const SheetHeader(
              title: 'Destination country',
              subtitle: 'Where are we shipping to?',
            ),
            ListTile(
              onTap: () => Navigator.of(ctx).pop(_clearCountry),
              title: Text(
                '-Select Country-',
                style: AppText.bodyMedium.copyWith(color: AppColors.neutral1),
              ),
              trailing: _destination == null
                  ? const Icon(Icons.check, color: AppColors.secondary)
                  : null,
            ),
            for (final country in DestinationCountry.values)
              ListTile(
                onTap: () => Navigator.of(ctx).pop(country),
                leading: Text(country.flag, style: AppText.h3),
                title: Text(country.name, style: AppText.bodyMedium),
                trailing: country == _destination
                    ? const Icon(Icons.check, color: AppColors.secondary)
                    : null,
              ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    );

    if (picked == null) return;
    setState(() {
      _destination = picked == _clearCountry ? null : picked as DestinationCountry;
    });
  }

  /// Sentinel so the sheet can distinguish "picked the placeholder" from
  /// "dismissed the sheet".
  static const _clearCountry = Object();

  void _submit() {
    final destination = _destination;
    if (destination == null) return;

    final request = _mode == EstimateMode.link
        ? ShippingEstimateRequest(
            destinationCountryCode: destination.code,
            mode: EstimateMode.link,
            productUrl: _urlController.text.trim(),
          )
        : ShippingEstimateRequest(
            destinationCountryCode: destination.code,
            mode: EstimateMode.weight,
            weight: _parse(_weightController),
            weightUnit: _weightUnit,
            length: _parse(_lengthController),
            width: _parse(_widthController),
            height: _parse(_heightController),
            dimensionUnit: _dimensionUnit,
          );

    FocusScope.of(context).unfocus();
    ref.read(calculatorEstimateProvider.notifier).submit(request);
  }

  void _reset() {
    setState(() {
      _urlController.clear();
      _weightController.clear();
      _lengthController.clear();
      _widthController.clear();
      _heightController.clear();
    });
    ref.read(calculatorEstimateProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorEstimateProvider);
    final estimate = state.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          radius: AppRadius.rCardLarge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModeTabs(mode: _mode, onChanged: _setMode),
              const SizedBox(height: AppSpace.xxl),
              const EyebrowLabel('SHIPPING CALCULATOR'),
              const SizedBox(height: AppSpace.sm),
              Text('Know your cost before you buy.', style: AppText.h3),
              const SizedBox(height: AppSpace.sm),
              Text(
                "Paste a product link or enter weight and dimensions. We'll show "
                'you the exact shipping cost to your country.',
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.xxl),
              _CountrySelect(value: _destination, onTap: _pickCountry),
              const SizedBox(height: AppSpace.xl),
              if (_mode == EstimateMode.link) _buildLinkForm() else _buildWeightForm(),
              if (state.hasError) ...[
                const SizedBox(height: AppSpace.lg),
                ErrorBanner(message: _messageFor(state.error!)),
              ],
              const SizedBox(height: AppSpace.xl),
              PrimaryButton(
                label: 'Get Estimate',
                trailingIcon: Icons.arrow_forward,
                loading: state.isLoading,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                'Some items like electronics, fragrances, and lithium batteries '
                'may have fixed pricing due to higher import duties or special '
                'handling requirements.',
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        if (estimate != null)
          _ResultCard(estimate: estimate, onAnother: _reset)
        else
          _PlaceholderCard(mode: _mode),
        const SizedBox(height: AppSpace.xxl),
        const _ValueProps(),
      ],
    );
  }

  String _messageFor(Object error) =>
      error is ApiException ? error.message : ApiException.network.message;

  Widget _buildLinkForm() {
    return AppTextField(
      label: 'PRODUCT LINK',
      controller: _urlController,
      hint: 'Paste a product URL (e.g., amazon.com/dp/…)',
      helper: 'Supported: Amazon, eBay, Fashion Nova, Plug Tech, Best Buy, and Sephora',
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      onChanged: (_) => setState(() {}),
      onSubmitted: (_) => _canSubmit ? _submit() : null,
    );
  }

  Widget _buildWeightForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'WEIGHT',
          controller: _weightController,
          hint: 'e.g 1.5',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimalFormatters,
          onChanged: (_) => setState(() {}),
          suffix: _UnitToggle<WeightUnit>(
            values: WeightUnit.values,
            value: _weightUnit,
            labelOf: (u) => u.label,
            onChanged: (u) => setState(() => _weightUnit = u),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const FieldLabel('DIMENSIONS (optional)'),
        const SizedBox(height: AppSpace.sm),
        // The web lays L / W / H / unit out as four inline selects. At 375px
        // four columns are unreadable, so the three numeric fields stay in one
        // equal-width Row (8px gaps — tight but legible) and the shared unit
        // toggle drops to its own line beneath them.
        Row(
          children: [
            Expanded(child: _DimensionField(controller: _lengthController, hint: 'L')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: _DimensionField(controller: _widthController, hint: 'W')),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: _DimensionField(controller: _heightController, hint: 'H')),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: _UnitToggle<DimensionUnit>(
            values: DimensionUnit.values,
            value: _dimensionUnit,
            labelOf: (u) => u.label,
            onChanged: (u) => setState(() => _dimensionUnit = u),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Helps us give you a more accurate shipping estimate.',
          style: AppText.caption.copyWith(color: AppColors.neutral1),
        ),
      ],
    );
  }
}

final _decimalFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
];

/// The two-tab segmented control at the top of the card. Active tab is a lime
/// pill with a dark-green label; inactive is transparent with a neutral label.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onChanged});

  final EstimateMode mode;
  final ValueChanged<EstimateMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Tab(
              label: 'Paste a Link',
              icon: Icons.link,
              active: mode == EstimateMode.link,
              onTap: () => onChanged(EstimateMode.link),
            ),
          ),
          Expanded(
            child: _Tab(
              label: 'Enter Weight',
              icon: Icons.inventory_2_outlined,
              active: mode == EstimateMode.weight,
              onTap: () => onChanged(EstimateMode.weight),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.secondary : AppColors.neutral1;
    return InkWell(
      borderRadius: AppRadius.rPill,
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.tertiary : Colors.transparent,
          borderRadius: AppRadius.rPill,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppText.body14Semibold.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountrySelect extends StatelessWidget {
  const _CountrySelect({required this.value, required this.onTap});

  final DestinationCountry? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final country = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('DESTINATION COUNTRY', required: true),
        const SizedBox(height: AppSpace.sm),
        InkWell(
          borderRadius: AppRadius.rInput,
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppRadius.rInput,
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                if (country != null) ...[
                  Text(country.flag, style: AppText.body),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  child: Text(
                    country?.name ?? '-Select Country-',
                    style: country == null
                        ? AppText.body.copyWith(color: AppColors.neutral2)
                        : AppText.body,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral1),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact numeric box used for L / W / H. No label of its own — the group
/// carries the `DIMENSIONS (optional)` label.
class _DimensionField extends StatelessWidget {
  const _DimensionField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimalFormatters,
      textAlign: TextAlign.center,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.sm,
          vertical: AppSpace.md,
        ),
      ),
    );
  }
}

/// Two-value segmented selector (lbs/kg, cm/in) — the phone stand-in for the
/// web's inline `<select>`.
class _UnitToggle<T> extends StatelessWidget {
  const _UnitToggle({
    required this.values,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });

  final List<T> values;
  final T value;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in values)
            InkWell(
              borderRadius: AppRadius.rPill,
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: option == value ? AppColors.secondary : Colors.transparent,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  labelOf(option),
                  style: AppText.captionSemibold.copyWith(
                    color: option == value ? Colors.white : AppColors.neutral1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Zero-state that occupies the result slot before the first quote.
class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.mode});

  final EstimateMode mode;

  @override
  Widget build(BuildContext context) {
    final copy = mode == EstimateMode.link
        ? 'Paste a product link and hit Get Estimate to see your shipping cost.'
        : 'Fill the form and hit Calculate to see your complete shipping breakdown.';

    return AppCard(
      color: AppColors.surface6,
      radius: AppRadius.rCardLarge,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.cardPadding,
        vertical: AppSpace.section,
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.surface5),
          const SizedBox(height: AppSpace.md),
          Text(
            copy,
            textAlign: TextAlign.center,
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
        ],
      ),
    );
  }
}

/// Dark-green result panel: `Shipping to Ghana`, `Shipping (USD) $20.00`,
/// `Shipping (GHS) GHS 244.00`, handling-fee note, `Get Another Quote`.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.estimate, required this.onAnother});

  final ShippingEstimate estimate;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.secondary,
      borderColor: AppColors.secondary,
      radius: AppRadius.rCardLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📦', style: AppText.h3),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  'Shipping to ${estimate.destination.name}',
                  style: AppText.cardTitle.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          if (estimate.productTitle != null) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              estimate.productTitle!,
              style: AppText.body14.copyWith(color: AppColors.secondary7),
            ),
          ],
          const SizedBox(height: AppSpace.xl),
          _ResultRow(
            label: 'Shipping (USD)',
            value: estimate.shipping.usdLabel,
          ),
          const SizedBox(height: AppSpace.md),
          _ResultRow(
            label: 'Shipping (${estimate.shipping.localCurrency})',
            value: estimate.shipping.localLabel,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            'Handling fees may apply at checkout.',
            style: AppText.caption.copyWith(color: AppColors.secondary7),
          ),
          const SizedBox(height: AppSpace.xl),
          SecondaryButton(label: 'Get Another Quote', onPressed: onAnother),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body14.copyWith(color: AppColors.secondary7),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Text(
          value,
          style: AppText.cardTitle.copyWith(color: AppColors.tertiary),
        ),
      ],
    );
  }
}

/// Three reassurance blocks under the result. The web renders them as a 3-up
/// row; on a phone they stack.
class _ValueProps extends StatelessWidget {
  const _ValueProps();

  @override
  Widget build(BuildContext context) {
    const props = [
      (r'$', 'Transparent Pricing', 'No hidden fees. Breakdown includes everything.'),
      ('⚡', 'Instant Estimate', 'See costs immediately with your package details'),
      ('✓', 'No Surprises', 'The price you see is the price you pay'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (glyph, title, body) in props)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.secondary2,
                    borderRadius: AppRadius.rCard,
                  ),
                  child: Text(
                    glyph,
                    style: AppText.bodySemibold.copyWith(color: AppColors.secondary),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.body14Semibold),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: AppText.caption.copyWith(color: AppColors.neutral1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
