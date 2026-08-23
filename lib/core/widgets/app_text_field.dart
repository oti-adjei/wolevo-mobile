import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Labelled field. The site marks required fields with a red asterisk after the
/// label and puts helper text below the input, errors in red with a ⓘ glyph.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.required = false,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.autofillHints,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final bool required;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Widget? prefix;
  final bool enabled;
  final List<String>? autofillHints;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        const SizedBox(height: AppSpace.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLines: obscure ? 1 : maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          enabled: enabled,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          style: AppText.body,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix,
            suffixIcon: suffix,
            errorText:
                null, // rendered manually below so the ⓘ icon matches web
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          FieldError(errorText!),
        ] else if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: AppText.caption.copyWith(color: AppColors.neutral1),
          ),
        ],
      ],
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppText.body14Medium.copyWith(color: AppColors.bodyText),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: AppText.body14Medium.copyWith(color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.error_outline, size: 14, color: AppColors.error),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: AppText.caption.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}

/// Dismissible red banner shown above a form on a server error — matches the
/// login page's "Invalid email or password" banner.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.error3,
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.error),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              message,
              style: AppText.body14.copyWith(color: AppColors.error),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}

/// Green confirmation block — the "Verification email sent!" state.
class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary2,
        borderRadius: AppRadius.rInput,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.success2,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body14Semibold.copyWith(
                    color: AppColors.success2,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message!,
                    style: AppText.caption.copyWith(color: AppColors.success2),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
