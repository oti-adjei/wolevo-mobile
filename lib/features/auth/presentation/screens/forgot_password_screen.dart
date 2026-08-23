import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/verify_email_sheet.dart' show LimeIconCircle;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();

  bool _submitting = false;
  bool _sent = false;
  String? _emailError;
  String? _banner;
  String _sentTo = '';

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _backToSignIn() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() =>
        _emailError = valid ? null : 'Please enter a valid email address');
    if (!valid) return;

    setState(() {
      _submitting = true;
      _banner = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _sent = true;
        _sentTo = email;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _banner = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _banner = ApiException.network.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppTextLink(
              label: '← Back to Sign In',
              color: AppColors.neutral1,
              onPressed: _backToSignIn,
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          const Center(child: WolevoWordmark(fontSize: 28)),
          const SizedBox(height: AppSpace.xxl),
          AppCard(
            radius: AppRadius.rCardLarge,
            padding: const EdgeInsets.all(AppSpace.xl),
            child: _sent ? _buildSent() : _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: LimeIconCircle(icon: Icons.mail_outline)),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Forgot Password?',
          style: AppText.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          "Enter your email address and we'll send you a link to reset your password",
          style: AppText.body14.copyWith(color: AppColors.neutral1),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        if (_banner != null) ...[
          ErrorBanner(
            message: _banner!,
            onDismiss: () => setState(() => _banner = null),
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        AppTextField(
          label: 'Email Address',
          hint: 'Email',
          controller: _email,
          errorText: _emailError,
          enabled: !_submitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _submit(),
          prefix: const Icon(
            Icons.mail_outline,
            size: 20,
            color: AppColors.neutral1,
          ),
        ),
        const SizedBox(height: AppSpace.xl),
        PrimaryButton(
          label: 'Send Reset Link',
          loading: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
        const SizedBox(height: AppSpace.xl),
        AuthFooterPrompt(
          question: 'Remember your password?',
          action: 'Sign in',
          onTap: _backToSignIn,
        ),
      ],
    );
  }

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: LimeIconCircle(
            icon: Icons.check,
            background: AppColors.secondary2,
            foreground: AppColors.success2,
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          'Check Your Email',
          style: AppText.h3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.md),
        // Deliberately enumeration-safe wording, matching the web copy.
        Text.rich(
          TextSpan(
            style: AppText.body14.copyWith(color: AppColors.neutral1),
            children: [
              const TextSpan(text: 'If an account exists for '),
              TextSpan(
                text: _sentTo,
                style: AppText.body14Semibold.copyWith(
                  color: AppColors.bodyText,
                ),
              ),
              const TextSpan(
                text: ', you will receive a password reset link shortly.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          "The link will expire in 1 hour. Check your spam folder if you don't see it.",
          style: AppText.caption.copyWith(color: AppColors.neutral2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpace.xl),
        PrimaryButton(label: 'Back to Sign In', onPressed: _backToSignIn),
      ],
    );
  }
}
