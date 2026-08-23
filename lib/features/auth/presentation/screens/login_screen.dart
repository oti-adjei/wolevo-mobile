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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  bool _googleBusy = false;
  String? _emailError;
  String? _passwordError;
  String? _banner;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// The web form applies the 8-character rule to the login input too, not just
  /// signup (discovery-notes.md § 4).
  bool _validate() {
    final email = _email.text.trim();
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _emailError = emailOk ? null : 'Please enter a valid email address';
      _passwordError =
          _password.text.length >= 8 ? null : 'Must be at least 8 characters';
    });
    return _emailError == null && _passwordError == null;
  }

  void _onAuthenticated() {
    // Preserving the intended destination through the auth wall is a
    // deliberate improvement on the live site, which drops it.
    final next = GoRouterState.of(context).uri.queryParameters[AppRoutes.nextParam];
    context.go(next != null && next.isNotEmpty ? next : AppRoutes.home);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() {
      _submitting = true;
      _banner = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      _onAuthenticated();
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

  Future<void> _google() async {
    setState(() {
      _googleBusy = true;
      _banner = null;
    });
    try {
      await ref.read(sessionProvider.notifier).continueWithGoogle();
      if (!mounted) return;
      _onAuthenticated();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _banner = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _banner = ApiException.network.message);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _submitting || _googleBusy;

    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: WolevoWordmark(fontSize: 28)),
          const SizedBox(height: AppSpace.xxl),
          AppCard(
            radius: AppRadius.rCardLarge,
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTabStrip(
                  loginSelected: true,
                  onLogin: () {},
                  onSignUp: () => context.go(AppRoutes.register),
                ),
                const SizedBox(height: AppSpace.xxl),
                Text('Welcome Back', style: AppText.h3),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Sign in to your account',
                  style: AppText.body14.copyWith(color: AppColors.neutral1),
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
                  label: 'Email',
                  hint: 'Email',
                  controller: _email,
                  errorText: _emailError,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'Password',
                  controller: _password,
                  focusNode: _passwordFocus,
                  errorText: _passwordError,
                  enabled: !busy,
                  obscure: _obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.neutral1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextLink(
                    label: 'Forgot password?',
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                PrimaryButton(
                  label: 'Login',
                  loading: _submitting,
                  onPressed: busy ? null : _submit,
                ),
                const SizedBox(height: AppSpace.xl),
                const OrDivider(),
                const SizedBox(height: AppSpace.xl),
                GoogleAuthButton(
                  label: 'Continue with Google',
                  loading: _googleBusy,
                  onPressed: busy ? null : _google,
                ),
                const SizedBox(height: AppSpace.xl),
                AuthFooterPrompt(
                  question: "Don't have an account?",
                  action: 'Sign up for free',
                  onTap: () => context.go(AppRoutes.register),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
