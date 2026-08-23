import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_search_field.dart';

/// "Search by order ID, tracking…" — the site pairs the field with an explicit
/// `Search` button. On a phone the keyboard's search action does that job, and
/// the query is additionally debounced so the list updates as you type without
/// firing a request per keystroke.
class OrdersSearchField extends StatefulWidget {
  const OrdersSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 350),
  });

  final TextEditingController controller;

  /// Fires after [debounce] of quiet, or immediately on submit / clear.
  final ValueChanged<String> onChanged;

  final Duration debounce;

  @override
  State<OrdersSearchField> createState() => _OrdersSearchFieldState();
}

class _OrdersSearchFieldState extends State<OrdersSearchField> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
    setState(() {}); // keeps the clear affordance in sync
  }

  void _submitNow(String value) {
    _timer?.cancel();
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return AppSearchField(
      controller: widget.controller,
      hint: 'Search by order ID, tracking…',
      onChanged: _schedule,
      onSubmitted: _submitNow,
      onCleared: () => _submitNow(''),
    );
  }
}
