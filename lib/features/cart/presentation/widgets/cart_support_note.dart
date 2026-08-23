import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// `Having issues? WhatsApp · Email · Help` plus the terms line, both copied
/// from the live cart's step-2 sidebar. WhatsApp and Email hand off externally
/// exactly as they do on the web; Help stays in-app.
class CartSupportNote extends StatelessWidget {
  const CartSupportNote({super.key});

  static const _whatsapp = 'https://wa.me/233596394945';
  static const _email = 'mailto:support@wolevo.com';

  @override
  Widget build(BuildContext context) {
    final muted = AppText.caption.copyWith(color: AppColors.neutral1);
    final link = AppText.captionSemibold.copyWith(color: AppColors.secondary);

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Having issues? ', style: muted),
            _SupportLink(label: 'WhatsApp', style: link, onTap: () => _launch(_whatsapp)),
            Text(' · ', style: muted),
            _SupportLink(label: 'Email', style: link, onTap: () => _launch(_email)),
            Text(' · ', style: muted),
            _SupportLink(
              label: 'Help',
              style: link,
              onTap: () => context.push(AppRoutes.help),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'By proceeding, you agree to our Terms of Service',
          style: muted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _SupportLink extends StatelessWidget {
  const _SupportLink({
    required this.label,
    required this.style,
    required this.onTap,
  });

  final String label;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(label, style: style),
    );
  }
}
