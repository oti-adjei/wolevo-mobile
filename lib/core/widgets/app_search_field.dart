import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// The app's search box.
///
/// Deliberately not the themed [InputDecoration] used by forms: that carries a
/// heavy outline and 8px corners, which reads as "fill this in" rather than
/// "search". This is a soft pill with a hairline edge, sized to sit under a
/// header without crowding it.
///
/// Debouncing belongs to the caller — this widget only forwards keystrokes,
/// submits and clears, so a rebuild can never restart someone else's timer.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.rPill,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpace.lg),
          const Icon(Icons.search, size: 20, color: AppColors.neutral2),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              style: AppText.body14,
              onChanged: (value) {
                widget.onChanged(value);
                setState(() {}); // keeps the clear affordance in sync
              },
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppText.body14.copyWith(color: AppColors.neutral2),
                // The pill above draws the surface; the field itself is bare.
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppColors.neutral1,
              ),
              onPressed: () {
                widget.controller.clear();
                widget.onCleared?.call();
                widget.onChanged('');
                setState(() {});
              },
            )
          else
            const SizedBox(width: AppSpace.sm),
        ],
      ),
    );
  }
}
