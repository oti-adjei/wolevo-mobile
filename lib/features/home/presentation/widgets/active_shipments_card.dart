import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../home_providers.dart';

/// The hero card on Home: how many parcels are in flight right now.
///
/// This is the one element on the screen allowed to shout, which is what makes
/// the layout read as calm — the app bar above it is flat, and everything below
/// is white cards. Rendered in lime rather than the client mockup's dark green,
/// because our app bar is already dark: two dark blocks stacked would put the
/// weight back where the mockup removed it.
class ActiveShipmentsCard extends ConsumerWidget {
  const ActiveShipmentsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(activeShipmentsProvider);
    final total = summary.valueOrNull?.total ?? 0;

    return Material(
      color: AppColors.tertiary,
      borderRadius: AppRadius.rCardLarge,
      child: InkWell(
        borderRadius: AppRadius.rCardLarge,
        onTap: () => context.go(AppRoutes.orders),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.xl),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(borderRadius: AppRadius.rCardLarge),
          child: Stack(
            children: [
              // The diagonal stripes from the mockup, drawn rather than
              // shipped as an image so they follow the palette.
              Positioned.fill(
                child: CustomPaint(painter: const _StripePainter()),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Expanded, not Spacer: the label must be allowed to
                      // ellipsize rather than push the pill off the card.
                      Expanded(
                        child: Text(
                          'ACTIVE SHIPMENTS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.micro.copyWith(color: AppColors.secondary),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: AppRadius.rPill,
                        ),
                        child: Text(
                          'Live Tracking',
                          style: AppText.captionSemibold.copyWith(
                            color: AppColors.tertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$total',
                        style: AppText.h1.copyWith(
                          color: AppColors.secondary,
                          fontSize: 46,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            summary.valueOrNull?.caption ?? 'Loading…',
                            style: AppText.body14.copyWith(
                              color: AppColors.secondary3,
                            ),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 34,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.07)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.square;

    // Three diagonals sweeping off the right edge.
    for (var i = 0; i < 3; i++) {
      final x = size.width - 30 + i * 34.0;
      canvas.drawLine(
        Offset(x, size.height + 20),
        Offset(x - size.height - 40, -20),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => false;
}
