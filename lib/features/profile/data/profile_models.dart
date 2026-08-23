/// Models behind `/profile` — saved addresses, the geocoding typeahead and the
/// referral programme (discovery-notes.md § 2.7).
library;

/// A delivery address the user has saved (`GET /api/v1/addresses`).
///
/// The web card renders the address as three lines — street, "City, Region",
/// then the country — which [formatted] reproduces.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.countryCode,
    required this.city,
    required this.region,
    this.streetAddress,
    this.apartment,
    this.label,
    this.nearestLandmark,
    this.isPrimary = false,
  });

  final String id;

  /// ISO-2, matching the API's `country` / `destinationCountryCode` convention.
  final String countryCode;
  final String city;
  final String region;
  final String? streetAddress;
  final String? apartment;
  final String? label;

  /// A real Ghana/Nigeria addressing accommodation — many destinations have no
  /// usable street number, so the courier navigates by landmark.
  final String? nearestLandmark;

  final bool isPrimary;

  /// Human country name for the third line of [formatted]. Only the two
  /// deliverable countries are named; anything else falls back to the code.
  String get countryName => switch (countryCode.toUpperCase()) {
    'GH' => 'Ghana',
    'NG' => 'Nigeria',
    _ => countryCode.toUpperCase(),
  };

  /// The card's display form, newline separated:
  /// `8 Bia Rd` / `Accra, Greater Accra` / `Ghana`.
  String get formatted => [
    if (streetAddress != null && streetAddress!.trim().isNotEmpty)
      streetAddress!.trim(),
    if (apartment != null && apartment!.trim().isNotEmpty) apartment!.trim(),
    [city, region].where((p) => p.trim().isNotEmpty).join(', '),
    countryName,
  ].join('\n');

  SavedAddress copyWith({
    String? id,
    String? countryCode,
    String? city,
    String? region,
    String? streetAddress,
    String? apartment,
    String? label,
    String? nearestLandmark,
    bool? isPrimary,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      city: city ?? this.city,
      region: region ?? this.region,
      streetAddress: streetAddress ?? this.streetAddress,
      apartment: apartment ?? this.apartment,
      label: label ?? this.label,
      nearestLandmark: nearestLandmark ?? this.nearestLandmark,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    countryCode:
        json['countryCode'] as String? ?? json['country'] as String? ?? 'GH',
    city: json['city'] as String? ?? '',
    region: json['region'] as String? ?? json['state'] as String? ?? '',
    streetAddress: json['streetAddress'] as String?,
    apartment: json['apartment'] as String?,
    label: json['label'] as String?,
    nearestLandmark: json['nearestLandmark'] as String?,
    isPrimary: json['isPrimary'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'countryCode': countryCode,
    'city': city,
    'region': region,
    'streetAddress': streetAddress,
    'apartment': apartment,
    'label': label,
    'nearestLandmark': nearestLandmark,
    'isPrimary': isPrimary,
  };
}

/// One typeahead hit from
/// `GET /api/v1/geocoding/search?query=&country=&limit=5`.
class GeocodedPlace {
  const GeocodedPlace({
    required this.city,
    required this.region,
    required this.countryCode,
    required this.countryName,
    required this.flag,
  });

  final String city;
  final String region;
  final String countryCode;
  final String countryName;

  /// Emoji flag — the web results render one ahead of the label.
  final String flag;

  /// `Accra, Greater Accra, Ghana`.
  String get label =>
      [city, region, countryName].where((p) => p.trim().isNotEmpty).join(', ');

  factory GeocodedPlace.fromJson(Map<String, dynamic> json) => GeocodedPlace(
    city: json['city'] as String? ?? '',
    region: json['region'] as String? ?? json['state'] as String? ?? '',
    countryCode: json['countryCode'] as String? ?? '',
    countryName: json['countryName'] as String? ?? '',
    flag: json['flag'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'city': city,
    'region': region,
    'countryCode': countryCode,
    'countryName': countryName,
    'flag': flag,
  };
}

/// `GET /api/v1/user/referrals`.
class ReferralSummary {
  const ReferralSummary({
    required this.code,
    required this.link,
    this.entries = const [],
  });

  final String code;

  /// `https://www.wolevo.com/?ref=<code>` as observed on the web.
  final String link;
  final List<ReferralEntry> entries;

  factory ReferralSummary.fromJson(Map<String, dynamic> json) =>
      ReferralSummary(
        code: json['code'] as String? ?? '',
        link:
            json['link'] as String? ??
            'https://www.wolevo.com/?ref=${json['code'] ?? ''}',
        entries: (json['entries'] as List<dynamic>? ?? const [])
            .map((e) => ReferralEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'code': code,
    'link': link,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}

/// A friend who signed up with the user's code.
// ASSUMPTION: the live account had zero referrals, so the row's field set is
// inferred from the "Friends who signed up with your code" column header.
class ReferralEntry {
  const ReferralEntry({
    required this.name,
    required this.joinedAt,
    this.rewarded = false,
  });

  final String name;
  final DateTime joinedAt;
  final bool rewarded;

  factory ReferralEntry.fromJson(Map<String, dynamic> json) => ReferralEntry(
    name: json['name'] as String? ?? '',
    joinedAt: DateTime.parse(json['joinedAt'] as String),
    rewarded: json['rewarded'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'joinedAt': joinedAt.toIso8601String(),
    'rewarded': rewarded,
  };
}
