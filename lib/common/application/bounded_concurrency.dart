/// Runs [load] for every id with at most [parallel] requests in flight and
/// joins the results in the order of [ids]. Several resources of the current
/// API are exposed per environment, so laboratory-wide views add them up the
/// same way QualiTrack Web does.
Future<List<T>> loadAll<T>(
  Iterable<int> ids,
  Future<List<T>> Function(int id) load, {
  int parallel = 4,
}) async {
  final pending = ids.toList();
  final result = <T>[];
  for (var i = 0; i < pending.length; i += parallel) {
    final groups = await Future.wait(pending.skip(i).take(parallel).map(load));
    for (final group in groups) {
      result.addAll(group);
    }
  }
  return result;
}
