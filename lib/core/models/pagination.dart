/// The API takes pagination as dotted query keys — `pagination.pageNumber` and
/// `pagination.pageSize`, 1-indexed (observed on `/user/fulfillments` and
/// `/user/notifications`).
class Pagination {
  const Pagination({this.pageNumber = 1, this.pageSize = 20});

  final int pageNumber;
  final int pageSize;

  Map<String, dynamic> toQuery() => {
        'pagination.pageNumber': pageNumber,
        'pagination.pageSize': pageSize,
      };

  Pagination next() => Pagination(pageNumber: pageNumber + 1, pageSize: pageSize);
}

/// A page of results plus enough metadata to drive infinite scroll.
class Paged<T> {
  const Paged({
    required this.items,
    required this.pageNumber,
    required this.hasMore,
  });

  final List<T> items;
  final int pageNumber;
  final bool hasMore;

  static Paged<T> empty<T>() => Paged<T>(items: const [], pageNumber: 1, hasMore: false);
}
