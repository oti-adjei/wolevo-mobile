import 'package:intl/intl.dart';

import 'destination_country.dart';

/// Every amount the API returns carries BOTH a USD figure and a
/// destination-currency figure. The client never converts — the server owns the
/// FX rate (see discovery-notes.md § "Anything else notable", item 3).
class Money {
  const Money({
    required this.usd,
    required this.localAmount,
    required this.localCurrency,
  });

  /// Amount in US dollars.
  final double usd;

  /// The same amount, already converted server-side.
  final double localAmount;

  /// ISO-4217 code of the local amount: `GHS` or `NGN`.
  final String localCurrency;

  factory Money.fromJson(Map<String, dynamic> json) => Money(
    usd: (json['usd'] as num).toDouble(),
    localAmount: (json['localAmount'] as num).toDouble(),
    localCurrency: json['localCurrency'] as String,
  );

  Map<String, dynamic> toJson() => {
    'usd': usd,
    'localAmount': localAmount,
    'localCurrency': localCurrency,
  };

  static final _usdFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 2,
  );

  /// `$187.68`
  String get usdLabel => _usdFormat.format(usd);

  /// `₵2,021.54` / `₦…` — symbol comes from the currency code, not from a
  /// client-side lookup of the user's country, so a GHS price stays GHS even if
  /// the profile country changes mid-session.
  String get localLabel {
    final symbol = switch (localCurrency) {
      'GHS' => '₵',
      'NGN' => '₦',
      _ => '$localCurrency ',
    };
    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    ).format(localAmount);
  }

  Money operator *(num factor) => Money(
    usd: usd * factor,
    localAmount: localAmount * factor,
    localCurrency: localCurrency,
  );

  Money operator +(Money other) => Money(
    usd: usd + other.usd,
    localAmount: localAmount + other.localAmount,
    localCurrency: localCurrency,
  );

  /// Convenience for mock data: builds a Money using the fixed demo rate for a
  /// destination. Real responses always arrive with both fields populated.
  factory Money.mock(double usd, DestinationCountry country) => Money(
    usd: usd,
    localAmount: usd * country.mockRate,
    localCurrency: country.currencyCode,
  );

  static Money zero(DestinationCountry country) => Money.mock(0, country);
}
