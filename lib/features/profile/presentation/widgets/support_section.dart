import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../../support/data/support_content.dart';

/// Profile → Support. Contact details are verbatim from the site's support
/// section; WhatsApp is a first-class channel throughout Wolevo.
class SupportSection extends StatelessWidget {
  const SupportSection({super.key});

  static const _email = 'support@wolevo.com';
  static const _phone = '+233 59 639 4945';
  static const _whatsapp = '233596394945';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconChip(icon: Icons.help_outline),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Help Center', style: AppText.cardTitleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Browse our knowledge base and frequently asked questions.',
                          style: AppText.caption.copyWith(
                            color: AppColors.neutral1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              SecondaryButton(
                label: 'Visit Help Center',
                icon: Icons.open_in_new,
                onPressed: () => context.push(AppRoutes.help),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Contact support'),
        const SizedBox(height: AppSpace.md),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Column(
            children: [
              _ContactRow(
                icon: Icons.mail_outline,
                label: _email,
                onTap: () => _launch('mailto:$_email'),
              ),
              const Divider(height: 1),
              _ContactRow(
                icon: Icons.call_outlined,
                label: _phone,
                onTap: () => _launch('tel:${_phone.replaceAll(' ', '')}'),
              ),
              const Divider(height: 1),
              _ContactRow(
                icon: Icons.chat_bubble_outline,
                label: 'Chat on WhatsApp',
                subtitle: 'Message us on WhatsApp for faster support',
                onTap: () => _launch('https://wa.me/$_whatsapp'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Legal & policies'),
        const SizedBox(height: AppSpace.md),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
          child: Column(
            children: [
              for (final entry in SupportContent.legalLinks.entries) ...[
                _ContactRow(
                  icon: Icons.description_outlined,
                  label: entry.key,
                  onTap: () => _launch(entry.value),
                ),
                if (entry.key != SupportContent.legalLinks.keys.last)
                  const Divider(height: 1),
              ],
            ],
          ),
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

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.neutral1),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.body14Medium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppText.caption.copyWith(
                        color: AppColors.neutral1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.neutral2,
            ),
          ],
        ),
      ),
    );
  }
}
