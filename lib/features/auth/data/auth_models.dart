import '../../../core/models/destination_country.dart';

/// The signed-in user. Mirrors what `POST /auth/restore` returns: profile
/// fields, the assigned locker, and the shared US warehouse address.
class WolevoUser {
  const WolevoUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailVerified,
    required this.phoneNumber,
    required this.destinationCountry,
    required this.lockerId,
    required this.accountType,
    required this.referralCode,
    this.dateOfBirth,
    this.promotionalEmails = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool emailVerified;

  /// E.164, e.g. `+233240000000`.
  final String phoneNumber;

  /// Never asked at signup — inferred from the phone country code and the
  /// site's country switcher.
  final DestinationCountry destinationCountry;

  /// The one per-user discriminator on an otherwise shared warehouse address.
  final String lockerId;

  final AccountType accountType;
  final String referralCode;
  final DateTime? dateOfBirth;
  final bool promotionalEmails;

  String get fullName => '$firstName $lastName';
  String get initials => (firstName.isEmpty ? '?' : firstName[0]).toUpperCase();

  /// The name a US retailer must be given so the warehouse can match the parcel.
  String get lockerName => 'Wolevo $lockerId';

  WolevoUser copyWith({
    String? firstName,
    String? lastName,
    bool? emailVerified,
    String? phoneNumber,
    DestinationCountry? destinationCountry,
    DateTime? dateOfBirth,
    bool? promotionalEmails,
  }) {
    return WolevoUser(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      lockerId: lockerId,
      accountType: accountType,
      referralCode: referralCode,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      promotionalEmails: promotionalEmails ?? this.promotionalEmails,
    );
  }

  factory WolevoUser.fromJson(Map<String, dynamic> json) => WolevoUser(
    id: json['id'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    email: json['email'] as String,
    emailVerified: json['emailVerified'] as bool? ?? false,
    phoneNumber: json['phoneNumber'] as String,
    destinationCountry: DestinationCountry.fromCode(
      json['destinationCountryCode'] as String? ?? 'GH',
    ),
    lockerId: json['lockerId'] as String,
    accountType: AccountType.fromApi(
      json['accountType'] as String? ?? 'PERSONAL',
    ),
    referralCode: json['referralCode'] as String? ?? '',
    dateOfBirth: json['dateOfBirth'] == null
        ? null
        : DateTime.parse(json['dateOfBirth'] as String),
    promotionalEmails: json['promotionalEmails'] as bool? ?? false,
  );
}

/// The profile screen shows `Personal`; a `/business-shipping` route exists on
/// the site, so a business tier is assumed to exist too.
enum AccountType {
  personal('PERSONAL', 'Personal'),
  business('BUSINESS', 'Business');

  const AccountType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static AccountType fromApi(String v) => values.firstWhere(
    (t) => t.apiValue == v.toUpperCase(),
    orElse: () => personal,
  );
}

/// The US warehouse address. Street, PMB and phone are shared across all users —
/// only [WolevoUser.lockerId] identifies the recipient, which is why the site
/// carries such loud warnings about the name and the PMB line.
class WarehouseAddress {
  const WarehouseAddress({
    required this.name,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.stateCode,
    required this.stateName,
    required this.zipCode,
    required this.countryCode,
    required this.phone,
  });

  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String stateCode;
  final String stateName;
  final String zipCode;
  final String countryCode;
  final String phone;

  /// The retailer-facing first name is always the literal "Wolevo"; the last
  /// name is the locker ID.
  String get retailerFirstName => 'Wolevo';
  String get retailerLastName => name.replaceFirst('Wolevo ', '');

  factory WarehouseAddress.fromJson(Map<String, dynamic> json) =>
      WarehouseAddress(
        name: json['name'] as String,
        addressLine1: json['addressLine1'] as String,
        addressLine2: json['addressLine2'] as String,
        city: json['city'] as String,
        stateCode: json['stateCode'] as String,
        stateName: json['stateName'] as String,
        zipCode: json['zipCode'] as String,
        countryCode: json['countryCode'] as String,
        phone: json['phone'] as String,
      );

  /// One-block form, for the "copy the whole address" action.
  String get asBlock => [
    name,
    addressLine1,
    addressLine2,
    '$city, $stateCode $zipCode',
    countryCode,
    phone,
  ].join('\n');
}

/// `POST /api/v1/auth/register`
class RegisterRequest {
  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.confirmPassword,
    this.referralCode,
  });

  final String firstName;
  final String lastName;
  final String email;

  /// E.164 — the web app formats the field as `+233 24 000 0000` but submits
  /// the compact form.
  final String phoneNumber;
  final String password;
  final String confirmPassword;
  final String? referralCode;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'phoneNumber': phoneNumber,
    'password': password,
    'confirmPassword': confirmPassword,
    if (referralCode != null && referralCode!.isNotEmpty)
      'referralCode': referralCode,
  };
}

/// `POST /api/v1/auth/login`
class LoginRequest {
  const LoginRequest({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

/// What a successful login / register hands back.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.warehouseAddress,
    required this.accessToken,
    this.refreshToken,
  });

  final WolevoUser user;
  final WarehouseAddress warehouseAddress;
  final String accessToken;
  final String? refreshToken;

  AuthSession copyWith({WolevoUser? user}) => AuthSession(
    user: user ?? this.user,
    warehouseAddress: warehouseAddress,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
