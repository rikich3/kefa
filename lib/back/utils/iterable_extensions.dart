/// Extension methods for Iterable to add compatibility with newer Dart features
extension IterableExtensions<T> on Iterable<T> {
  /// Returns the first element, or null if the collection is empty.
  /// This is a compatibility method for Dart versions that don't have firstOrNull
  T? get firstOrNullCompat => isEmpty ? null : first;
}
