import 'package:flutter/widgets.dart';

import 'analytics.dart';

/// Reports screen views from one place.
///
/// The alternative — every screen firing its own `screen()` in `initState` — is
/// how screen tracking rots: someone adds a route and forgets, and the gap is
/// invisible until a funnel looks wrong weeks later. Routing already knows what
/// is on top, so it does the reporting.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  AnalyticsNavigatorObserver(this._analytics);

  final AnalyticsClient _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _report(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Popping reveals whatever was underneath, which is now the current screen.
    if (previousRoute != null) _report(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _report(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _report(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;

    // Path only. Query strings carry search terms, product ids and — on the
    // auth routes — the `next` destination, none of which belong in a screen
    // name where they would fragment the report into thousands of rows.
    final path = Uri.tryParse(name)?.path ?? name;
    _analytics.screen(path);
  }
}
