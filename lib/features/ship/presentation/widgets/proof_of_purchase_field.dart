import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/ship_models.dart';

const _maxFiles = 3;
const _maxBytes = 10 * 1024 * 1024;
const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

/// `Proof of Purchase (required) *` — the receipt uploader.
///
/// The web version is a drag-and-drop target; on a phone it becomes a tap
/// target that opens the system file picker. The limits (3 files, 10MB each,
/// JPG/PNG/PDF) are the site's own and are enforced client-side here so the
/// user sees the error before a round trip.
class ProofOfPurchaseField extends StatefulWidget {
  const ProofOfPurchaseField({
    super.key,
    required this.files,
    required this.onChanged,
  });

  final List<ProofFile> files;
  final ValueChanged<List<ProofFile>> onChanged;

  @override
  State<ProofOfPurchaseField> createState() => _ProofOfPurchaseFieldState();
}

class _ProofOfPurchaseFieldState extends State<ProofOfPurchaseField> {
  String? _error;
  bool _picking = false;

  Future<void> _pick() async {
    if (_picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      // file_picker 12 exposes static methods and returns an empty list when
      // the user cancels (the 11.x `FilePicker.platform` singleton is gone).
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );
      if (picked.isEmpty) return; // cancelled

      final next = [...widget.files];
      String? error;

      for (final file in picked) {
        final path = file.path;
        if (path == null) continue;
        // PlatformFile exposes length() rather than a `size` field in
        // file_picker 12; the extension has to come off the name.
        final size = await file.length();
        if (size > _maxBytes) {
          error = '${file.name} is larger than 10MB.';
          continue;
        }
        final extension = file.name.split('.').last.toLowerCase();
        if (!_allowedExtensions.contains(extension)) {
          error = '${file.name} is not a JPG, PNG or PDF.';
          continue;
        }
        if (next.any((f) => f.path == path)) continue;
        if (next.length >= _maxFiles) {
          error = 'You can attach up to $_maxFiles files.';
          break;
        }
        next.add(ProofFile(name: file.name, sizeBytes: size, path: path));
      }

      widget.onChanged(next);
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _remove(ProofFile file) {
    widget.onChanged(widget.files.where((f) => f.path != file.path).toList());
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.files.length >= _maxFiles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Proof of Purchase (required)', required: true),
        const SizedBox(height: AppSpace.sm),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          color: AppColors.surface6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload your receipt, order confirmation, or invoice. Must clearly show '
                'item names, quantities, and prices. We use this to verify your package '
                'when it arrives. Max 3 files.',
                style: AppText.body14.copyWith(color: AppColors.neutral1),
              ),
              const SizedBox(height: AppSpace.lg),
              _DropTarget(
                enabled: !full && !_picking,
                busy: _picking,
                onTap: _pick,
              ),
              if (widget.files.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final file in widget.files)
                      _FileChip(file: file, onRemove: () => _remove(file)),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 6), FieldError(_error!)],
      ],
    );
  }
}

class _DropTarget extends StatelessWidget {
  const _DropTarget({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        borderRadius: AppRadius.rCard,
        onTap: enabled ? onTap : null,
        child: CustomPaint(
          painter: const _DashedBorderPainter(color: AppColors.inputBorder),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
            child: Column(
              children: [
                if (busy)
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.secondary,
                    ),
                  )
                else
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 24,
                    color: AppColors.neutral1,
                  ),
                const SizedBox(height: AppSpace.sm),
                Text('Tap to upload', style: AppText.body14Semibold),
                const SizedBox(height: 2),
                Text(
                  'Max 10MB per file — JPG, PNG, PDF',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.file, required this.onRemove});

  final ProofFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.description_outlined,
            size: 16,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpace.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body14Medium,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            file.sizeLabel,
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: AppRadius.rSm,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 14, color: AppColors.neutral1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed rounded rectangle — the web uploader's drop-zone border.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(Offset.zero & size, AppRadius.card);
    final path = Path()..addRRect(rrect);

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
