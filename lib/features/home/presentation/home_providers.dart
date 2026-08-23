import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/destination_country.dart';
import '../../../core/models/pagination.dart';
import '../../../core/models/retailer.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../orders/data/order_models.dart';
import '../../orders/presentation/orders_providers.dart';
import '../data/home_models.dart';
import '../data/home_repository.dart';
import '../data/mock_home_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => const MockHomeRepository(),
);

/// The destination drives every price in the feed, so the feed is rebuilt
/// whenever the user's country changes (the web app's nav country switcher).
final destinationCountryProvider = Provider<DestinationCountry>(
  (ref) => ref.watch(currentUserProvider).destinationCountry,
);

/// `GET /shop/homepage-deals`. Keyed off the destination country: watching it
/// inside [build] means a country switch re-fetches automatically.
class HomeFeedController extends AsyncNotifier<HomeFeed> {
  @override
  Future<HomeFeed> build() {
    final country = ref.watch(destinationCountryProvider);
    return ref.read(homeRepositoryProvider).fetchFeed(country);
  }

  /// Pull-to-refresh. Keeps the previous feed on screen while re-fetching so
  /// the list does not collapse to a spinner under the user's finger.
  Future<void> refresh() async {
    final country = ref.read(destinationCountryProvider);
    state = await AsyncValue.guard(
      () => ref.read(homeRepositoryProvider).fetchFeed(country),
    );
  }
}

final homeFeedProvider =
    AsyncNotifierProvider<HomeFeedController, HomeFeed>(HomeFeedController.new);

/// Everything the search screen renders, in one immutable value.
class SearchState {
  const SearchState({
    this.query = '',
    this.retailer = Retailer.amazon,
    this.results = const [],
    this.status = SearchStatus.idle,
    this.errorMessage,
  });

  final String query;
  final Retailer retailer;
  final List<DealProduct> results;
  final SearchStatus status;
  final String? errorMessage;

  bool get hasQuery => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    Retailer? retailer,
    List<DealProduct>? results,
    SearchStatus? status,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      retailer: retailer ?? this.retailer,
      results: results ?? this.results,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

enum SearchStatus { idle, loading, loaded, error }

/// Debounced controller behind `GET /shop/search?keyword=&retailer=&page=`.
///
/// The mobile brief replaces the web header's inline search bar with a
/// dedicated screen, so the query lives here rather than in the URL.
class SearchController extends Notifier<SearchState> {
  Timer? _debounce;

  /// Guards against a slow response for an abandoned query overwriting a newer
  /// one — only the most recent request is allowed to publish results.
  int _requestId = 0;

  // ASSUMPTION: 350ms is the brief's number; no debounce was observable on the
  // web app, which searches on submit rather than as-you-type.
  static const _debounceDuration = Duration(milliseconds: 350);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _requestId++;
      state = state.copyWith(results: const [], status: SearchStatus.idle);
      return;
    }
    _debounce = Timer(_debounceDuration, _run);
  }

  void setRetailer(Retailer retailer) {
    if (retailer == state.retailer) return;
    state = state.copyWith(retailer: retailer);
    if (!state.hasQuery) return;
    _debounce?.cancel();
    state = state.copyWith(status: SearchStatus.loading);
    _run();
  }

  void clear() {
    _debounce?.cancel();
    _requestId++;
    state = SearchState(retailer: state.retailer);
  }

  /// Bypasses the debounce — wired to the keyboard's search action.
  void submit() {
    if (!state.hasQuery) return;
    _debounce?.cancel();
    _run();
  }

  Future<void> _run() async {
    final id = ++_requestId;
    final query = state.query;
    final retailer = state.retailer;
    state = state.copyWith(status: SearchStatus.loading);
    try {
      final results = await ref.read(homeRepositoryProvider).search(
            query: query,
            retailer: retailer,
            country: ref.read(destinationCountryProvider),
            pagination: const Pagination(),
          );
      if (id != _requestId) return;
      state = state.copyWith(results: results, status: SearchStatus.loaded);
    } catch (e) {
      if (id != _requestId) return;
      state = state.copyWith(
        status: SearchStatus.error,
        results: const [],
        errorMessage: e.toString(),
      );
    }
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);

/// Unread notification count for the app-bar bell
/// (`GET /user/notifications/unread-count`).
// ASSUMPTION: the messages feature owns this endpoint in a later phase; Home
// only needs the number, so it reads a placeholder until that lands.
final unreadNotificationsProvider = Provider<int>((ref) => 0);

/// How many parcels are in flight, for the Home hero card.
///
/// Cross-feature read: Home has no orders data of its own, so it goes through
/// the orders feature's published repository interface rather than reaching
/// into its widgets or notifiers.
class ActiveShipmentsSummary {
  const ActiveShipmentsSummary({
    required this.total,
    required this.inTransit,
    required this.arrived,
  });

  final int total;
  final int inTransit;
  final int arrived;

  /// "2 in transit · 1 arrived"
  String get caption {
    if (total == 0) return 'Nothing in flight right now';
    final parts = <String>[
      if (inTransit > 0) '$inTransit in transit',
      if (arrived > 0) '$arrived arrived',
    ];
    return parts.isEmpty ? '$total active' : parts.join(' · ');
  }
}

final activeShipmentsProvider =
    FutureProvider<ActiveShipmentsSummary>((ref) async {
  final repo = ref.watch(ordersRepositoryProvider);
  final page = await repo.list(pagination: const Pagination(pageSize: 50));

  // "Active" means anything the warehouse still owes the user: delivered and
  // cancelled fulfillments have left the pipeline.
  final active = page.items.where(
    (f) => f.status != OrderStatus.delivered && f.status != OrderStatus.cancelled,
  );

  return ActiveShipmentsSummary(
    total: active.length,
    inTransit: active.where((f) => f.status == OrderStatus.shipped).length,
    arrived: active.where((f) => f.status == OrderStatus.purchased).length,
  );
});

/// Cart badge count (`GET /carts/active`).
// ASSUMPTION: the cart feature lands in Phase 2 — hardcoded to 0 until then.
final cartItemCountProvider = Provider<int>((ref) => 0);
