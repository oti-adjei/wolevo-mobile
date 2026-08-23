import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../data/support_content.dart';

/// `/support` — public. The web app scoped this with `?country=us|ghana|nigeria`
/// and rendered three expandable office cards; the same structure works on a
/// phone unchanged.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialCountry});

  /// Matches the site's `?country=` param.
  final String? initialCountry;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late int _open = _initialIndex();

  int _initialIndex() {
    final country = widget.initialCountry?.toLowerCase();
    if (country == null) return 0;
    final index = SupportContent.offices.indexWhere(
      (o) => o.country.toLowerCase().startsWith(country),
    );
    return index == -1 ? 0 : index;
  }

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
        title: const Text('Contact Us'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xl,
          AppSpace.gutter,
          AppSpace.section,
        ),
        children: [
          Text('Contact Us', style: AppText.h2),
          const SizedBox(height: AppSpace.sm),
          Text(
            "Reach out to the team closest to you. We're here to help.",
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
          const SizedBox(height: AppSpace.xxl),
          for (var i = 0; i < SupportContent.offices.length; i++) ...[
            _OfficeCard(
              office: SupportContent.offices[i],
              expanded: _open == i,
              onToggle: () => setState(() => _open = _open == i ? -1 : i),
            ),
            const SizedBox(height: AppSpace.md),
          ],
        ],
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  const _OfficeCard({
    required this.office,
    required this.expanded,
    required this.onToggle,
  });

  final SupportOffice office;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Row(
                children: [
                  const IconChip(icon: Icons.location_on_outlined, size: 40),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(office.country, style: AppText.cardTitleMedium),
                        const SizedBox(height: 2),
                        Text(
                          office.city,
                          style: AppText.caption.copyWith(
                            color: AppColors.neutral1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.neutral1,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.place_outlined,
                    label: 'Address',
                    value: office.address,
                  ),
                  _DetailRow(
                    icon: Icons.mail_outline,
                    label: 'Email',
                    value: office.email,
                    onTap: () => _launch('mailto:${office.email}'),
                  ),
                  _DetailRow(
                    icon: Icons.call_outlined,
                    label: 'Phone',
                    value: office.phone,
                    onTap: () =>
                        _launch('tel:${office.phone.replaceAll(' ', '')}'),
                  ),
                  _DetailRow(
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    value: 'Message us',
                    onTap: () => _launch('https://wa.me/${office.whatsapp}'),
                  ),
                  _DetailRow(
                    icon: Icons.schedule_outlined,
                    label: 'Hours',
                    value: office.hours,
                    last: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : AppSpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.neutral1),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.caption.copyWith(color: AppColors.neutral1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppText.body14Medium.copyWith(
                      color: onTap == null
                          ? AppColors.bodyText
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
