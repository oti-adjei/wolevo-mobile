import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/pagination.dart';
import '../data/mock_notifications_repository.dart';
import '../data/notification_models.dart';
import '../data/notifications_repository.dart';

/// Swap for a Dio-backed implementation to go live.
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => MockNotificationsRepository(),
);

/// Whether the inbox is filtered to unread. The site's full page has a
/// `Show all` toggle and defaults to unread-only.
final notificationsUnreadOnlyProvider = StateProvider<bool>((ref) => true);

/// Drives the bell badge. Refreshed whenever the list is reloaded or a row is
/// marked read.
class UnreadCountController extends AsyncNotifier<int> {
  @override
  Future<int> build() =>
      ref.watch(notificationsRepositoryProvider).unreadCount();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(notificationsRepositoryProvider).unreadCount(),
    );
  }
}

final unreadCountProvider = AsyncNotifierProvider<UnreadCountController, int>(
  UnreadCountController.new,
);

/// The inbox list, respecting the unread/all toggle.
class NotificationsListController extends AsyncNotifier<List<AppNotification>> {
  NotificationsRepository get _repo =>
      ref.read(notificationsRepositoryProvider);

  @override
  Future<List<AppNotification>> build() async {
    final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
    final page = await _repo.list(
      unreadOnly: unreadOnly,
      pagination: const Pagination(pageSize: 10),
    );
    return page.items;
  }

  Future<void> refresh() async {
    final unreadOnly = ref.read(notificationsUnreadOnlyProvider);
    state = await AsyncValue.guard(() async {
      final page = await _repo.list(unreadOnly: unreadOnly);
      return page.items;
    });
    await ref.read(unreadCountProvider.notifier).refresh();
  }

  Future<void> markRead(String id) async {
    await _repo.markRead(id);
    await refresh();
  }

  Future<void> markAllRead() async {
    await _repo.markAllRead();
    await refresh();
  }
}

final notificationsListProvider =
    AsyncNotifierProvider<NotificationsListController, List<AppNotification>>(
      NotificationsListController.new,
    );

/// The bell dropdown shows the most recent few regardless of read state.
final recentNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final page = await ref
          .watch(notificationsRepositoryProvider)
          .list(unreadOnly: false, pagination: const Pagination(pageSize: 5));
      return page.items;
    });
