import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// One gallery slot.
///
/// The live page loads imagery through a Cloudflare image proxy. Nothing is
/// reachable offline and there are no bundled assets, so an empty or failing
/// URL falls back to a deterministic tinted panel with the retailer's initial
/// centred — the same language the shop grid uses for its thumbnails.
///
// ASSUMPTION: the tint is derived from a hash of the product id so a product
// looks identical on every rebuild; the slot index only shifts the shade, so
// the seven Anker slots are distinguishable while still reading as one set.
class ProductGalleryImage extends StatelessWidget {
  const ProductGalleryImage({
    super.key,
    required this.productId,
    required this.retailer,
    this.imageUrl = '',
    this.index = 0,
    this.radius = AppRadius.rCard,
    this.compact = false,
  });

  final String productId;
  final Retailer retailer;
  final String imageUrl;

  /// Position in the gallery — only used to vary the placeholder shade.
  final int index;

  final BorderRadius radius;

  /// Thumbnail-strip sizing: smaller initial, no wordmark.
  final bool compact;

  static const _tints = <Color>[
    AppColors.secondary2,
    AppColors.tertiary2,
    AppColors.secondary7,
    AppColors.tertiary,
    AppColors.primary2,
    AppColors.surface3,
  ];

  static Color tintFor(String productId, int index) =>
      _tints[(_hash(productId) + index) % _tints.length];

  /// Deterministic, platform-independent hash — `String.hashCode` is not
  /// guaranteed stable across runs.
  static int _hash(String value) {
    var h = 0;
    for (final unit in value.codeUnits) {
      h = (h * 31 + unit) & 0x7fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: tintFor(productId, index),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                retailer.label.substring(0, 1).toUpperCase(),
                style: (compact ? AppText.h3 : AppText.h1).copyWith(
                  color: AppColors.secondary.withValues(alpha: 0.45),
                ),
              ),
              if (!compact)
                Text(
                  retailer.label,
                  style: AppText.micro.copyWith(
                    color: AppColors.secondary.withValues(alpha: 0.55),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: radius,
      child: imageUrl.isEmpty
          ? placeholder
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );
  }
}

/// Swipeable gallery with the site's `1 / 7` counter overlay and a thumbnail
/// strip beneath. The desktop page pairs the main image with a zoom button;
/// pinch-to-zoom is the phone equivalent, so the button is dropped.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.productId,
    required this.retailer,
    required this.images,
  });

  final String productId;
  final Retailer retailer;
  final List<String> images;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int index) {
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? const [''] : widget.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: PageView.builder(
                controller: _controller,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => ProductGalleryImage(
                  productId: widget.productId,
                  retailer: widget.retailer,
                  imageUrl: images[i],
                  index: i,
                ),
              ),
            ),
            Positioned(
              right: AppSpace.md,
              bottom: AppSpace.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.85),
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  '${_index + 1} / ${images.length}',
                  style: AppText.captionSemibold.copyWith(color: AppColors.background),
                ),
              ),
            ),
          ],
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
              itemBuilder: (context, i) {
                final active = i == _index;
                return GestureDetector(
                  onTap: () => _jumpTo(i),
                  child: Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.rSm,
                      border: Border.all(
                        color: active ? AppColors.secondary3 : AppColors.surface4,
                        width: active ? 1.6 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ProductGalleryImage(
                      productId: widget.productId,
                      retailer: widget.retailer,
                      imageUrl: images[i],
                      index: i,
                      radius: AppRadius.rSm,
                      compact: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
