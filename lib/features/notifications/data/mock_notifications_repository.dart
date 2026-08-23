import '../../../core/models/pagination.dart';
import 'notification_models.dart';
import 'notifications_repository.dart';

/// In-memory inbox.
///
/// The live account's inbox was empty during discovery ("You're all caught up"),
/// so [seedDemoNotifications] defaults to true here purely so the populated
/// design is demoable — flip it to false to reproduce the exact state observed.
/// ASSUMPTION: the shape and wording of individual notification cards was never
/// observable and is written to match the site's voice.
class MockNotificationsRepository implements NotificationsRepository {
  MockNotificationsRepository({this.seedDemoNotifications = true}) {
    if (seedDemoNotifications) _items.addAll(_seed());
  }

  final bool seedDemoNotifications;

  static const _latency = Duration(milliseconds: 450);

  final List<AppNotification> _items = [];

  static List<AppNotification> _seed() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'ntf_1',
        title: 'Your package arrived at our warehouse',
        body: 'WLV-10241 was received in New Castle, DE and is being weighed.',
        createdAt: now.subtract(const Duration(hours: 3)),
        read: false,
        kind: NotificationKind.shipment,
        deepLink: '/orders/ful_1',
      ),
      AppNotification(
        id: 'ntf_2',
        title: r'Quote ready — $24.80 to Ghana',
        body: 'Pay for WLV-10238 to release it for shipping.',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
        read: false,
        kind: NotificationKind.payment,
        deepLink: '/orders/ful_2',
      ),
      AppNotification(
        id: 'ntf_3',
        title: 'Order purchased',
        body: 'We bought your 2 items from Amazon. Tracking follows once they ship.',
        createdAt: now.subtract(const Duration(days: 2)),
        read: true,
        kind: NotificationKind.order,
        deepLink: '/orders/ful_3',
      ),
      AppNotification(
        id: 'ntf_4',
        title: 'Delivered',
        body: 'WLV-10233 was delivered in Accra. Thanks for shopping with Wolevo.',
        createdAt: now.subtract(const Duration(days: 6)),
        read: true,
        kind: NotificationKind.order,
        deepLink: '/orders/ful_4',
      ),
    ];
  }

  @override
  Future<Paged<AppNotification>> list({
    required bool unreadOnly,
    Pagination pagination = const Pagination(pageSize: 10),
  }) async {
    await Future<void>.delayed(_latency);

    final filtered = _items.where((n) => !unreadOnly || !n.read).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (pagination.pageNumber - 1) * pagination.pageSize;
    if (start >= filtered.length) {
      return Paged(items: const [], pageNumber: pagination.pageNumber, hasMore: false);
    }
    final end = (start + pagination.pageSize).clamp(0, filtered.length);

    return Paged(
      items: filtered.sublist(start, end),
      pageNumber: pagination.pageNumber,
      hasMore: end < filtered.length,
    );
  }

  @override
  Future<int> unreadCount() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _items.where((n) => !n.read).length;
  }

  @override
  Future<void> markRead(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final index = _items.indexWhere((n) => n.id == id);
    if (index != -1) _items[index] = _items[index].copyWith(read: true);
  }

  @override
  Future<void> markAllRead() async {
    await Future<void>.delayed(_latency);
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
  }
}
