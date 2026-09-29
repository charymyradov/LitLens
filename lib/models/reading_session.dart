class ReadingSession {
  const ReadingSession({
    required this.bookId,
    required this.minutes,
    required this.pagesRead,
    required this.at,
  });

  final String bookId;
  final int minutes;
  final int pagesRead;
  final DateTime at;
}
