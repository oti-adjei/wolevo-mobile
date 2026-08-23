import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/destination_country.dart';
import '../../../../core/models/retailer.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/wolevo_mark.dart';
import '../../../calculator/presentation/widgets/calculator_panel.dart';

/// The public entry point — a compact, task-first version of the landing page.
///
/// The full marketing scroll still exists at [AppRoutes.welcome]; this screen is
/// what "Explore first" and returning logged-out users get instead, because the
/// three things a visitor actually wants to do (look for a product, understand
/// the locker, price a shipment) are otherwise buried several screens down a
/// desktop-shaped page.
///
/// Shop and Ship both lead into the auth wall, but the intended destination is
/// carried through as `?next=`, so signing in drops the user exactly where they
/// were headed rather than on Home.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  DestinationCountry _country = DestinationCountry.ghana;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showAppSheet<DestinationCountry>(
      context: context,
      builder: (_) => const _CountrySheet(),
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: _Hero(country: _country, onPickCountry: _pickCountry),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeader(controller: _tabs),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _ShopTab(country: _country),
            _ShipTab(country: _country),
            const _CalculatorTab(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.country, required this.onPickCountry});

  final DestinationCountry country;
  final VoidCallback onPickCountry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.secondary,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const WolevoMark(width: 30),
                const SizedBox(width: AppSpace.sm),
                Text(
                  'wolevo',
                  style: AppText.cardTitleMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                const Spacer(),
                _CountryPill(country: country, onTap: onPickCountry),
                const SizedBox(width: AppSpace.xs),
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  style: TextButton.styleFrom(foregroundColor: AppColors.tertiary),
                  child: Text('Login', style: AppText.body14Semibold),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              'Shop global.',
              style: AppText.h2.copyWith(color: Colors.white),
            ),
            // Wrap rather than Row: at 26px display type "Receive it at home."
            // does not fit one line on a 390px phone, and the highlight block
            // must be able to fall to the next line.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  'Receive it at ',
                  style: AppText.h2.copyWith(color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  color: AppColors.primary,
                  child: Text(
                    'home.',
                    style: AppText.h2.copyWith(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'Shop top U.S. stores or ship your own packages to '
              '${country.name}. Pay in ${country.currencyCode} — no U.S. card '
              'required.',
              style: AppText.body14.copyWith(color: AppColors.secondary7),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryPill extends StatelessWidget {
  const _CountryPill({required this.country, required this.onTap});

  final DestinationCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountrySheet extends StatelessWidget {
  const _CountrySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            title: 'Where are you shipping to?',
            subtitle: 'Prices and delivery options follow your country.',
          ),
          for (final country in DestinationCountry.values)
            ListTile(
              leading: Text(country.flag, style: const TextStyle(fontSize: 22)),
              title: Text(country.name, style: AppText.body),
              subtitle: Text(
                'Pay in ${country.currencyCode}',
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
              onTap: () => Navigator.of(context).pop(country),
            ),
          const SizedBox(height: AppSpace.lg),
        ],
      ),
    );
  }
}

/// The Shop | Ship | Calculator switcher, pinned under the hero. Styled as the
/// site's lime active pill rather than Material's underline indicator.
class _TabBarHeader extends SliverPersistentHeaderDelegate {
  const _TabBarHeader({required this.controller});

  final TabController controller;

