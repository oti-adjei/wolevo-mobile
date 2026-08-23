import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pagination.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/mock_orders_repository.dart';
import '../data/order_models.dart';
import '../data/orders_repository.dart';

/// Swap this single line for a Dio-backed implementation to go live.
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  // Prices arrive pre-converted, so the mock mints amounts in the signed-in
  // user's destination currency. A real client sends the country as a request
  // parameter instead.
  final country = ref.watch(currentUserProvider).destinationCountry;
  return MockOrdersRepository(country: country);
});

/// The two things that narrow the list: the status chip row and the search box.
class OrdersFilter {
  const OrdersFilter({this.status, this.query = ''});

  /// Null is the `All` chip — the request simply omits `status`.
  final OrderStatus? status;

  final String query;

  bool get isActive => status != null || query.trim().isNotEmpty;

  /// Drives the `Clear all filters (n)` count, exactly as the site does: the
  /// status chip and an active search each count as one filter.
  int get activeCount =>
      (status != null ? 1 : 0) + (query.trim().isEmpty ? 0 : 1);

  OrdersFilter copyWith({OrderStatus? status, String? query, bool clearStatus = false}) {
    return OrdersFilter(
      status: clearStatus ? null : (status ?? this.status),
      query: query ?? this.query,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is OrdersFilter && other.status == status && other.query == query;

  @override
  int get hashCode => Object.hash(status, query);
}

class OrdersFilterController extends Notifier<OrdersFilter> {
  @override
  OrdersFilter build() => const OrdersFilter();

  void setStatus(OrderStatus? status) {
    state = status == null
        ? state.copyWith(clearStatus: true)
        : state.copyWith(status: status);
  }

  /// Called from the search field's debounce timer, not on every keystroke.
  void setQuery(String query) => state = state.copyWith(query: query);

  void clear() => state = const OrdersFilter();
}

final ordersFilterProvider =
    NotifierProvider<OrdersFilterController, OrdersFilter>(OrdersFilterController.new);

/// Accumulated pages plus the flags the list needs to drive infinite scroll.
class OrdersListState {
  const OrdersListState({
    required this.items,
    required this.hasMore,
    required this.pageNumber,
    this.loadingMore = false,
  });

  final List<Fulfillment> items;
  final bool hasMore;
  final int pageNumber;
  final bool loadingMore;

  bool get isEmpty => items.isEmpty;

  OrdersListState copyWith({
    List<Fulfillment>? items,
    bool? hasMore,
    int? pageNumber,
    bool? loadingMore,
  }) {
    return OrdersListState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      pageNumber: pageNumber ?? this.pageNumber,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

/// Owns the paged fulfillment list. Rebuilds from scratch whenever the filter
/// changes (the web app re-requests with `?status=…`), and appends pages as the
/// user scrolls.
class OrdersListController extends AsyncNotifier<OrdersListState> {
  static const _pageSize = 20;

  OrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  @override
  Future<OrdersListState> build() async {
    final filter = ref.watch(ordersFilterProvider);
    final page = await _repo.list(
      status: filter.status,
      query: filter.query,
      pagination: const Pagination(pageSize: _pageSize),
    );
    return OrdersListState(
      items: page.items,
      hasMore: page.hasMore,
      pageNumber: page.pageNumber,
    );
  }

  /// Pull-to-refresh. Keeps the current list on screen while the reload runs.
  Future<void> refresh() async {
    final filter = ref.read(ordersFilterProvider);
    final page = await _repo.list(
      status: filter.status,
      query: filter.query,
      pagination: const Pagination(pageSize: _pageSize),
    );
    state = AsyncValue.data(
      OrdersListState(
        items: page.items,
        hasMore: page.hasMore,
        pageNumber: page.pageNumber,
      ),
    );
  }

  /// Appends the next page. No-ops while one is already in flight or when the
  /// server said there is nothing left.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;

    state = AsyncValue.data(current.copyWith(loadingMore: true));
    final filter = ref.read(ordersFilterProvider);
    try {
      final page = await _repo.list(
        status: filter.status,
        query: filter.query,
        pagination: Pagination(
          pageNumber: current.pageNumber + 1,
          pageSize: _pageSize,
        ),
      );
      state = AsyncValue.data(
        OrdersListState(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          pageNumber: page.pageNumber,
        ),
      );
    } catch (_) {
      // A failed page-append must not blow away the pages already on screen.
      state = AsyncValue.data(current.copyWith(loadingMore: false));
    }
  }
}

final ordersListProvider =
    AsyncNotifierProvider<OrdersListController, OrdersListState>(OrdersListController.new);

/// One fulfillment, for the detail screen. Family keyed by the route's `id`.
final orderDetailProvider = FutureProvider.autoDispose
    .family<Fulfillment, String>((ref, id) => ref.watch(ordersRepositoryProvider).byId(id));
