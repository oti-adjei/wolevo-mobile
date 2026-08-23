import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/destination_country.dart';

/// The landing page's country switcher (🌍 Global / 🇬🇭 Ghana / 🇳🇬 Nigeria).
/// It drives the hero pill, the headline copy and the delivery-locations list,
/// and is one of the two inputs the site uses to infer a new account's
/// destination country (discovery-notes.md § "Auth & Onboarding", item 5).
///
// ASSUMPTION: the web app pre-selects a region from geo/IP. There is no
// geolocation dependency in this app, so Ghana is the default — it is the
// larger of the two markets and the one the discovery session observed.
final siteRegionProvider = StateProvider<SiteRegion>((ref) => SiteRegion.ghana);

/// The Shop | Ship toggle in the hero.
enum LandingMode { shop, ship }

final landingModeProvider = StateProvider<LandingMode>(
  (ref) => LandingMode.shop,
);

/// The "How it works" tab selection — mirrors [LandingMode] but is independent
/// of the hero toggle on the live site.
final howItWorksTabProvider = StateProvider<LandingMode>(
  (ref) => LandingMode.shop,
);
