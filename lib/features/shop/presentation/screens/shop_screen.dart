import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../data/shop_models.dart';
import '../widgets/category_chip_row.dart';
import '../widgets/sku_entry_row.dart';
import '../widgets/store_selector.dart';
import '../shop_providers.dart';
import '../widgets/paste_link_panel.dart';
import '../widgets/shop_listing_card.dart';
import '../widgets/shop_results_header.dart';
import '../widgets/shop_search_field.dart';

/// `/shop` — browse, search and paste-a-link on one route, exactly like the
/// web app drives them with `?mode=` / `?retailer=` / `?q=`
/// (discovery-notes.md § 2.5).
///
/// The desktop grid is 5-up; a phone gets 2-up, and the header's retailer
/// dropdown becomes a scrolling chip row.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({
    super.key,
    this.initialRetailer,
    this.initialMode,
    this.initialQuery,
  });

  /// Seeded by the router from `?retailer=`, `?mode=` and `?q=`.
  final Retailer? initialRetailer;
  final ShopMode? initialMode;
  final String? initialQuery;

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late final TextEditingController _searchController;
  final _scrollController = ScrollController();
  final _searchFocus = FocusNode();

  /// Where `🔍 Search products` returns to when leaving paste mode.
  ShopMode _modeBeforePaste = ShopMode.browse;
  ShopCategory _category = ShopCategory.all;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialQuery ?? ref.read(shopQueryProvider).keyword,
    );
    _scrollController.addListener(_onScroll);

    // The query params are route state, so they are applied once the first
    // frame has been laid out rather than during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialRetailer == null &&
          widget.initialMode == null &&
          widget.initialQuery == null) {
        return;
      }
      ref
          .read(shopQueryProvider.notifier)
          .hydrate(
            retailer: widget.initialRetailer,
            mode: widget.initialMode,
            query: widget.initialQuery,
          );
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(shopListProvider.notifier).loadMore();
    }
  }

  void _enterPaste() {
    _modeBeforePaste = ref.read(shopQueryProvider).mode;
    ref.read(pasteLinkProvider.notifier).reset();
    ref.read(shopQueryProvider.notifier).setMode(ShopMode.paste);
  }

  void _leavePaste() {
    ref.read(pasteLinkProvider.notifier).reset();
    ref
        .read(shopQueryProvider.notifier)
        .setMode(
          _modeBeforePaste == ShopMode.paste
              ? ShopMode.search
              : _modeBeforePaste,
        );
    if (ref.read(shopQueryProvider).mode == ShopMode.search) {
      _searchFocus.requestFocus();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(shopQueryProvider.notifier).clearKeyword();
    setState(() {});
  }

  void _openListing(ShopListing listing) {
    context.push(
      '${AppRoutes.product}?retailer=${listing.retailer.apiValue}'
      '&productId=${listing.productId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(shopQueryProvider);
    final listState = ref.watch(shopListProvider);
    final isPaste = query.mode == ShopMode.paste;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // Deep green, matching Home and the rest of the app's chrome. The
        // mockup drew this header light, but a green bar is the brand's
        // signature and the client kept it deliberately.
        centerTitle: true,
        title: Text(
          'Shop',
          style: AppText.cardTitle.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Cart',
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push(AppRoutes.cart),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () => ref.read(shopListProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxl)),
              SliverToBoxAdapter(
                child: StoreSelector(
                  selected: query.retailer,
                  onSelected: (retailer) => ref
                      .read(shopQueryProvider.notifier)
                      .setRetailer(retailer),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
              // Search is always on screen now rather than hidden behind a
              // mode toggle — the mockup treats it as the primary control.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.gutter,
                  ),
                  child: ShopSearchField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) =>
                        ref.read(shopQueryProvider.notifier).setKeyword(value),
                    onSubmitted: (value) => ref
                        .read(shopQueryProvider.notifier)
                        .submitKeyword(value),
                    onCleared: () =>
                        ref.read(shopQueryProvider.notifier).clearKeyword(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
              SliverToBoxAdapter(
                child: SkuEntryRow(
                  retailer: query.retailer,
                  onSubmit: (sku) => context.push(
                    '${AppRoutes.product}?retailer=${query.retailer.apiValue}'
                    '&productId=$sku',
                  ),
                  onPasteLink: isPaste ? _leavePaste : _enterPaste,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
              SliverToBoxAdapter(
                child: CategoryChipRow(
                  selected: _category,
                  onSelected: (category) =>
                      setState(() => _category = category),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.md)),
              if (isPaste)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.xl,
                    AppSpace.gutter,
                    AppSpace.section,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: PasteLinkPanel(
                      retailer: query.retailer,
                      onResolved: _openListing,
                    ),
                  ),
                )
              else ...[
                ..._resultSlivers(query, listState),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resultSlivers(
    ShopQuery query,
    AsyncValue<ShopListState> listState,
  ) {
    // Search with an empty box: no request was fired, so prompt instead of
    // rendering a zero-result state.
    if (query.mode == ShopMode.search && !query.hasKeyword) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search,
            title: 'Search US stores',
            message:
                'Type what you are looking for — we search the store you picked above.',
          ),
        ),
      ];
    }

    final loading = listState.isLoading;
    final value = listState.valueOrNull;

    final header = SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xl,
          AppSpace.gutter,
          AppSpace.md,
        ),
        child: query.mode == ShopMode.search
            ? SearchResultsHeader(
                query: query.trimmedKeyword,
                countLabel: value?.countLabel ?? '',
                loading: loading,
                onClear: _clearSearch,
              )
            : BrowseResultsHeader(
                retailerLabel: query.retailer.label,
                countLabel: value?.countLabel ?? '',
                loading: loading,
              ),
      ),
    );

    return switch (listState) {
      AsyncError(:final error) => [
        header,
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorRetry(
            message: '$error',
            onRetry: () => ref.invalidate(shopListProvider),
          ),
        ),
      ],
      AsyncLoading() when value == null => [header, const _GridSkeleton()],
      AsyncData(:final value) when value.isEmpty => [
        header,
        SliverFillRemaining(
          hasScrollBody: false,
          child: query.mode == ShopMode.search
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'No products found',
                  message:
                      'Nothing matched "${query.trimmedKeyword}" at ${query.retailer.label}. '
                      'Try another keyword or a different store.',
                  actionLabel: 'Clear search',
                  onAction: _clearSearch,
                )
              : const EmptyState(
                  icon: Icons.storefront_outlined,
                  title: 'Nothing to show yet',
                  message: 'This store has no featured products right now.',
                ),
        ),
      ],
      _ => [
        header,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            0,
            AppSpace.gutter,
            AppSpace.xxl,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: _gridDelegate,
            itemCount: value?.items.length ?? 0,
            itemBuilder: (context, index) =>
                ShopListingCard(listing: value!.items[index]),
          ),
        ),
        if (value?.loadingMore ?? false)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: AppSpace.section),
              child: AppLoader(),
            ),
          ),
      ],
    };
  }
}

/// 2-up on a phone (the web's 5-up desktop grid). The ratio leaves room for a
/// square thumbnail plus two title lines, the price pair and the local price.
const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: AppSpace.md,
  mainAxisSpacing: AppSpace.md,
  childAspectRatio: 0.60,
);

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.gutter,
        0,
        AppSpace.gutter,
        AppSpace.xxl,
      ),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(_buildSkeleton, childCount: 4),
      ),
    );
  }
}

Widget _buildSkeleton(BuildContext context, int index) =>
    const ShopListingCardSkeleton();
