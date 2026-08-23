import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wolevo/features/calculator/presentation/widgets/calculator_panel.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../landing_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/hero_headline.dart';
import '../widgets/retailer_marquee.dart';

/// The logged-out entry point. `/` and `/welcome` render this same page on the
/// web app — `/welcome` is an SEO alias, not a separate onboarding screen.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // The web nav links are in-page anchors (`/#how-it-works`, …); on mobile they
  // scroll the page to the matching section.
  final _howItWorksKey = GlobalKey();
  final _calculatorKey = GlobalKey();
  final _countriesKey = GlobalKey();
  final _appKey = GlobalKey();

  Future<void> _jumpTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  Future<void> _pickRegion() async {
    final picked = await showAppSheet<SiteRegion>(
      context: context,
      builder: (_) => _RegionSheet(current: ref.read(siteRegionProvider)),
    );
    if (picked == null) return;
    ref.read(siteRegionProvider.notifier).state = picked;
  }

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(siteRegionProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleSpacing: AppSpace.gutter,
        title: const WolevoWordmark(fontSize: 24),
        actions: [
          InkWell(
            onTap: _pickRegion,
            borderRadius: AppRadius.rPill,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.rPill,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(region.flag, style: const TextStyle(fontSize: 16)),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.neutral1,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            icon: const Icon(Icons.menu, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      endDrawer: _LandingDrawer(
        onHowItWorks: () => _jumpTo(_howItWorksKey),
        onCalculator: () => _jumpTo(_calculatorKey),
        onCountries: () => _jumpTo(_countriesKey),
        onGetTheApp: () => _jumpTo(_appKey),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.gutter,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpace.lg),
                    _Hero(region: region),
                    const SizedBox(height: AppSpace.section),
                    const RetailerMarquee(),
                    const SizedBox(height: AppSpace.section),
                    const _StatsStrip(),
                    const SizedBox(height: AppSpace.sectionLarge),
                    _HowItWorks(key: _howItWorksKey),
                    const SizedBox(height: AppSpace.sectionLarge),
                    _CalculatorSection(key: _calculatorKey),
                    const SizedBox(height: AppSpace.sectionLarge),
                    _DeliverTo(key: _countriesKey, region: region),
                    const SizedBox(height: AppSpace.sectionLarge),
                    _AppSection(key: _appKey),
                    const SizedBox(height: AppSpace.sectionLarge),
                    const _ClosingCta(),
                    const SizedBox(height: AppSpace.sectionLarge),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends ConsumerWidget {
  const _Hero({required this.region});

  final SiteRegion region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = region.destination;
    final pillText = destination == null
        ? 'NOW DELIVERING ACROSS AFRICA'
        : 'NOW DELIVERING ACROSS ${destination.name.toUpperCase()}';

    // The hero says "Ghana" / "Cedis" when a country is selected; Global gets a
    // neutral variant.
    final subhead = destination == null
        ? 'Shop from top U.S. stores or ship your packages home. Pay in your own currency via Mobile Money (MoMo), Card, or Bank Transfer—no U.S. card required. Whether you\'re an individual or a business, Wolevo helps you save on U.S. sales tax and shipping. Delivered in 7-14 days.'
        : 'Shop from top U.S. stores or ship your packages to ${destination.name}. Pay in ${_currencyWord(destination)} via Mobile Money (MoMo), Card, or Bank Transfer—no U.S. card required. Whether you\'re an individual or a business, Wolevo helps you save on U.S. sales tax and shipping. Delivered in 7-14 days.';
    // The live hero says 7-12 days while the register page and the core-promise
    // block both say 7-14. Using 7-14 here, per the brief — flagged in
    // discovery-notes.md § 1 as a site copy inconsistency.

    final mode = ref.watch(landingModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: AppRadius.rPill,
          ),
          child: Text(
            '${region.flag} $pillText',
            style: AppText.micro.copyWith(color: AppColors.secondary),
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const HeroHeadline(),
        const SizedBox(height: AppSpace.xl),
        Text(
          subhead,
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        const SizedBox(height: AppSpace.xl),
        _ShopShipToggle(
          mode: mode,
          onChanged: (m) => ref.read(landingModeProvider.notifier).state = m,
        ),
        const SizedBox(height: AppSpace.lg),
        // The landing search bar is a lead-gen device — browsing requires an
        // account, so tapping it pushes straight into the auth wall.
        InkWell(
          onTap: () => context.go(AppRoutes.register),
          borderRadius: AppRadius.rPill,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            decoration: BoxDecoration(
              color: AppColors.surface6,
              borderRadius: AppRadius.rPill,
              border: Border.all(color: AppColors.surface4),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 20, color: AppColors.neutral1),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    mode == LandingMode.shop
                        ? 'Search any US store…'
                        : 'Paste a tracking number…',
                    style: AppText.body14.copyWith(color: AppColors.neutral2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        PrimaryButton(
          label: 'Start Shopping',
          trailingIcon: Icons.arrow_forward,
          pill: true,
          onPressed: () => context.go(AppRoutes.register),
        ),
      ],
    );
  }

  static String _currencyWord(DestinationCountry c) => switch (c) {
    DestinationCountry.ghana => 'Cedis',
    DestinationCountry.nigeria => 'Naira',
  };
}

class _ShopShipToggle extends StatelessWidget {
  const _ShopShipToggle({required this.mode, required this.onChanged});

  final LandingMode mode;
  final ValueChanged<LandingMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        children: [
          for (final m in LandingMode.values)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(m),
                borderRadius: AppRadius.rPill,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: m == mode ? AppColors.tertiary : Colors.transparent,
                    borderRadius: AppRadius.rPill,
                  ),
                  child: Text(
                    m == LandingMode.shop ? 'Shop' : 'Ship',
                    style: AppText.body14Semibold.copyWith(
                      color: m == mode
                          ? AppColors.secondary
                          : AppColors.neutral1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats
// ---------------------------------------------------------------------------

class _Stat {
  const _Stat(this.value, this.suffix, this.caption);

  final String value;
  final String suffix;
  final String caption;
}

const _stats = <_Stat>[
  _Stat('0', '%', 'US sales tax (we ship from a tax-free state)'),
  _Stat('6', '+', 'US stores you can shop from today'),
  _Stat('2', '+', 'African countries we deliver to'),
  _Stat('25', '%', 'Average savings vs traditional agents'),
];

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    // 2x2 on a phone; the web renders all four in one row.
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpace.md,
      mainAxisSpacing: AppSpace.md,
      childAspectRatio: 1.25,
      children: [
        for (final stat in _stats)
          AppCard(
            color: AppColors.surface6,
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppText.h2.copyWith(color: AppColors.secondary),
                    children: [
                      TextSpan(text: stat.value),
                      TextSpan(
                        text: stat.suffix,
                        style: AppText.h2.copyWith(color: AppColors.primary3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Flexible(
                  child: Text(
                    stat.caption,
                    style: AppText.caption.copyWith(color: AppColors.neutral1),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// How it works
// ---------------------------------------------------------------------------

class _Step {
  const _Step(this.number, this.title, this.body);

  final String number;
  final String title;
  final String body;
}

const _shopSteps = <_Step>[
  _Step(
    '01',
    'Find Your Product',
    'Search any US store or paste a product link. We show the full landed cost up front.',
  ),
  _Step(
    '02',
    'Pay for the Item',
    'Pay in your own currency with Mobile Money, card or bank transfer — no US card needed.',
  ),
  _Step(
    '03',
    'We Handle Everything',
    'We buy it, receive it at our tax-free Delaware warehouse and ship it out.',
  ),
  _Step(
    '04',
    'You Receive',
    'Delivery or pickup near you, typically 7-14 days after we receive your items.',
  ),
];

// ASSUMPTION: only the "Shop on Wolevo" step titles were captured in discovery.
// The "Ship for Me" step bodies below are written to match the observed
// `/ship` flow (tracking number + receipt upload, then warehouse receipt).
const _shipSteps = <_Step>[
  _Step(
    '01',
    'Get Your US Address',
    'Sign up and we assign you a locker ID at our Delaware warehouse instantly.',
  ),
  _Step(
    '02',
    'Shop Anywhere',
    'Buy from any US store and ship to your locker address — use your exact locker name.',
  ),
  _Step(
    '03',
    'Register Your Shipment',
    'Add the tracking number and upload your receipt so we can match the parcel to you.',
  ),
  _Step(
    '04',
    'You Receive',
    'We consolidate, ship and deliver to you — or hold it for pickup.',
  ),
];

class _HowItWorks extends ConsumerWidget {
  const _HowItWorks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(howItWorksTabProvider);
    final steps = tab == LandingMode.shop ? _shopSteps : _shipSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'How it works',
          title: 'Two ways to get what you love.',
        ),
        const SizedBox(height: AppSpace.xl),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.rPill,
          ),
          child: Row(
            children: [
              for (final m in LandingMode.values)
                Expanded(
                  child: InkWell(
                    onTap: () =>
                        ref.read(howItWorksTabProvider.notifier).state = m,
                    borderRadius: AppRadius.rPill,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: m == tab
                            ? AppColors.background
                            : Colors.transparent,
                        borderRadius: AppRadius.rPill,
                        border: Border.all(
                          color: m == tab
                              ? AppColors.surface4
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        m == LandingMode.shop
                            ? 'Shop on Wolevo'
                            : 'Ship for Me',
                        style: AppText.body14Semibold.copyWith(
                          color: m == tab
                              ? AppColors.secondary
                              : AppColors.neutral1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        for (final step in steps) ...[
          _StepRow(step: step),
          const SizedBox(height: AppSpace.lg),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
          child: Text(
            step.number,
            style: AppText.body14Semibold.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.title, style: AppText.cardTitleMedium),
              const SizedBox(height: 2),
              Text(
                step.body,
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

class _CalculatorSection extends StatelessWidget {
  const _CalculatorSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SectionHeader(
          eyebrow: 'Shipping calculator',
          title: 'Know the cost before you buy.',
        ),
        SizedBox(height: AppSpace.xl),
        // Fully usable logged out — the estimate endpoint lives under `public/`.
        CalculatorPanel(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// We deliver to
// ---------------------------------------------------------------------------

const _ghanaCities = ['Accra', 'Kumasi', 'Tamale', 'Takoradi', 'Cape Coast'];

class _DeliverTo extends StatelessWidget {
  const _DeliverTo({super.key, required this.region});

  final SiteRegion region;

  @override
  Widget build(BuildContext context) {
    final name = region.destination?.name ?? 'Africa';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(eyebrow: 'We deliver to', title: 'From US to $name.'),
        const SizedBox(height: AppSpace.xl),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final city in _ghanaCities) _CityChip(label: city),
            const _CityChip(label: '+ all other regions', muted: true),
          ],
        ),
      ],
    );
  }
}

class _CityChip extends StatelessWidget {
  const _CityChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: muted ? AppColors.surface6 : AppColors.secondary2,
        borderRadius: AppRadius.rPill,
        border: Border.all(
          color: muted ? AppColors.surface4 : AppColors.secondary2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!muted) ...[
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: AppColors.secondary,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.body14Medium.copyWith(
              color: muted ? AppColors.neutral1 : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Get the app
// ---------------------------------------------------------------------------

const _appBullets = [
  'Shop any US store from one place',
  'See the full landed cost before you pay',
  'Track every parcel end to end',
  'Pay in your own currency',
  'Delivery or pickup, your choice',
];

class _AppSection extends StatelessWidget {
  const _AppSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          eyebrow: 'The Wolevo app',
          title: 'Shop. Ship. Track. Receive.',
        ),
        const SizedBox(height: AppSpace.xl),
        for (final bullet in _appBullets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.primary3,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(bullet, style: AppText.body14)),
              ],
            ),
          ),
        const SizedBox(height: AppSpace.md),
        PrimaryButton(
          label: 'Start Shopping',
          trailingIcon: Icons.arrow_forward,
          onPressed: () => context.go(AppRoutes.register),
        ),
        const SizedBox(height: AppSpace.md),
        SecondaryButton(
          label: 'Ship a Package',
          onPressed: () => context.go(AppRoutes.register),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Closing CTA
// ---------------------------------------------------------------------------

class _ClosingCta extends StatelessWidget {
  const _ClosingCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.xxl),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: AppRadius.rCardLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Access is a right, not a Privilege.',
            style: AppText.h2.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpace.xl),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.register),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.rPill,
                ),
              ),
              child: Text('Start Shopping', style: AppText.bodySemibold),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer + region sheet
// ---------------------------------------------------------------------------

class _LandingDrawer extends StatelessWidget {
  const _LandingDrawer({
    required this.onHowItWorks,
    required this.onCalculator,
    required this.onCountries,
    required this.onGetTheApp,
  });

  final VoidCallback onHowItWorks;
  final VoidCallback onCalculator;
  final VoidCallback onCountries;
  final VoidCallback onGetTheApp;

  @override
  Widget build(BuildContext context) {
    void close(VoidCallback then) {
      Navigator.of(context).pop();
      then();
    }

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Row(
                children: [
                  const Expanded(child: WolevoWordmark(fontSize: 24)),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.neutral1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerLink(
                    label: 'How it works',
                    onTap: () => close(onHowItWorks),
                  ),
                  _DrawerLink(
                    label: 'Calculator',
                    onTap: () => close(onCalculator),
                  ),
                  _DrawerLink(
                    label: 'Countries',
                    onTap: () => close(onCountries),
                  ),
                  _DrawerLink(
                    label: 'Get the App',
                    onTap: () => close(onGetTheApp),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SecondaryButton(
                    label: 'Login',
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: AppSpace.md),
                  PrimaryButton(
                    label: 'Start Shopping',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.register);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(label, style: AppText.bodyMedium),
      trailing: const Icon(
        Icons.arrow_forward,
        size: 16,
        color: AppColors.neutral2,
      ),
    );
  }
}

class _RegionSheet extends StatelessWidget {
  const _RegionSheet({required this.current});

  final SiteRegion current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpace.lg),
          const SheetHeader(
            title: 'Choose your country',
            subtitle: 'This sets pricing, currency and delivery locations.',
          ),
          for (final region in SiteRegion.values)
            ListTile(
              onTap: () => Navigator.of(context).pop(region),
              leading: Text(region.flag, style: const TextStyle(fontSize: 22)),
              title: Text(region.label, style: AppText.body14Medium),
              trailing: region == current
                  ? const Icon(
                      Icons.check,
                      size: 18,
                      color: AppColors.secondary,
                    )
                  : null,
            ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}
