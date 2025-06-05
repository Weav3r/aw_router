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

// String normalizePath(String path) {
//   if (!path.startsWith('/')) {
//     path = '/$path';
//   }
//   // Remove trailing slash unless it's the root path or intended for wildcard
//   if (path.length > 1 && path.endsWith('/') && !path.contains('<path|')) {
//     path = path.substring(0, path.length - 1);
//   }
//   return path;
// }

/// Utility for normalizing route paths for consistent registration and matching.
String normalizePathi(String path) => path;
String normalizePath(String path) {
  if (path.isEmpty) return '/';

  // Remove double slashes, except for root
  path = path.replaceAll(RegExp(r'\/\/+'), '/');

  // Always ensure a leading slash
  if (!path.startsWith('/')) path = '/$path';
  // Remove trailing slash unless root or wildcard/regex (e.g. <path|...)
  if (path.length > 1 &&
      path.endsWith('/') &&
      !path.contains('<path|') &&
      !path.contains('<.*>')) {
    path = path.substring(0, path.length - 1);
  }
  return path;
}

String normalizePathxx(String path) {
  if (path.isEmpty) return '/';

  // Remove duplicate slashes except for root
  path = path.replaceAll(RegExp(r'\/\/+'), '/');

  // Ensure leading slash
  if (!path.startsWith('/')) path = '/$path';

  // Special-case: preserve trailing slash immediately after '>' for patterns like <path|...>/
  // e.g. /foo/<path|[^]*/>
  final trailingPattern = RegExp(r'<[^>]+>/$');
  if (trailingPattern.hasMatch(path)) {
    return path;
  }

  // Remove trailing slash unless root
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  return path;
}
