import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../auth_providers.dart';

/// Opens the verify-email sheet. On the web this is a centered modal; on mobile
/// it becomes a non-blocking bottom sheet the user can dismiss — verification
/// is entirely deferrable (discovery-notes.md § 3).
Future<void> showVerifyEmailSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => const VerifyEmailSheet(),
  );
}

class VerifyEmailSheet extends ConsumerStatefulWidget {
  const VerifyEmailSheet({super.key});

  @override
  ConsumerState<VerifyEmailSheet> createState() => _VerifyEmailSheetState();
}

class _VerifyEmailSheetState extends ConsumerState<VerifyEmailSheet> {
  bool _resending = false;
  bool _checking = false;
  bool _resent = false;
  String? _error;

  Future<void> _resend(String email) async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerificationEmail(email);
      if (!mounted) return;
      setState(() => _resent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = ApiException.network.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _confirmVerified() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final verified = await ref
          .read(sessionProvider.notifier)
          .refreshVerification();
      if (!mounted) return;
      if (verified) {
        Navigator.of(context).pop();
        return;
      }
      // ASSUMPTION: the "not yet verified" branch was never reached in
      // discovery (the throwaway account was left unverified), so this inline
      // nudge is invented.
      setState(
        () => _error =
            "We can't see a confirmation yet. Click the link in the email, then try again.",
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = ApiException.network.message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).valueOrNull?.user.email ?? '';
    final busy = _resending || _checking;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.xl,
                AppSpace.xl,
                AppSpace.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      height: 4,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surface4,
                        borderRadius: AppRadius.rPill,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  const Center(child: LimeIconCircle(icon: Icons.mail_outline)),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    'Verify your email',
                    style: AppText.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    "We've sent a verification link to your inbox. Confirming your address means order updates and your final bill reach you.",
                    style: AppText.body14.copyWith(color: AppColors.neutral1),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpace.xl),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.rInput,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verification email sent to:',
                          style: AppText.caption.copyWith(
                            color: AppColors.neutral1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(email, style: AppText.body14Semibold),
                      ],
                    ),
                  ),
                  if (_resent) ...[
                    const SizedBox(height: AppSpace.lg),
                    const SuccessBanner(
                      title: 'Verification email sent!',
                      message:
                          'Check your inbox and spam folder. Click the link in the email to verify your account.',
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpace.lg),
                    ErrorBanner(
                      message: _error!,
                      onDismiss: () => setState(() => _error = null),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xl),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: busy ? null : _confirmVerified,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        disabledBackgroundColor: AppColors.success.withValues(
                          alpha: 0.55,
                        ),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.rInput,
                        ),
                      ),
                      child: _checking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "I've Already Verified",
                              style: AppText.bodySemibold.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  PrimaryButton(
                    label: 'Resend Verification Email',
                    loading: _resending,
                    onPressed: busy ? null : () => _resend(email),
                  ),
                  const SizedBox(height: AppSpace.md),
                  SecondaryButton(
                    label: "I'll Verify Later",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Text(
                    "Didn't receive the email? Check your spam folder or click the resend button above.",
                    style: AppText.caption.copyWith(color: AppColors.neutral2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lime disc that carries the envelope / check glyph on the verify sheet
/// and the forgot-password card.
class LimeIconCircle extends StatelessWidget {
  const LimeIconCircle({
    super.key,
    required this.icon,
    this.background = AppColors.tertiary,
    this.foreground = AppColors.secondary,
    this.size = 64,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.45, color: foreground),
    );
  }
}
