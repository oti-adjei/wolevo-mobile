import 'package:flutter/widgets.dart';

/// Radius scale observed on the web app: cards 12–16, inputs and small buttons
/// 6–8, pills / avatars / hero CTAs fully rounded.
abstract final class AppRadius {
  static const sm = Radius.circular(6);
  static const input = Radius.circular(8);
  static const card = Radius.circular(12);
  static const cardLarge = Radius.circular(16);
  static const pill = Radius.circular(9999);

  static const rSm = BorderRadius.all(sm);
  static const rInput = BorderRadius.all(input);
  static const rCard = BorderRadius.all(card);
  static const rCardLarge = BorderRadius.all(cardLarge);
  static const rPill = BorderRadius.all(pill);
}

/// 4pt spacing scale. Phone gutter is 16 (the web uses 32 on desktop, 16 on
/// mobile); card padding lands at 20 to match the web's 20–24.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const section = 32.0;
  static const sectionLarge = 48.0;

  /// Horizontal page gutter on a phone.
  static const gutter = 16.0;

  /// Standard inner padding for a card.
  static const cardPadding = 20.0;
}
