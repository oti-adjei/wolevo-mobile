import 'package:flutter/material.dart';

/// Design tokens lifted verbatim from the Wolevo web app's Tailwind `@theme`
/// block (see discovery-notes.md § "Design Language"). Do not approximate these
/// values — they are the source of truth for both platforms.
abstract final class AppColors {
  // Greens — the brand core.
  static const primary = Color(0xFF01FF69);
  static const primary2 = Color(0xFFCCFFE1);
  static const primary3 = Color(0xFF00993F);

  static const secondary = Color(0xFF0A3307);
  static const secondary2 = Color(0xFFDDFADB);
  static const secondary3 = Color(0xFF125A0C);
  static const secondary5 = Color(0xFF1A1A1A);
  static const secondary6 = Color(0xFFF7FEF6);
  static const secondary7 = Color(0xFFD5F9D2);

  // Lime — the second signature accent.
  static const tertiary = Color(0xFFDFFF7C);
  static const tertiary2 = Color(0xFFF3FFCC);
  static const tertiary3 = Color(0xFFF9FFE5);
  static const tertiary4 = Color(0xFFF9FFE5);

  static const success = Color(0xFF2EB67D);
  static const success2 = Color(0xFF1F7A54);

  static const error = Color(0xFFE63946);
  static const error2 = Color(0xFF88111A);
  static const error3 = Color(0xFFFEF6F7);

  static const neutral = Color(0xFF1F2933);
  static const neutral1 = Color(0xFF666666);
  static const neutral2 = Color(0xFF999999);

  static const surface = Color(0xFFF2F2F2);
  static const surface3 = Color(0xFFEBEBEB);
  static const surface4 = Color(0xFFE6E6E6);
  static const surface5 = Color(0xFFB3B3B3);
  static const surface6 = Color(0xFFFAFAFA);

  static const inputBorder = Color(0xFFD1D5DB);
  static const background = Color(0xFFFFFFFF);
  static const bodyText = Color(0xFF171717);
}
