import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// What kind of event produced a notification. The live inbox was empty during
/// discovery, so the taxonomy below is derived from the site's own description
/// of what it notifies about: "Order updates and your final bill", "Order,
/// payment, and shipment notifications are always sent and cannot be turned
/// off", plus the opt-in promotional stream.
enum NotificationKind {
  order('ORDER', Icons.receipt_long_outlined, AppColors.secondary2),
  shipment('SHIPMENT', Icons.local_shipping_outlined, AppColors.primary2),
  payment('PAYMENT', Icons.payments_outlined, AppColors.tertiary2),
  promo('PROMO', Icons.local_offer_outlined, AppColors.tertiary),
  system('SYSTEM', Icons.info_outline, AppColors.surface3);

  const NotificationKind(this.apiValue, this.icon, this.tint);

  final String apiValue;
  final IconData icon;
  final Color tint;

  static NotificationKind fromApi(String value) => values.firstWhere(
        (k) => k.apiValue == value.toUpperCase(),
        orElse: () => NotificationKind.system,
      );
}

/// A row from `GET /api/v1/user/notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.kind,
    this.deepLink,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final NotificationKind kind;

  /// Where tapping the row should land, e.g. `/orders/ful_1`.
  /// ASSUMPTION: the live payload was never seen, so this field is inferred
  /// from the fact that every notification concerns a specific order or
  /// shipment.
  final String? deepLink;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: createdAt,
        read: read ?? this.read,
        kind: kind,
        deepLink: deepLink,
      );

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        read: json['read'] as bool? ?? false,
        kind: NotificationKind.fromApi(json['kind'] as String? ?? 'SYSTEM'),
        deepLink: json['deepLink'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'kind': kind.apiValue,
        'deepLink': deepLink,
      };
}
