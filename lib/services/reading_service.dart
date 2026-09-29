import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reading_session.dart';

class ReadingLog {
  const ReadingLog({this.sessions = const [], this.progress = const {}});

  final List<ReadingSession> sessions;

  /// Last page reached, per book id.
  final Map<String, int> progress;

  int progressOf(String bookId) => progress[bookId] ?? 1;

  /// Book ids, most recently read first.
  List<String> get recentBookIds {
    final seen = <String>{};
    return [
      for (final s in sessions.reversed)
        if (seen.add(s.bookId)) s.bookId,
    ];
  }
}

/// Sessions + progress, kept in memory for now.
/// Its own provider so rebuilding a view model never wipes the log.
class ReadingService extends Notifier<ReadingLog> {
  @override
  ReadingLog build() => const ReadingLog();

  void recordSession(ReadingSession s, int page) {
    state = ReadingLog(
      sessions: [...state.sessions, s],
      progress: {...state.progress, s.bookId: page},
    );
  }
}

final readingServiceProvider = NotifierProvider<ReadingService, ReadingLog>(
  ReadingService.new,
);
