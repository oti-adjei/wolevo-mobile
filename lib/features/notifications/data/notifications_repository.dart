import '../../../core/models/pagination.dart';
import 'notification_models.dart';

/// Endpoints modelled:
///   GET /api/v1/user/notifications?pagination.pageNumber=1&pagination.pageSize=10
///   GET /api/v1/user/notifications/unread-count   (fires on every page load)
abstract interface class NotificationsRepository {
  Future<Paged<AppNotification>> list({
    required bool unreadOnly,
    Pagination pagination = const Pagination(pageSize: 10),
  });

  Future<int> unreadCount();

  /// ASSUMPTION: no mark-as-read call was observed (the inbox was empty), but
  /// an unread count that never decrements would be broken, so the endpoint is
  /// assumed to exist.
  Future<void> markRead(String id);

  Future<void> markAllRead();
}
