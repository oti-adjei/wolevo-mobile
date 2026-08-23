import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics.dart';

import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/mock_shop_repository.dart';
import '../data/shop_models.dart';
import '../data/shop_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final shopRepositoryProvider = Provider<ShopRepository>(
  (ref) => const MockShopRepository(),
);

/// The destination drives every price in the grid and the `Ship to Ghana`
/// framing, so the feed rebuilds whenever the user's country changes.
final shopDestinationProvider = Provider<DestinationCountry>(
  (ref) => ref.watch(currentUserProvider).destinationCountry,
);

/// Everything `/shop` carries in its URL: `?mode=`, `?retailer=`, `?q=`.
class ShopQuery {
  const ShopQuery({
    this.mode = ShopMode.browse,
    this.retailer = Retailer.amazon,
    this.keyword = '',
  });

  final ShopMode mode;
  final Retailer retailer;
  final String keyword;

  String get trimmedKeyword => keyword.trim();

  bool get hasKeyword => trimmedKeyword.isNotEmpty;

  ShopQuery copyWith({ShopMode? mode, Retailer? retailer, String? keyword}) => ShopQuery(
        mode: mode ?? this.mode,
        retailer: retailer ?? this.retailer,
        keyword: keyword ?? this.keyword,
      );

  @override
  bool operator ==(Object other) =>
      other is ShopQuery &&
      other.mode == mode &&
      other.retailer == retailer &&
      other.trimmedKeyword == trimmedKeyword;

  @override
  int get hashCode => Object.hash(mode, retailer, trimmedKeyword);
}

/// Owns the mode / retailer / keyword triple. The keyword is debounced here
/// rather than in the widget so a rebuild cannot restart the timer.
class ShopQueryController extends Notifier<ShopQuery> {
  Timer? _debounce;

  // ASSUMPTION: 350ms is the brief's number; the web app searches on submit
  // rather than as-you-type, so no debounce was observable.
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  ShopQuery build() {
    ref.onDispose(() => _debounce?.cancel());
    return const ShopQuery();
  }

  /// Seeds from the route's query params on first frame.
  void hydrate({Retailer? retailer, ShopMode? mode, String? query}) {
    _debounce?.cancel();
    state = ShopQuery(
      mode: mode ?? (query != null && query.trim().isNotEmpty ? ShopMode.search : state.mode),
      retailer: retailer ?? state.retailer,
      keyword: query ?? state.keyword,
    );
  }

  void setMode(ShopMode mode) {
    if (mode == state.mode) return;
    _debounce?.cancel();
    state = state.copyWith(mode: mode);
  }

  void setRetailer(Retailer retailer) {
    if (retailer == state.retailer) return;
    _debounce?.cancel();
    state = state.copyWith(retailer: retailer);
  }

  /// Called on every keystroke — publishes once the user pauses.
  void setKeyword(String keyword) {
    _debounce?.cancel();
    if (keyword.trim().isEmpty) {
      state = state.copyWith(keyword: keyword);
      return;
    }
    _debounce = Timer(
      _debounceDuration,
      () => state = state.copyWith(keyword: keyword),
    );
  }

  /// Bypasses the debounce — wired to the keyboard's search action.
  void submitKeyword(String keyword) {
    _debounce?.cancel();
    state = state.copyWith(keyword: keyword);

    // On submit only. Firing per keystroke would bury the real searches under
    // every prefix the user typed on the way there.
    if (keyword.trim().isNotEmpty) {
      ref.read(analyticsProvider).track(
        AnalyticsEvents.productSearched,
        properties: {
          'query': keyword.trim(),
          'retailer': state.retailer.apiValue,
        },
      );
    }
  }

  /// The `× Clear` control beside the results heading.
  void clearKeyword() {
    _debounce?.cancel();
    state = state.copyWith(keyword: '');
  }
}

final shopQueryProvider =
    NotifierProvider<ShopQueryController, ShopQuery>(ShopQueryController.new);

/// Accumulated pages plus the flags the grid needs to drive infinite scroll.
class ShopListState {
  const ShopListState({
    required this.items,
    required this.hasMore,
    required this.pageNumber,
    required this.totalCount,
    this.loadingMore = false,
  });

