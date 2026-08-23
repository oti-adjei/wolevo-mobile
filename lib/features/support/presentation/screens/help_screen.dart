import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/support_content.dart';

/// `/help` — public, reachable signed out. Content is identical whether or not
/// a session exists; only the surrounding chrome differs on the web.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.landing),
        ),
        title: const Text('Help Center'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xl,
          AppSpace.gutter,
          AppSpace.section,
        ),
        children: [
          Text('Help Center', style: AppText.h2),
          const SizedBox(height: AppSpace.sm),
          Text(
            'Find answers or get in touch with our team.',
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
          const SizedBox(height: AppSpace.xxl),
          // Two cards sat side by side on desktop; stacked on a phone.
          _ShortcutCard(
            icon: Icons.call_outlined,
            title: 'Contact Us',
            subtitle: 'Phone, email, or WhatsApp',
            onTap: () => context.push(AppRoutes.support),
          ),
          const SizedBox(height: AppSpace.md),
          _ShortcutCard(
            icon: Icons.help_outline,
            title: 'Pricing Guide',
            subtitle: 'How we calculate costs',
            onTap: () => context.push(AppRoutes.pricing),
          ),
          const SizedBox(height: AppSpace.section),
          Text('Frequently Asked Questions', style: AppText.h3),
          for (final group in SupportContent.faq) ...[
            const SizedBox(height: AppSpace.xxl),
            Text(group.title, style: AppText.cardTitle),
            const SizedBox(height: AppSpace.md),
            for (final entry in group.entries) ...[
              _FaqTile(question: entry.question, answer: entry.answer),
              const SizedBox(height: AppSpace.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          IconChip(icon: icon),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.neutral2),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md,
      ),
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.question, style: AppText.body14Medium),
              ),
              Icon(
                _open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
                color: AppColors.neutral1,
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              widget.answer,
              style: AppText.body14.copyWith(color: AppColors.neutral1),
            ),
          ],
        ],
      ),
    );
  }
}