  /// Tab height (44) plus the padding above and below. Must agree with the
  /// child's real height or the sliver protocol asserts.
  static const _height = 64.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // A full-width white band under the green hero read as a hard seam. The
    // switcher is a floating pill on the page background instead, so the hero
    // and the content below it stay visually separate without a slab between.
    return Container(
      height: _height,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.sm,
        AppSpace.gutter,
        AppSpace.sm,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: AppRadius.rPill,
          border: Border.all(color: AppColors.surface4),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          indicator: const BoxDecoration(
            color: AppColors.tertiary,
            borderRadius: AppRadius.rPill,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.neutral1,
          labelStyle: AppText.body14Semibold,
          unselectedLabelStyle: AppText.body14,
          splashBorderRadius: AppRadius.rPill,
          padding: EdgeInsets.zero,
          tabs: const [
            Tab(height: 40, text: 'Shop'),
            Tab(height: 40, text: 'Ship'),
            Tab(height: 40, text: 'Calculator'),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarHeader oldDelegate) =>
      oldDelegate.controller != controller;
}

class _ShopTab extends StatefulWidget {
  const _ShopTab({required this.country});

  final DestinationCountry country;

  @override
  State<_ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<_ShopTab> {
  final _query = TextEditingController();
  Retailer _retailer = Retailer.amazon;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Shopping is behind the auth wall, but the search the visitor typed is not
  /// thrown away — it rides through the redirect as `?next=` and runs once they
  /// are signed in.
  void _search() {
    final q = _query.text.trim();
    final destination = q.isEmpty
        ? '${AppRoutes.shop}?retailer=${_retailer.apiValue}'
        : '${AppRoutes.shop}?mode=search&retailer=${_retailer.apiValue}'
            '&q=${Uri.encodeComponent(q)}';
    context.push(AppRoutes.loginWithNext(destination));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EyebrowLabel('Search US stores'),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
                decoration: const InputDecoration(
                  hintText: 'Search for what you need',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: Retailer.values.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
                  itemBuilder: (context, i) {
                    final r = Retailer.values[i];
                    final selected = r == _retailer;
                    return _Chip(
                      label: r.label,
                      selected: selected,
                      onTap: () => setState(() => _retailer = r),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Search',
                icon: Icons.search,
                onPressed: _search,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const _PointList(
          points: [
            'Browse 6 US retailers, or paste any product link',
            'We buy it, pack it and ship it to your door',
            'Pay by Mobile Money, card or bank transfer',
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        _MoreLink(country: widget.country),
      ],
    );
  }
}

class _ShipTab extends StatelessWidget {
  const _ShipTab({required this.country});

  final DestinationCountry country;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconChip(icon: Icons.location_on_outlined),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your US warehouse address', style: AppText.cardTitleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Assigned the moment you sign up',
                          style: AppText.caption.copyWith(color: AppColors.neutral1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                "It's a real Delaware address — tax-free. Use it at any US "
                'checkout, or share it with family in the States. Register the '
                'tracking number and we deliver to your door in ${country.name}.',
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Get your US address',
                trailingIcon: Icons.arrow_forward,
                onPressed: () => context.push(
                  AppRoutes.loginWithNext(AppRoutes.ship),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        const _PointList(
          points: [
            'USPS, UPS, FedEx — any carrier works',
            'We receive, weigh and quote before you pay',
            'Delivery or pickup, whichever suits you',
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        _MoreLink(country: country),
      ],
    );
  }
}

/// The calculator is genuinely public — its endpoint sits under `/public/` — so
/// a visitor can price a shipment without an account. That makes it the one tab
/// here that does real work rather than routing to the auth wall.
class _CalculatorTab extends StatelessWidget {
  const _CalculatorTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: const [CalculatorPanel()],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.secondary2 : AppColors.background,
      borderRadius: AppRadius.rPill,
      child: InkWell(
        borderRadius: AppRadius.rPill,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.rPill,
            border: Border.all(
              color: selected ? AppColors.secondary3 : AppColors.surface4,
            ),
          ),
          child: Text(
            label,
            style: AppText.body14Medium.copyWith(
              color: selected ? AppColors.secondary : AppColors.bodyText,
            ),
          ),
        ),
      ),
    );
  }
}

class _PointList extends StatelessWidget {
  const _PointList({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final point in points) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.check_circle, size: 18, color: AppColors.secondary3),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(child: Text(point, style: AppText.body14)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
        ],
      ],
    );
  }
}

class _MoreLink extends StatelessWidget {
  const _MoreLink({required this.country});

  final DestinationCountry country;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.tertiary3,
      borderColor: AppColors.tertiary2,
      onTap: () => context.push(AppRoutes.welcome),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('See how Wolevo works', style: AppText.body14Semibold),
                const SizedBox(height: 2),
                Text(
                  'Stories, pricing and delivery across ${country.name}',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.secondary),
        ],
      ),
    );
  }
}