  static const idle = ShopListState(
    items: [],
    hasMore: false,
    pageNumber: 1,
    totalCount: 0,
  );

  final List<ShopListing> items;
  final bool hasMore;
  final int pageNumber;

  /// Drives the `141 items` label beside the heading.
  final int totalCount;

  final bool loadingMore;

  bool get isEmpty => items.isEmpty;

  /// `141 items` / `1 item`.
  String get countLabel => '$totalCount ${totalCount == 1 ? 'item' : 'items'}';

  ShopListState copyWith({
    List<ShopListing>? items,
    bool? hasMore,
    int? pageNumber,
    int? totalCount,
    bool? loadingMore,
  }) {
    return ShopListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      pageNumber: pageNumber ?? this.pageNumber,
      totalCount: totalCount ?? this.totalCount,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Owns the paged grid. Rebuilds from scratch whenever the query changes (the
/// web app re-requests with a new `?retailer=` / `?q=`) and appends as the user
/// scrolls.
class ShopListController extends AsyncNotifier<ShopListState> {
  static const _pageSize = 20;

  ShopRepository get _repo => ref.read(shopRepositoryProvider);

  @override
  Future<ShopListState> build() {
    final query = ref.watch(shopQueryProvider);
    final country = ref.watch(shopDestinationProvider);
    return _load(query, country, const Pagination(pageSize: _pageSize));
  }

  Future<ShopListState> _load(
    ShopQuery query,
    DestinationCountry country,
    Pagination pagination,
  ) async {
    // Paste mode has no grid, and search with an empty box shows nothing —
    // neither state should fire a request.
    if (query.mode == ShopMode.paste) return ShopListState.idle;
    if (query.mode == ShopMode.search && !query.hasKeyword) return ShopListState.idle;

    final page = query.mode == ShopMode.search
        ? await _repo.search(
            keyword: query.trimmedKeyword,
            retailer: query.retailer,
            country: country,
            pagination: pagination,
          )
        : await _repo.browse(
            retailer: query.retailer,
            country: country,
            pagination: pagination,
          );

    return ShopListState(
      items: page.items,
      hasMore: page.hasMore,
      pageNumber: page.pageNumber,
      totalCount: shopTotalCount(page),
    );
  }

  /// Pull-to-refresh. Keeps the current grid on screen while the reload runs.
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _load(
        ref.read(shopQueryProvider),
        ref.read(shopDestinationProvider),
        const Pagination(pageSize: _pageSize),
      ),
    );
  }

  /// Appends the next page. No-ops while one is in flight or when the server
  /// said there is nothing left.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    try {
      final next = await _load(
        ref.read(shopQueryProvider),
        ref.read(shopDestinationProvider),
        Pagination(pageNumber: current.pageNumber + 1, pageSize: _pageSize),
      );
      state = AsyncValue.data(
        next.copyWith(items: [...current.items, ...next.items]),
      );
    } catch (_) {
      // A failed append must not blow away the pages already on screen.
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final shopListProvider =
    AsyncNotifierProvider<ShopListController, ShopListState>(ShopListController.new);

/// The paste-a-link panel's own state machine: idle → submitting → resolved,
/// with the failure surfaced inline under the field rather than as a toast.
class PasteLinkState {
  const PasteLinkState({this.submitting = false, this.errorMessage, this.resolved});

  final bool submitting;
  final String? errorMessage;
  final ShopListing? resolved;
}

class PasteLinkController extends Notifier<PasteLinkState> {
  @override
  PasteLinkState build() => const PasteLinkState();

  void reset() => state = const PasteLinkState();

  /// Returns the resolved listing so the screen can push the product route,
  /// or null when the URL was rejected.
  Future<ShopListing?> submit(String url) async {
    state = const PasteLinkState(submitting: true);
    try {
      final listing = await ref.read(shopRepositoryProvider).parseLink(
            url: url,
            country: ref.read(shopDestinationProvider),
          );
      state = PasteLinkState(resolved: listing);
      return listing;
    } on ShopLinkException catch (e) {
      state = PasteLinkState(errorMessage: e.message);
      return null;
    } catch (e) {
      state = PasteLinkState(errorMessage: '$e');
      return null;
    }
  }
}

final pasteLinkProvider =
    NotifierProvider<PasteLinkController, PasteLinkState>(PasteLinkController.new);
