// INFERRED SCREEN: the live account had zero orders during discovery, so no
// order detail view was ever observable (see discovery-notes.md § "States not
// reached"). The layout below is derived from the 5-step journey stepper on
// /ship, the cart's cost-summary conventions, and the status enum exposed by
// GET /user/fulfillments.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/money.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffolding.dart';
import '../../data/order_models.dart';
import '../orders_providers.dart';
import '../widgets/order_item_thumb.dart';
import '../widgets/order_status_badge.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.orders),
        ),
        title: Text(async.valueOrNull?.reference ?? 'Order'),
      ),
      body: switch (async) {
        AsyncError(:final error) => ErrorRetry(
            message: '$error',
            onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
          ),
        AsyncData(:final value) => _Body(fulfillment: value),
        _ => const AppLoader(),
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.fulfillment});

  final Fulfillment fulfillment;

  @override
  Widget build(BuildContext context) {
    final f = fulfillment;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        AppSpace.lg,
        AppSpace.gutter,
        AppSpace.section,
      ),
      children: [
        _HeaderCard(fulfillment: f),
        const SizedBox(height: AppSpace.lg),
        const EyebrowLabel('Tracking'),
        const SizedBox(height: AppSpace.md),
        AppCard(child: _Timeline(events: f.timeline)),
        if (f.items.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xxl),
          EyebrowLabel('Items (${f.itemCount})'),
          const SizedBox(height: AppSpace.md),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < f.items.length; i++) ...[
                  _ItemRow(item: f.items[i]),
                  if (i != f.items.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Cost summary'),
        const SizedBox(height: AppSpace.md),
        // Single column — the desktop sidebar does not survive a 375px phone.
        AppCard(child: _CostSummary(costs: f.costs, destination: f.destinationCountry.name)),
        const SizedBox(height: AppSpace.xxl),
        const EyebrowLabel('Delivery address'),
        const SizedBox(height: AppSpace.md),
        AppCard(child: _AddressBlock(address: f.deliveryAddress)),
        const SizedBox(height: AppSpace.xxl),
        SecondaryButton(
          label: 'Get help with this order',
          icon: Icons.help_outline,
          onPressed: () => context.push(AppRoutes.support),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.fulfillment});

  final Fulfillment fulfillment;

  @override
  Widget build(BuildContext context) {
    final f = fulfillment;
    final created = DateFormat('d MMM yyyy').format(f.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(f.reference, style: AppText.cardTitle)),
              OrderStatusBadge(status: f.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${f.sourceLabel} · Placed $created',
            style: AppText.body14.copyWith(color: AppColors.neutral1),
          ),
          if (f.currentEvent case final event?) ...[
            const SizedBox(height: AppSpace.lg),
            InfoCallout(
              leading: '📦',
              background: AppColors.tertiary3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.label, style: AppText.body14Semibold),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description,
                      style: AppText.caption.copyWith(color: AppColors.neutral),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (f.trackingNumber case final tracking?) ...[
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EyebrowLabel('Tracking number'),
                      const SizedBox(height: 2),
                      Text(tracking, style: AppText.bodySemibold),
                    ],
                  ),
                ),
                _CopyButton(value: tracking, label: 'Tracking number'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondary2,
      borderRadius: AppRadius.rSm,
      child: InkWell(
        borderRadius: AppRadius.rSm,
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('$label copied')));
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            'Copy',
            style: AppText.captionSemibold.copyWith(color: AppColors.secondary),
          ),
        ),
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});

  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'Tracking updates will appear here.',
        style: AppText.body14.copyWith(color: AppColors.neutral1),
      );
    }

    final currentIndex = events.indexWhere((e) => !e.completed);

    return Column(
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineNode(
            event: events[i],
            isFirst: i == 0,
            isLast: i == events.length - 1,
            isCurrent: i == currentIndex,
            // The connector below a node is green only while the parcel has
            // already moved past it.
            connectorFilled: events[i].completed,
          ),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.isCurrent,
    required this.connectorFilled,
  });

  final TrackingEvent event;
  final bool isFirst;
  final bool isLast;
  final bool isCurrent;
  final bool connectorFilled;

  @override
  Widget build(BuildContext context) {
    final done = event.completed;
    final muted = !done && !isCurrent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 6, color: AppColors.surface4),
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.secondary
                        : isCurrent
                            ? AppColors.tertiary
                            : AppColors.background,
                    border: Border.all(
                      color: done
                          ? AppColors.secondary
                          : isCurrent
                              ? AppColors.secondary3
                              : AppColors.surface4,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: connectorFilled ? AppColors.secondary : AppColors.surface4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpace.xl, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          event.label,
                          style: AppText.body14Semibold.copyWith(
                            color: muted ? AppColors.neutral2 : AppColors.bodyText,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: AppSpace.sm),
                        const MicroBadge(label: "You're here"),
                      ],
                    ],
                  ),
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      event.description,
                      style: AppText.caption.copyWith(
                        color: muted ? AppColors.neutral2 : AppColors.neutral1,
                      ),
                    ),
                  ],
                  if (event.timestamp case final ts?) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy · HH:mm').format(ts),
                      style: AppText.caption.copyWith(color: AppColors.neutral2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final FulfillmentItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderItemThumb(item: item),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body14Medium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty ${item.quantity} · ${item.retailer.label}',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.unitPrice.usdLabel,
                style: AppText.body14Semibold.copyWith(color: AppColors.secondary3),
              ),
              Text(
                item.unitPrice.localLabel,
                style: AppText.caption.copyWith(color: AppColors.neutral1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CostSummary extends StatelessWidget {
  const _CostSummary({required this.costs, required this.destination});

  final CostBreakdown costs;
  final String destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CostRow(label: 'Subtotal', value: costs.subtotal),
        _CostRow(label: 'Retailer Shipping', value: costs.retailerShipping),
        _CostRow(label: 'Shipping to $destination', value: costs.shippingToDestination),
        _CostRow(label: 'Handling', value: costs.handling),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpace.md),
          child: Divider(height: 1),
        ),
        _CostRow(label: 'Total', value: costs.total, emphasised: true),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.emphasised = false});

  final String label;
  final Money? value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasised
                  ? AppText.bodySemibold
                  : AppText.body14.copyWith(color: AppColors.neutral1),
            ),
          ),
          if (value == null)
            Text(
              // Same wording the cart uses for costs the warehouse has not
              // determined yet.
              'Calculated at checkout',
              style: AppText.body14.copyWith(color: AppColors.neutral1),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value!.usdLabel,
                  style: emphasised ? AppText.bodySemibold : AppText.body14Medium,
                ),
                Text(
                  value!.localLabel,
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.address});

  final DeliveryAddressSummary address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address.line1, style: AppText.body14Semibold),
        const SizedBox(height: 2),
        Text(
          '${address.city}, ${address.region}',
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        Text(
          address.countryName,
          style: AppText.body14.copyWith(color: AppColors.neutral1),
        ),
        if (address.nearestLandmark case final landmark?) ...[
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.neutral1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Nearest landmark: $landmark',
                  style: AppText.caption.copyWith(color: AppColors.neutral1),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
