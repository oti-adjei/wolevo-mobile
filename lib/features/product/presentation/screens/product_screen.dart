import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../cart/presentation/cart_providers.dart';
import '../../data/product_models.dart';
import '../product_providers.dart';
import '../widgets/collapsible_section.dart';
import '../widgets/product_action_bar.dart';
import '../widgets/product_gallery.dart';
import '../widgets/product_price_rail.dart';
import '../widgets/product_spec_table.dart';
import '../widgets/product_trust_row.dart';
import '../widgets/variant_picker.dart';

/// `/product?retailer=AMAZON&productId=<ASIN>` — a retailer's product rendered
/// inside Wolevo with landed-cost framing (discovery-notes.md § 2.6).
///
/// Models `GET /api/v1/shop/products/parse?retailer=&productId=
/// &destinationCountryCode=`.
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({
    super.key,
    required this.productId,
    required this.retailer,
  });

  final String productId;
  final Retailer retailer;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  bool _adding = false;

  /// Populated from the cart the repository returns, so the badge only appears
  /// once the cart's real count is known.
  int? _cartCount;

  ProductArgs get _args =>
      (productId: widget.productId, retailer: widget.retailer);

  Future<void> _share(ProductDetail product) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            '${product.title} — ${product.price.usdLabel} on Wolevo. '
            '${AppRoutes.product}?retailer=${product.retailer.apiValue}'
            '&productId=${product.productId}',
        subject: product.title,
      ),
    );
  }

  Future<void> _addToCart(ProductDetail product) async {
    final quantity = ref.read(productQuantityProvider(_args));
    setState(() => _adding = true);
    try {
      final cart = await ref
          .read(cartRepositoryProvider)
          .addItem(
            productId: product.productId,
            retailer: product.retailer,
            title: product.title,
            unitPrice: product.price,
            quantity: quantity,
            imageUrl: product.images.isEmpty ? null : product.images.first,
            variantSummary: product.variantSummary,
          );
      if (!mounted) return;
      setState(() {
        _adding = false;
        _cartCount = cart.itemCount;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Added to cart · ${product.title}'),
            action: SnackBarAction(
              label: 'View cart',
              onPressed: () => context.push(AppRoutes.cart),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(_args));
    final quantity = ref.watch(productQuantityProvider(_args));
    final product = detail.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          _RetailerBadge(retailer: widget.retailer),
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: product == null ? null : () => _share(product),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: switch (detail) {
        AsyncError(:final error) => ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(productDetailProvider(_args)),
        ),
        AsyncData(:final value) => _ProductBody(
          product: value,
          onVariantSelected: (groupName, optionId) => ref
              .read(productDetailProvider(_args).notifier)
              .selectVariant(groupName: groupName, optionId: optionId),
        ),
        _ => const AppLoader(),
      },
      bottomNavigationBar: product == null
          ? null
          : ProductActionBar(
              quantity: quantity,
              priceLabel: (product.price * quantity).usdLabel,
              adding: _adding,
              enabled: product.inStock,
              cartCount: _cartCount,
              onIncrement: () =>
                  ref.read(productQuantityProvider(_args).notifier).increment(),
              onDecrement: () =>
                  ref.read(productQuantityProvider(_args).notifier).decrement(),
              onAddToCart: () => _addToCart(product),
              onOpenCart: () => context.push(AppRoutes.cart),
            ),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product, required this.onVariantSelected});

  final ProductDetail product;

  /// `(groupName, optionId)`.
  final void Function(String, String) onVariantSelected;

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
          padding: const EdgeInsets.all(AppSpace.md),
          child: ProductGallery(
            productId: product.productId,
            retailer: product.retailer,
            images: product.images,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        Text(product.title, style: AppText.cardTitle),
        const SizedBox(height: AppSpace.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.cardPadding,
            vertical: AppSpace.xs,
          ),
          child: SpecTable(
            rows: {
              'Seller': product.seller,
              'Brand': product.brand,
              'Condition': product.condition,
              'Product ID': product.productId,
            },
          ),
        ),
        if (product.variantGroups.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, group) in product.variantGroups.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpace.xl),
                  VariantPicker(
                    group: group,
                    onSelected: (optionId) =>
                        onVariantSelected(group.name, optionId),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xl),
        AppCard(child: ProductPriceRail(product: product)),
        const SizedBox(height: AppSpace.xl),
        AppCard(child: const ProductTrustRow()),
        if (product.highlights.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xl),
          CollapsibleSection(
            title: 'Product Highlights',
            initiallyExpanded: true,
            child: BulletList(items: product.highlights),
          ),
        ],
        if (product.dimensions.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          CollapsibleSection(
            title: 'Dimensions & Weight',
            child: SpecTable(rows: product.dimensions),
          ),
        ],
      ],
    );
  }
}

/// `Amazon` — the retailer chip the site floats top-right of the gallery. On a
/// phone it lives in the app bar, beside the share button.
class _RetailerBadge extends StatelessWidget {
  const _RetailerBadge({required this.retailer});

  final Retailer retailer;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.md,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary2,
          borderRadius: AppRadius.rPill,
        ),
        child: Text(
          retailer.label,
          style: AppText.captionSemibold.copyWith(color: AppColors.secondary),
        ),
      ),
    );
  }
}
