/// Returns a [Map] with the values from [original] and the values from
/// [updates].
///
/// For keys that are the same between [original] and [updates], the value in
/// [updates] is used. Keys with null values will be removed.
///
/// If [updates] is `null` or empty, [original] is returned unchanged.
Map<K, V> updateMap<K, V>(Map<K, V> original, Map<K, V?>? updates) {
  if (updates == null || updates.isEmpty) return original;

  final value = Map.of(original);
  for (var entry in updates.entries) {
    final val = entry.value;
    if (val == null) {
      value.remove(entry.key);
    } else {
      value[entry.key] = val;
    }
  }

  return value;
}
