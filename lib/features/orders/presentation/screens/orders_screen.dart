import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../orders_providers.dart';
import '../widgets/fulfillment_card.dart';
import '../widgets/order_status_filter_bar.dart';
import '../widgets/orders_search_field.dart';

/// `/orders` — the unified list of proxy-buy orders and forwarded shipments.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(ordersListProvider.notifier).loadMore();
    }
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(ordersFilterProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(ordersFilterProvider);
    final listState = ref.watch(ordersListProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('My Orders')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () => ref.read(ordersListProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.gutter,
                    AppSpace.lg,
                    AppSpace.gutter,
                    AppSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track all your orders in one place',
                        style: AppText.body14.copyWith(color: AppColors.neutral1),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      // Desktop floated these top-right; on a phone they read
                      // better as a full-width pair under the header.
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Shop',
                              size: AppButtonSize.compact,
                              onPressed: () => context.go(AppRoutes.shop),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Create Shipment',
                              size: AppButtonSize.compact,
                              onPressed: () => context.go(AppRoutes.ship),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      OrdersSearchField(
                        controller: _searchController,
                        onChanged: (value) =>
                            ref.read(ordersFilterProvider.notifier).setQuery(value),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: OrderStatusFilterBar(
                  selected: filter.status,
                  onSelected: (status) =>
                      ref.read(ordersFilterProvider.notifier).setStatus(status),
                ),
              ),
              if (filter.isActive)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.gutter,
                      AppSpace.md,
                      AppSpace.gutter,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ClearFiltersButton(
                        count: filter.activeCount,
                        onPressed: _clearFilters,
                      ),
                    ),
                  ),
                ),
              ...switch (listState) {
                AsyncError(:final error) => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ErrorRetry(
                        message: '$error',
                        onRetry: () => ref.invalidate(ordersListProvider),
                      ),
                    ),
                  ],
                AsyncData(:final value) when value.isEmpty => [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: filter.isActive
                          ? EmptyState(
                              icon: Icons.filter_alt_off_outlined,
                              title: 'No matching orders',
                              message: 'Try adjusting your search or filters.',
                              actionLabel: 'Clear Filters',
                              onAction: _clearFilters,
                            )
                          : EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No orders yet',
                              message: 'Your orders and shipments will appear here.',
                              actionLabel: 'Start Shopping',
                              onAction: () => context.go(AppRoutes.shop),
                            ),
                    ),
                  ],
                AsyncData(:final value) => [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.gutter,
                        AppSpace.lg,
                        AppSpace.gutter,
                        AppSpace.xxl,
                      ),
                      sliver: SliverList.separated(
                        itemCount: value.items.length + (value.loadingMore ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                        itemBuilder: (context, index) {
                          if (index >= value.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpace.xl),
                              child: AppLoader(),
                            );
                          }
                          final item = value.items[index];
                          return FulfillmentCard(
                            fulfillment: item,
                            onTap: () => context.push(AppRoutes.orderDetail(item.id)),
                          );
                        },
                      ),
                    ),
                  ],
                _ => const [
                    SliverFillRemaining(hasScrollBody: false, child: AppLoader()),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
