import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/profile_models.dart';
import '../profile_providers.dart';

/// Add / edit a delivery address.
///
/// The web app ran this as a centered three-step modal. On a phone it is a
/// full-screen route with a step indicator, which is the native equivalent and
/// leaves room for the country list and the city typeahead.
class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key, this.existing});

  final SavedAddress? existing;

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  int _step = 0;

  DestinationCountry? _country;
  GeocodedPlace? _place;

  final _street = TextEditingController();
  final _apartment = TextEditingController();
  final _label = TextEditingController();
  final _landmark = TextEditingController();
  final _cityQuery = TextEditingController();

  bool _isPrimary = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _country = DestinationCountry.fromCode(existing.countryCode);
      _place = GeocodedPlace(
        city: existing.city,
        region: existing.region,
        countryCode: existing.countryCode,
        countryName: DestinationCountry.fromCode(existing.countryCode).name,
        flag: DestinationCountry.fromCode(existing.countryCode).flag,
      );
      _street.text = existing.streetAddress ?? '';
      _apartment.text = existing.apartment ?? '';
      _label.text = existing.label ?? '';
      _landmark.text = existing.nearestLandmark ?? '';
      _isPrimary = existing.isPrimary;
      _step = 2;
    }
  }

  @override
  void dispose() {
    _street.dispose();
    _apartment.dispose();
    _label.dispose();
    _landmark.dispose();
    _cityQuery.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
    0 => _country != null,
    1 => _place != null,
    _ => true,
  };

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    _save();
  }

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _save() async {
    final place = _place;
    if (place == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(savedAddressesProvider.notifier)
          .save(
            SavedAddress(
              id: widget.existing?.id ?? '',
              countryCode: place.countryCode,
              city: place.city,
              region: place.region,
              streetAddress: _street.text.trim().isEmpty
                  ? null
                  : _street.text.trim(),
              apartment: _apartment.text.trim().isEmpty
                  ? null
                  : _apartment.text.trim(),
              label: _label.text.trim().isEmpty ? null : _label.text.trim(),
              nearestLandmark: _landmark.text.trim().isEmpty
                  ? null
                  : _landmark.text.trim(),
              isPrimary: _isPrimary,
            ),
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Address saved')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        title: Text(
          widget.existing == null ? 'Enter a New Address' : 'Edit Address',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _StepIndicator(step: _step),
            Expanded(
              child: switch (_step) {
                0 => _CountryStep(
                  selected: _country,
                  onSelected: (c) => setState(() {
                    _country = c;
                    _place = null;
                    ref.read(citySearchProvider.notifier).setCountry(c.code);
                  }),
                ),
                1 => _CityStep(
                  controller: _cityQuery,
                  selected: _place,
                  onSelected: (p) => setState(() => _place = p),
                ),
                _ => _DetailsStep(
                  place: _place!,
                  street: _street,
                  apartment: _apartment,
                  label: _label,
                  landmark: _landmark,
                  isPrimary: _isPrimary,
                  onPrimaryChanged: (v) => setState(() => _isPrimary = v),
                ),
              },
            ),
            _BottomBar(
              label: _step < 2 ? 'Continue' : 'Save Address',
              enabled: _canAdvance && !_saving,
              loading: _saving,
              onPressed: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  static const _labels = ['Country', 'City', 'Details'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.lg,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? AppColors.secondary
                          : AppColors.surface4,
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Step ${i + 1}: ${_labels[i]}',
                    style: AppText.caption.copyWith(
                      color: i <= step
                          ? AppColors.secondary
                          : AppColors.neutral2,
                    ),
                  ),
                ],
              ),
            ),
            if (i != _labels.length - 1) const SizedBox(width: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _CountryStep extends StatelessWidget {
  const _CountryStep({required this.selected, required this.onSelected});

  final DestinationCountry? selected;
  final ValueChanged<DestinationCountry> onSelected;

  @override
  Widget build(BuildContext context) {
    // The web app listed every ISO country here, but Wolevo only delivers to
    // two. Showing ~250 unreachable options on a phone is noise, so the
    // deliverable countries are the list and everything else is explained in a
    // callout rather than rendered as dead rows.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        const EyebrowLabel('We deliver here'),
        const SizedBox(height: AppSpace.md),
        for (final country in DestinationCountry.values) ...[
          SelectableCard(
            selected: selected == country,
            onTap: () => onSelected(country),
            child: Row(
              children: [
                Text(country.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(country.name, style: AppText.cardTitleMedium),
                      Text(
                        'Delivery and pickup available',
                        style: AppText.caption.copyWith(
                          color: AppColors.neutral1,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected == country) const SelectedMarker(),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        const SizedBox(height: AppSpace.sm),
        const InfoCallout(
          child: Text(
            'Wolevo delivers to Ghana and Nigeria today. More countries are on the way.',
          ),
        ),
      ],
    );
  }
}

class _CityStep extends ConsumerWidget {
  const _CityStep({
    required this.controller,
    required this.selected,
    required this.onSelected,
  });

  final TextEditingController controller;
  final GeocodedPlace? selected;
  final ValueChanged<GeocodedPlace> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(citySearchProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        AppTextField(
          label: 'Search City',
          required: true,
          controller: controller,
          hint: 'e.g., Accra, Tema, Kumasi',
          helper: 'Search for your city',
          onChanged: (value) =>
              ref.read(citySearchProvider.notifier).setQuery(value),
        ),
        const SizedBox(height: AppSpace.lg),
        if (search.loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
            child: AppLoader(),
          )
        else if (search.errorMessage != null)
          FieldError(search.errorMessage!)
        else
          for (final place in search.results) ...[
            AppCard(
              onTap: () => onSelected(place),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.lg,
                vertical: AppSpace.md,
              ),
              color: selected?.city == place.city
                  ? AppColors.secondary2
                  : AppColors.background,
              borderColor: selected?.city == place.city
                  ? AppColors.secondary3
                  : AppColors.surface4,
              child: Row(
                children: [
                  Text(place.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Text(
                      '${place.city}, ${place.region}, ${place.countryName}',
                      style: AppText.body14,
                    ),
                  ),
                  if (selected?.city == place.city)
                    const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
          ],
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  const _DetailsStep({
    required this.place,
    required this.street,
    required this.apartment,
    required this.label,
    required this.landmark,
    required this.isPrimary,
    required this.onPrimaryChanged,
  });

  final GeocodedPlace place;
  final TextEditingController street;
  final TextEditingController apartment;
  final TextEditingController label;
  final TextEditingController landmark;
  final bool isPrimary;
  final ValueChanged<bool> onPrimaryChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.xl,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        AppCard(
          color: AppColors.surface6,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          child: Row(
            children: [
              Text(place.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  '${place.city}, ${place.region}, ${place.countryName}',
                  style: AppText.body14Medium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        AppTextField(
          label: 'Street Address (recommended)',
          controller: street,
          hint: 'e.g., 123 Independence Avenue, Osu',
          helper: 'Street address, building name, or landmark',
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          label: 'Apartment, Suite, Unit (optional)',
          controller: apartment,
          hint: 'e.g., Apt 4B, Near Oxford Street',
          helper: 'Additional location details',
        ),
        const SizedBox(height: AppSpace.lg),
        AppTextField(
          label: 'Label (optional)',
          controller: label,
          hint: 'e.g., Home, Office, Warehouse',
          helper: 'Help you identify this address later',
        ),
        const SizedBox(height: AppSpace.lg),
        const InfoCallout(
          leading: '📍',
          child: Text(
            'Recommended: Adding a street address helps ensure accurate delivery.',
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        // A genuine Ghana/Nigeria addressing accommodation, not filler — many
        // destinations are found by landmark rather than by street number.
        AppTextField(
          label: 'Nearest Landmark',
          controller: landmark,
          hint: 'e.g., Near Omanye Lodge',
          helper: 'Helps our delivery partner find you quickly',
        ),
        const SizedBox(height: AppSpace.lg),
        InkWell(
          onTap: () => onPrimaryChanged(!isPrimary),
          child: Row(
            children: [
              Checkbox(
                value: isPrimary,
                onChanged: (v) => onPrimaryChanged(v ?? false),
              ),
              const SizedBox(width: AppSpace.sm),
              Text('Set as primary address', style: AppText.body14),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.gutter),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surface4)),
      ),
      child: PrimaryButton(
        label: label,
        loading: loading,
        trailingIcon: Icons.arrow_forward,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
