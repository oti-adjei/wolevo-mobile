import 'app_icon_models.dart';

/// The server-driven half: lets Wolevo switch the icon for a season without
/// shipping an app update.
///
/// ASSUMPTION: no such endpoint exists on the live API. Modelled as
/// `GET /api/v1/app/appearance`, following the conventions of the endpoints
/// that were observed.
abstract interface class AppearanceRepository {
  /// The campaign the server currently advertises, or null for none.
  Future<IconCampaign?> currentCampaign();
}

/// Mock source. Returns a campaign window so the behaviour is demoable; flip
/// [campaign] to null to see the no-campaign path.
class MockAppearanceRepository implements AppearanceRepository {
  MockAppearanceRepository({IconCampaign? campaign})
    : campaign = campaign ?? _festiveSeason;

  final IconCampaign campaign;

  /// A December window, the obvious first use of this.
  static final _festiveSeason = IconCampaign(
    variant: AppIconVariant.festive,
    startsAt: DateTime(DateTime.now().year, 12),
    endsAt: DateTime(DateTime.now().year + 1, 1, 7),
    name: 'Festive season',
  );

  @override
  Future<IconCampaign?> currentCampaign() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return campaign;
  }
}
