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
import '../../data/auth_models.dart';
import '../auth_providers.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_checklist.dart';
import '../widgets/phone_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();

  /// E.164, composed by [PhoneField] — the compact form the endpoint wants.
  String _phone = '';

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _referralOpen = false;
  bool _submitting = false;
  bool _googleBusy = false;
  String? _banner;

  final _errors = <String, String?>{};

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _referral.dispose();
    super.dispose();
  }

  bool _validate() {
    final next = <String, String?>{};

    if (_firstName.text.trim().isEmpty) {
      next['firstName'] = 'This field is required';
    }
    if (_lastName.text.trim().isEmpty) {
      next['lastName'] = 'This field is required';
    }

    final email = _email.text.trim();
    if (email.isEmpty) {
      next['email'] = 'This field is required';
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      next['email'] = 'Please enter a valid email address';
    }

    if (_phone.isEmpty) {
      next['phoneNumber'] = 'This field is required';
    }

    if (_password.text.isEmpty) {
      next['password'] = 'This field is required';
    } else if (_password.text.length < 8) {
      next['password'] = 'Password must be at least 8 characters';
    }

    if (_confirm.text.isEmpty) {
      next['confirmPassword'] = 'This field is required';
    } else if (_confirm.text != _password.text) {
      next['confirmPassword'] = 'Passwords do not match';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(next);
    });
    return next.isEmpty;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    setState(() {
      _submitting = true;
      _banner = null;
    });
    try {
      // Destination country is never asked on this form — the backend infers it
      // from the phone country code (and the landing page's country switcher),
      // matching the live signup (discovery-notes.md § 2, "Notable").
      await ref.read(sessionProvider.notifier).register(
            RegisterRequest(
              firstName: _firstName.text.trim(),
              lastName: _lastName.text.trim(),
              email: _email.text.trim(),
              phoneNumber: _phone,
              password: _password.text,
              confirmPassword: _confirm.text,
              referralCode: _referral.text.trim().isEmpty
                  ? null
                  : _referral.text.trim().toUpperCase(),
            ),
          );
      if (!mounted) return;
      // Signup signs the user in immediately: no OTP, no verification gate.
      context.go(AppRoutes.home);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errors.addAll(e.fieldErrors);
        _banner = e.fieldErrors.isEmpty ? e.message : null;
      });
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
      context.go(AppRoutes.home);
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
                  loginSelected: false,
                  onLogin: () => context.go(AppRoutes.login),
                  onSignUp: () {},
                ),
                const SizedBox(height: AppSpace.xxl),
                Text('Create Account', style: AppText.h3),
                const SizedBox(height: AppSpace.xs),
                Text(
                  'Shop from your favorite retailers and get it delivered to you in 7-14 days',
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

                // Name fields are side by side on desktop; on a phone they are
                // always stacked.
                AppTextField(
                  label: 'First Name',
                  required: true,
                  controller: _firstName,
                  errorText: _errors['firstName'],
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Last Name',
                  required: true,
                  controller: _lastName,
                  errorText: _errors['lastName'],
                  enabled: !busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Email',
                  required: true,
                  controller: _email,
                  errorText: _errors['email'],
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: AppSpace.lg),
                PhoneField(
                  required: true,
                  enabled: !busy,
                  errorText: _errors['phoneNumber'],
                  textInputAction: TextInputAction.next,
                  onChanged: (value) => _phone = value,
                ),
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _password,
                  errorText: _errors['password'],
                  enabled: !busy,
                  obscure: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.neutral1,
                    ),
                  ),
                ),
                if (_password.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  PasswordChecklist(password: _password.text),
                ],
                const SizedBox(height: AppSpace.lg),
                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  controller: _confirm,
                  errorText: _errors['confirmPassword'],
                  enabled: !busy,
                  obscure: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: AppColors.neutral1,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                _ReferralDisclosure(
                  open: _referralOpen,
                  controller: _referral,
                  enabled: !busy,
                  onToggle: () => setState(() => _referralOpen = !_referralOpen),
                ),
                const SizedBox(height: AppSpace.xl),
                PrimaryButton(
                  label: 'Sign Up',
                  trailingIcon: Icons.arrow_forward,
                  loading: _submitting,
                  onPressed: busy ? null : _submit,
                ),
                const SizedBox(height: AppSpace.xl),
                const OrDivider(),
                const SizedBox(height: AppSpace.xl),
                GoogleAuthButton(
                  label: 'Sign up with Google',
                  loading: _googleBusy,
                  onPressed: busy ? null : _google,
                ),
                const SizedBox(height: AppSpace.xl),
                AuthFooterPrompt(
                  question: 'Already have an account?',
                  action: 'Login here',
                  onTap: () => context.go(AppRoutes.login),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsed `🎁 Have a referral code?` row that reveals the monospace field.
class _ReferralDisclosure extends StatelessWidget {
  const _ReferralDisclosure({
    required this.open,
    required this.controller,
    required this.onToggle,
    required this.enabled,
  });

  final bool open;
  final TextEditingController controller;
  final VoidCallback onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: AppRadius.rSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 15)),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'Have a referral code?',
                    style: AppText.body14Semibold.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                Icon(
                  open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.neutral1,
                ),
              ],
            ),
          ),
        ),
        if (open) ...[
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: controller,
            enabled: enabled,
            textCapitalization: TextCapitalization.characters,
            style: AppText.mono,
            decoration: InputDecoration(
              hintText: 'ENTER REFERRAL CODE',
              hintStyle: AppText.mono.copyWith(color: AppColors.neutral2),
            ),
          ),
        ],
      ],
    );
  }
}
