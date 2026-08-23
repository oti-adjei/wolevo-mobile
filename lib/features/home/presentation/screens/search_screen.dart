import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../home_providers.dart';
import '../widgets/product_card.dart';

/// `/search` — the mobile replacement for the web header's inline search bar
/// (`GET /shop/search?keyword=&retailer=&page=`). Full screen, autofocused,
/// with the retailer scope moved from a dropdown to a chip strip.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Seed from the controller so backing out and returning keeps the query.
    _controller = TextEditingController(
      text: ref.read(searchControllerProvider).query,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    ref.read(searchControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface6,
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: AppText.body.copyWith(color: Colors.white),
          cursorColor: AppColors.primary,
          onChanged: notifier.setQuery,
          onSubmitted: (_) => notifier.submit(),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            hintText: 'Search ${state.retailer.label}',
            hintStyle: AppText.body.copyWith(color: Colors.white70),
            suffixIcon: state.hasQuery
                ? IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                    onPressed: _clear,
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RetailerScopeStrip(
            selected: state.retailer,
            onSelected: notifier.setRetailer,
          ),
          const Divider(height: 1, color: AppColors.surface4),
          Expanded(child: _Body(state: state, onClear: _clear)),
        ],
      ),
    );
  }
}

/// Horizontally scrolling scope chips, one per retailer. Selected state is the
/// site's mint fill + darker green border.
class _RetailerScopeStrip extends StatelessWidget {
  const _RetailerScopeStrip({required this.selected, required this.onSelected});

  final Retailer selected;
  final ValueChanged<Retailer> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: Retailer.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, index) {
          final retailer = Retailer.values[index];
          final isSelected = retailer == selected;
          return Center(
            child: Material(
              color: isSelected ? AppColors.secondary2 : AppColors.background,
              borderRadius: AppRadius.rPill,
              child: InkWell(
                borderRadius: AppRadius.rPill,
                onTap: () => onSelected(retailer),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.rPill,
                    border: Border.all(
                      color: isSelected ? AppColors.secondary3 : AppColors.surface4,
                    ),
                  ),
                  child: Text(
                    retailer.label,
                    style: AppText.body14Semibold.copyWith(
                      color: isSelected ? AppColors.secondary : AppColors.neutral1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.onClear});

  final SearchState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!state.hasQuery) return const _SearchIntro();

    return switch (state.status) {
      SearchStatus.loading => const AppLoader(label: 'Searching…'),
      SearchStatus.error => ErrorRetry(message: state.errorMessage ?? 'Search failed.'),
      SearchStatus.idle => const _SearchIntro(),
      SearchStatus.loaded => state.results.isEmpty
          ? EmptyState(
              icon: Icons.search_off,
              title: 'No matching products',
              message: 'Nothing on ${state.retailer.label} matched '
                  '"${state.query.trim()}". Try a different term or store.',
            )
          : _Results(state: state, onClear: onClear),
    };
  }
}

/// Empty state before anything has been typed.
class _SearchIntro extends StatelessWidget {
  const _SearchIntro();

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search,
      title: 'Search for what you need',
      message: 'We search ${Retailer.values.map((r) => r.label).join(' · ')} — '
          'pick a store above, then type what you are looking for.',
    );
  }
}

/// Result grid, headed by the web app's `"query" × Clear   20 items` line.
class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onClear});

  final SearchState state;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            AppSpace.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '"${state.query.trim()}"',
                    style: AppText.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                InkWell(
                  onTap: onClear,
                  borderRadius: AppRadius.rSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, size: 14, color: AppColors.neutral1),
                        const SizedBox(width: 2),
                        Text(
                          'Clear',
                          style: AppText.body14.copyWith(color: AppColors.neutral1),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${state.results.length} '
                  '${state.results.length == 1 ? 'item' : 'items'}',
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            0,
            AppSpace.gutter,
            AppSpace.section,
          ),
          // Two-up matches the web app's sub-500px product grid.
          sliver: SliverGrid.builder(
            itemCount: state.results.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpace.md,
              crossAxisSpacing: AppSpace.md,
              // Square thumb + two title lines + two price lines.
              childAspectRatio: 0.60,
            ),
            itemBuilder: (context, index) => ProductCard(product: state.results[index]),
          ),
        ),
      ],
    );
  }
}
