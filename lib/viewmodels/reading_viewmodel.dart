import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../services/catalog.dart';
import '../services/reading_service.dart';
import '../services/recommender.dart';

class ReadingState {
  const ReadingState({
    required this.sessionCount,
    required this.weekTotal,
    required this.bars,
    required this.goals,
    required this.nightstand,
  });

  final int sessionCount;
  final int weekTotal;
  final List<({String day, double height, bool active})> bars;
  final String? goals;
  final List<({Book book, int pct, String meta})> nightstand;
}

final readingViewModelProvider = Provider<ReadingState>((ref) {
  final log = ref.watch(readingServiceProvider);
  final p = ref.watch(personalizationProvider);

  // Minutes per day for the current Monday–Sunday week.
  final now = DateTime.now();
  final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final week = List<int>.filled(7, 0);
  for (final s in log.sessions) {
    final day = DateTime(s.at.year, s.at.month, s.at.day);
    final i = day.difference(monday).inDays;
    if (i >= 0 && i < 7) week[i] += s.minutes;
  }

  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final bars = [
    for (var i = 0; i < 7; i++)
      (
        day: days[i],
        height: 4 + (week[i] / 30 * 72).clamp(0, 72).toDouble(),
        active: i == now.weekday - 1,
      ),
  ];

  return ReadingState(
    sessionCount: log.sessions.length,
    weekTotal: week.fold(0, (a, b) => a + b),
    bars: bars,
    goals: p.preferences.isEmpty ? null : p.preferences.join('. '),
    nightstand: [
      for (final id in log.recentBookIds)
        if (bookById(id) case final b?)
          (
            book: b,
            pct: (log.progressOf(id) / b.pages * 100).round(),
            meta: 'p. ${log.progressOf(id)} of ${b.pages}',
          ),
    ],
  );
});
