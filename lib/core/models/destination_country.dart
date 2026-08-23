/// Wolevo delivers to two countries today. The API takes ISO-2 codes as
/// `destinationCountryCode` (`GH`, `NG`).
enum DestinationCountry {
  ghana(
    code: 'GH',
    name: 'Ghana',
    flag: '🇬🇭',
    currencyCode: 'GHS',
    dialCode: '+233',
    // Demo-only FX rate. Real amounts always arrive pre-converted from the API.
    mockRate: 12.2,
  ),
  nigeria(
    code: 'NG',
    name: 'Nigeria',
    flag: '🇳🇬',
    currencyCode: 'NGN',
    dialCode: '+234',
    mockRate: 1580.0,
  );

  const DestinationCountry({
    required this.code,
    required this.name,
    required this.flag,
    required this.currencyCode,
    required this.dialCode,
    required this.mockRate,
  });

  final String code;
  final String name;
  final String flag;
  final String currencyCode;
  final String dialCode;
  final double mockRate;

  static DestinationCountry fromCode(String code) => values.firstWhere(
    (c) => c.code == code.toUpperCase(),
    orElse: () => DestinationCountry.ghana,
  );

  /// Maps a dial code back to a destination. Signup never asks for a country —
  /// the web app infers it from the phone country code and the nav switcher
  /// (see discovery-notes.md § "Auth & Onboarding", item 5).
  static DestinationCountry? fromDialCode(String dialCode) {
    for (final c in values) {
      if (c.dialCode == dialCode) return c;
    }
    return null;
  }
}

/// The landing page's country switcher offers a third, non-shipping option.
enum SiteRegion {
  global('Global', '🌍', null),
  ghana('Ghana', '🇬🇭', DestinationCountry.ghana),
  nigeria('Nigeria', '🇳🇬', DestinationCountry.nigeria);

  const SiteRegion(this.label, this.flag, this.destination);

  final String label;
  final String flag;
  final DestinationCountry? destination;
}
