import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/logging/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_icon_models.dart';

/// Applies and remembers the launcher icon.
abstract interface class AppIconRepository {
  /// False on platforms that cannot swap icons, so the UI can explain itself
  /// rather than offering a control that silently does nothing.
  Future<bool> isSupported();

  /// The variant the user explicitly chose, or null if they never have.
  Future<AppIconVariant?> manualChoice();

  /// Whether the user lets Wolevo apply seasonal icons.
  Future<bool> followsCampaigns();

  Future<void> setFollowsCampaigns(bool value);

  /// Applies [variant] and records it as a manual choice.
  Future<void> apply(AppIconVariant variant);

  /// Applies a campaign without recording it as a manual choice, so the user's
  /// own preference survives the season.
  Future<void> applyCampaign(AppIconVariant variant);
}

class PlatformAppIconRepository implements AppIconRepository {
  PlatformAppIconRepository({AppLogger? logger})
    : _logger = logger ?? const NoopLogger();

  final AppLogger _logger;

  static const _manualKey = 'wolevo.appIcon.manual';
  static const _followKey = 'wolevo.appIcon.followCampaigns';

  /// Implemented directly in the app target (AppDelegate.swift /
  /// MainActivity.kt) rather than via a plugin: every dynamic-icon package on
  /// pub is CocoaPods-only, and this project builds with Swift Package Manager.
  static const _channel = MethodChannel('wolevo/app_icon');

  @override
  Future<bool> isSupported() async {
    // Web and desktop have no launcher icon to swap.
    if (kIsWeb) return false;
    if (!Platform.isIOS && !Platform.isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('supportsAlternateIcons') ??
          false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AppIconVariant?> manualChoice() async {
    final prefs = await _prefs();
    final id = prefs?.getString(_manualKey);
    return id == null ? null : AppIconVariant.fromId(id);
  }

  @override
  Future<bool> followsCampaigns() async {
    final prefs = await _prefs();
    // Opt-in by default: seasonal icons are part of the brand experience, and
    // the toggle in Settings lets anyone who dislikes it opt out.
    return prefs?.getBool(_followKey) ?? true;
  }

  @override
  Future<void> setFollowsCampaigns(bool value) async {
    final prefs = await _prefs();
    await prefs?.setBool(_followKey, value);
  }

  @override
  Future<void> apply(AppIconVariant variant) async {
    await _setIcon(variant);
    final prefs = await _prefs();
    await prefs?.setString(_manualKey, variant.id);
  }

  @override
  Future<void> applyCampaign(AppIconVariant variant) => _setIcon(variant);

  Future<void> _setIcon(AppIconVariant variant) async {
    if (!await isSupported()) return;
    try {
      // One name, two meanings: on iOS it is the CFBundleAlternateIcons key
      // (null restores the primary icon), on Android it is the activity-alias
      // to enable.
      final name = Platform.isIOS
          ? variant.iosAlternateName
          : variant.androidAlias;
      await _channel.invokeMethod<void>('setAlternateIcon', {'name': name});
    } catch (e) {
      // A failed icon swap is cosmetic — never let it break the screen the
      // user is standing on.
      _logger.warn('Icon switch failed', context: {'error': '$e'});
    }
  }

  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }
}
