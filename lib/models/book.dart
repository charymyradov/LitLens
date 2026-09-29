class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.pages,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String author;
  final int pages;

  /// Lower-case topics, matched against what Umbra shares.
  final List<String> tags;

  String get category => tags.isEmpty ? '' : tags.first.toUpperCase();

  @override
  bool operator ==(Object other) => other is Book && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
