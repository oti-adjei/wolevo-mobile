import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';

/// A dialling country for the phone picker.
class PhoneCountry {
  const PhoneCountry(this.isoCode, this.name, this.flag, this.dialCode);

  final String isoCode;
  final String name;
  final String flag;

  /// Includes the leading `+`.
  final String dialCode;
}

/// Ghana and Nigeria lead the list because they are the two destinations; the
/// rest are the common origin/diaspora markets. The live site shows the full
/// ISO country list — this is a pragmatic subset.
// ASSUMPTION: the web picker's full country list was not captured, so this
// ~22-entry list stands in for it.
const kPhoneCountries = <PhoneCountry>[
  PhoneCountry('GH', 'Ghana', '🇬🇭', '+233'),
  PhoneCountry('NG', 'Nigeria', '🇳🇬', '+234'),
  PhoneCountry('US', 'United States', '🇺🇸', '+1'),
  PhoneCountry('CA', 'Canada', '🇨🇦', '+1'),
  PhoneCountry('GB', 'United Kingdom', '🇬🇧', '+44'),
  PhoneCountry('IE', 'Ireland', '🇮🇪', '+353'),
  PhoneCountry('DE', 'Germany', '🇩🇪', '+49'),
  PhoneCountry('FR', 'France', '🇫🇷', '+33'),
  PhoneCountry('IT', 'Italy', '🇮🇹', '+39'),
  PhoneCountry('ES', 'Spain', '🇪🇸', '+34'),
  PhoneCountry('NL', 'Netherlands', '🇳🇱', '+31'),
  PhoneCountry('BE', 'Belgium', '🇧🇪', '+32'),
  PhoneCountry('CH', 'Switzerland', '🇨🇭', '+41'),
  PhoneCountry('SE', 'Sweden', '🇸🇪', '+46'),
  PhoneCountry('NO', 'Norway', '🇳🇴', '+47'),
  PhoneCountry('ZA', 'South Africa', '🇿🇦', '+27'),
  PhoneCountry('KE', 'Kenya', '🇰🇪', '+254'),
  PhoneCountry('TZ', 'Tanzania', '🇹🇿', '+255'),
  PhoneCountry('UG', 'Uganda', '🇺🇬', '+256'),
  PhoneCountry('CI', "Côte d'Ivoire", '🇨🇮', '+225'),
  PhoneCountry('TG', 'Togo', '🇹🇬', '+228'),
  PhoneCountry('BJ', 'Benin', '🇧🇯', '+229'),
  PhoneCountry('AE', 'United Arab Emirates', '🇦🇪', '+971'),
  PhoneCountry('AU', 'Australia', '🇦🇺', '+61'),
  PhoneCountry('IN', 'India', '🇮🇳', '+91'),
  PhoneCountry('CN', 'China', '🇨🇳', '+86'),
];

PhoneCountry _countryForDestination(DestinationCountry destination) {
  return kPhoneCountries.firstWhere(
    (c) => c.isoCode == destination.code,
    orElse: () => kPhoneCountries.first,
  );
}

/// Phone input: a country-code button that opens a searchable bottom sheet,
/// plus a national-number field. [onChanged] receives the composed E.164 value
/// (`+233240000000`) — the compact form the register endpoint expects.
class PhoneField extends StatefulWidget {
  const PhoneField({
    super.key,
    required this.onChanged,
    this.label = 'Phone Number',
    this.required = true,
    this.errorText,
    this.initialDestination = DestinationCountry.ghana,
    this.initialValue,
    this.onCountryChanged,
    this.textInputAction,
    this.enabled = true,
  });

  final ValueChanged<String> onChanged;
  final String label;
  final bool required;
  final String? errorText;
  final DestinationCountry initialDestination;

  /// An existing number in E.164 form (`+233240000000`). The dial code selects
  /// the country and the remainder prefills the national part, so screens like
  /// the cart's delivery step can show the user's saved number.
  final String? initialValue;

  final ValueChanged<PhoneCountry>? onCountryChanged;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late PhoneCountry _country = _countryForDestination(
    widget.initialDestination,
  );
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial == null || initial.isEmpty) return;

    // Longest dial code first, so +233 wins over a shorter prefix.
    final matches =
        kPhoneCountries.where((c) => initial.startsWith(c.dialCode)).toList()
          ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    if (matches.isNotEmpty) {
      _country = matches.first;
      _controller.text = initial.substring(_country.dialCode.length);
    } else {
      _controller.text = initial.replaceAll(RegExp(r'\D'), '');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _national => _controller.text.replaceAll(RegExp(r'\D'), '');

  void _emit() => widget.onChanged(
    _national.isEmpty ? '' : '${_country.dialCode}$_national',
  );

  Future<void> _pickCountry() async {
    final picked = await showAppSheet<PhoneCountry>(
      context: context,
      builder: (_) => const _CountrySheet(),
    );
    if (picked == null || !mounted) return;
    setState(() => _country = picked);
    widget.onCountryChanged?.call(picked);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(widget.label, required: widget.required),
        const SizedBox(height: AppSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CountryButton(
              country: _country,
              onTap: widget.enabled ? _pickCountry : null,
              hasError: widget.errorText != null,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                keyboardType: TextInputType.phone,
                textInputAction: widget.textInputAction,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                style: AppText.body,
                onChanged: (_) => _emit(),
                decoration: const InputDecoration(hintText: '24 000 0000'),
              ),
            ),
          ],
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: 6),
          FieldError(widget.errorText!),
        ],
      ],
    );
  }
}

class _CountryButton extends StatelessWidget {
  const _CountryButton({
    required this.country,
    required this.onTap,
    required this.hasError,
  });

  final PhoneCountry country;
  final VoidCallback? onTap;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.rInput,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        decoration: BoxDecoration(
          borderRadius: AppRadius.rInput,
          border: Border.all(
            color: hasError ? AppColors.error : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(country.dialCode, style: AppText.body14Medium),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: AppColors.neutral1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable country list. Replaces the web app's dropdown, per the mobile
/// rule that every select becomes a bottom sheet.
class _CountrySheet extends StatefulWidget {
  const _CountrySheet();

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = kPhoneCountries.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.dialCode.contains(q) ||
          c.isoCode.toLowerCase() == q;
    }).toList();

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: AppSpace.lg),
            const SheetHeader(title: 'Select country'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
              child: TextField(
                autofocus: false,
                style: AppText.body,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search country…',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.neutral1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpace.xl),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final c = results[i];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(c),
                    leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                    title: Text(c.name, style: AppText.body14Medium),
                    trailing: Text(
                      c.dialCode,
                      style: AppText.body14.copyWith(color: AppColors.neutral1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
