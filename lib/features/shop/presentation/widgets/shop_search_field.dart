import 'package:flutter/material.dart';

import '../../../../core/widgets/app_search_field.dart';

/// The search box in `?mode=search`. Debouncing lives in [ShopQueryController]
/// rather than here, so a rebuild cannot restart the timer; this widget only
/// forwards keystrokes, submits and clears.
class ShopSearchField extends StatefulWidget {
  const ShopSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCleared,
    this.focusNode,
    this.hint = 'Search products…',
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;
  final String hint;

  @override
  State<ShopSearchField> createState() => _ShopSearchFieldState();
}

class _ShopSearchFieldState extends State<ShopSearchField> {
  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      hint: widget.hint,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onCleared: widget.onCleared,
    );
  }
}
