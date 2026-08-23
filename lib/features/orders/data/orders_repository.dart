import '../../../core/models/pagination.dart';
import 'order_models.dart';

/// The Orders data surface.
///
/// One endpoint was observed backing `/orders`:
///
/// ```
/// GET /api/v1/user/fulfillments
///       ?status=PENDING
///       &pagination.pageNumber=1
///       &pagination.pageSize=20
/// ```
///
/// `status` is omitted for the "All" chip. The dotted `pagination.*` query
/// convention is handled by [Pagination.toQuery].
///
/// ASSUMPTION: the detail endpoint was never observed (the account had zero
/// orders, so no row was ever clickable). `GET /user/fulfillments/{id}` follows
/// the same REST shape as the rest of the API and is what [byId] models.
abstract interface class OrdersRepository {
  /// A page of fulfillments, newest first.
  ///
  /// [query] is the free-text search box ("Search by order ID, tracking…") and
  /// matches on reference, tracking number and item titles.
  Future<Paged<Fulfillment>> list({
    OrderStatus? status,
    String? query,
    Pagination pagination,
  });

  /// A single fulfillment with its items, timeline, address and costs.
  Future<Fulfillment> byId(String id);
}
