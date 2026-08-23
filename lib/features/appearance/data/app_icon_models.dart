import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// The launcher icons the app ships with.
///
/// Each variant is only a pair of brand colours — the mark itself never changes
/// — so a seasonal icon cannot drift off-brand. Adding one means adding a case
/// here plus a line in tool/generate_brand_assets.py, then regenerating the
/// platform files and declaring it natively (Info.plist / activity-alias).
enum AppIconVariant {
  /// The shipped default. On iOS this is the primary icon, so it has no
  /// alternate name; on Android it is MainActivity itself rather than an alias.
  wolevo(
    id: 'default',
    label: 'Wolevo',
    description: 'The default mark',
    background: AppColors.secondary,
    mark: AppColors.primary,
    iosAlternateName: null,
    androidAlias: 'MainActivityAliasDefault',
  ),
  lime(
    id: 'lime',
    label: 'Lime',
    description: 'Inverted lockup',
    background: AppColors.primary,
    mark: AppColors.secondary,
    iosAlternateName: 'lime',
    androidAlias: 'MainActivityAliasLime',
  ),
  midnight(
    id: 'midnight',
    label: 'Midnight',
    description: 'Near-black field',
    background: Color(0xFF0D110C),
    mark: AppColors.primary,
    iosAlternateName: 'midnight',
    androidAlias: 'MainActivityAliasMidnight',
  ),
  festive(
    id: 'festive',
    label: 'Festive',
    description: 'Seasonal lime mark',
    background: AppColors.secondary,
    mark: AppColors.tertiary,
    iosAlternateName: 'festive',
    androidAlias: 'MainActivityAliasFestive',
  );

  const AppIconVariant({
    required this.id,
    required this.label,
    required this.description,
    required this.background,
    required this.mark,
    required this.iosAlternateName,
    required this.androidAlias,
  });

  final String id;
  final String label;
  final String description;

  /// Used to draw the in-app preview from the same vector as the real icon, so
  /// the swatch in Settings always matches what lands on the home screen.
  final Color background;
  final Color mark;

  /// Null for the primary icon, which iOS restores by passing null.
  final String? iosAlternateName;

  /// Android has no "primary icon" to fall back to — the plugin only toggles
  /// activity-aliases — so the default is an alias as well.
  final String? androidAlias;

  static AppIconVariant fromId(String? id) =>
      values.firstWhere((v) => v.id == id, orElse: () => AppIconVariant.wolevo);
}

/// A server-driven icon campaign — the "change it without shipping an update"
/// half of this feature.
///
/// The app cannot install *new* artwork remotely (both stores require icons to
/// be in the binary), so a campaign selects one of the variants already shipped.
/// That is the meaningful limit to plan around: ship the season's icon in the
/// binary ahead of time, then switch it on by date from the server.
///
/// ASSUMPTION: no such endpoint exists on the live API. Modelled as
/// `GET /api/v1/app/appearance` to match the existing conventions.
class IconCampaign {
  const IconCampaign({
    required this.variant,
    required this.startsAt,
    required this.endsAt,
    this.name,
    this.force = false,
  });

  final AppIconVariant variant;
  final DateTime startsAt;
  final DateTime endsAt;

  /// Shown in Settings so the user knows why their icon changed.
  final String? name;

  /// When true the campaign overrides a manual choice. Off by default: a user
  /// who deliberately picked an icon should not have it silently replaced.
  final bool force;

  bool isActiveAt(DateTime now) =>
      now.isAfter(startsAt) && now.isBefore(endsAt);

  factory IconCampaign.fromJson(Map<String, dynamic> json) => IconCampaign(
    variant: AppIconVariant.fromId(json['variant'] as String?),
    startsAt: DateTime.parse(json['startsAt'] as String),
    endsAt: DateTime.parse(json['endsAt'] as String),
    name: json['name'] as String?,
    force: json['force'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'variant': variant.id,
    'startsAt': startsAt.toIso8601String(),
    'endsAt': endsAt.toIso8601String(),
    'name': name,
    'force': force,
  };
}
