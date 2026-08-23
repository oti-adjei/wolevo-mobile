import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// `Secure Transaction · Shipping Policy · Refund Policy`, then the
/// `We accept` payment rail. The site lays these out in a single row; at 375px
/// they wrap.
class ProductTrustRow extends StatelessWidget {
  const ProductTrustRow({super.key, this.onShippingPolicy, this.onRefundPolicy});

  final VoidCallback? onShippingPolicy;
  final VoidCallback? onRefundPolicy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpace.lg,
          runSpacing: AppSpace.md,
          children: [
            const _TrustItem(icon: Icons.lock_outline, label: 'Secure Transaction'),
            _TrustItem(
              icon: Icons.local_shipping_outlined,
              label: 'Shipping Policy',
              onTap: onShippingPolicy,
            ),
            _TrustItem(
              icon: Icons.assignment_return_outlined,
              label: 'Refund Policy',
              onTap: onRefundPolicy,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Text(
          'We accept',
          style: AppText.caption.copyWith(color: AppColors.neutral1),
        ),
        const SizedBox(height: AppSpace.sm),
        const Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            // Mobile Money and Bank Transfer are the two rails that matter in
            // Ghana and Nigeria — the site lists them alongside the cards.
            _PaymentChip(label: 'Visa', icon: Icons.credit_card),
            _PaymentChip(label: 'Mastercard', icon: Icons.credit_card),
            _PaymentChip(label: 'Mobile Money', icon: Icons.smartphone),
            _PaymentChip(label: 'Bank Transfer', icon: Icons.account_balance_outlined),
          ],
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final body = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.secondary3),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppText.body14.copyWith(
            color: AppColors.secondary5,
            decoration: onTap == null ? null : TextDecoration.underline,
            decorationColor: AppColors.surface5,
          ),
        ),
      ],
    );
    if (onTap == null) return body;
    return InkWell(onTap: onTap, borderRadius: AppRadius.rSm, child: body);
  }
}

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface6,
        borderRadius: AppRadius.rSm,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.neutral1),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.secondary5),
          ),
        ],
      ),
    );
  }
}
