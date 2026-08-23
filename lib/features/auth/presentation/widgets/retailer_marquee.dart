import 'package:flutter/material.dart';

import '../../../../core/models/retailer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Infinite horizontal marquee of retailer names separated by a green sparkle,
/// matching the strip under the hero. Driven by a repeating [AnimationController]
/// that scrolls one full copy of the list, then snaps back — with two copies
/// rendered the seam is invisible.
class RetailerMarquee extends StatefulWidget {
  const RetailerMarquee({
    super.key,
    this.height = 56,
    this.pixelsPerSecond = 40,
  });

  final double height;
  final double pixelsPerSecond;

  @override
  State<RetailerMarquee> createState() => _RetailerMarqueeState();
}

class _RetailerMarqueeState extends State<RetailerMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  final _scrollController = ScrollController();
  double _runWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tick);
  }

  void _tick() {
    if (!_scrollController.hasClients || _runWidth <= 0) return;
    _scrollController.jumpTo(_controller.value * _runWidth);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_tick)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Row(
                children: [
                  _MarqueeRun(
                    onWidth: (w) {
                      if ((w - _runWidth).abs() > 0.5) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _runWidth = w);
                        });
                      }
                    },
                  ),
                  const _MarqueeRun(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarqueeRun extends StatelessWidget {
  const _MarqueeRun({this.onWidth});

  final ValueChanged<double>? onWidth;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (final retailer in Retailer.values) {
      children.add(
        Text(
          retailer.label.toUpperCase(),
          style: AppText.body14Semibold.copyWith(
            color: AppColors.secondary,
            letterSpacing: 1.4,
          ),
        ),
      );
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Icon(Icons.auto_awesome, size: 14, color: AppColors.primary3),
        ),
      );
    }

    final row = Row(mainAxisSize: MainAxisSize.min, children: children);
    if (onWidth == null) return row;
    return _MeasureWidth(onWidth: onWidth!, child: row);
  }
}

class _MeasureWidth extends StatefulWidget {
  const _MeasureWidth({required this.onWidth, required this.child});

  final ValueChanged<double> onWidth;
  final Widget child;

  @override
  State<_MeasureWidth> createState() => _MeasureWidthState();
}

class _MeasureWidthState extends State<_MeasureWidth> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) widget.onWidth(box.size.width);
    });
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
