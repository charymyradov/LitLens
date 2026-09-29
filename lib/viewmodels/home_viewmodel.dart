import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/memory_access_controller.dart';
import '../models/book.dart';
import '../services/catalog.dart';
import '../services/reading_service.dart';
import '../services/recommender.dart';
import '../theme/tokens.dart';

/// A chip shown under the greeting. A plain data class beats an
/// inline record here — easier to read, and the View can name the type.
class HomeChip {
  const HomeChip({required this.label, required this.dot});
  final String label;
  final Color dot;
}

/// The entire state the Home screen renders. One immutable object,
/// so switching screens or comparing states is trivial.
class HomeState {
  const HomeState({
    required this.connected,
    required this.chips,
    required this.pick,
    required this.shelf,
    required this.preferredFormat,
    required this.continueBook,
    required this.continuePage,
    required this.greetingName,
    required this.now,
  });

  final bool connected;
  final List<HomeChip> chips;
  final Book? pick;
  final List<Book> shelf;
  final String? preferredFormat;
  final Book? continueBook;
  final int continuePage;
  final String? greetingName;
  final DateTime now;

  String get partOfDay => switch (now.hour) {
    >= 5 && < 12 => 'morning',
    >= 12 && < 17 => 'afternoon',
    >= 17 && < 22 => 'evening',
    _ => 'night',
  };

  String get dayLabel {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return '${days[now.weekday - 1]} ${partOfDay.toUpperCase()}';
  }

  String get greeting =>
      partOfDay == 'night' ? 'Good night' : 'Good $partOfDay';

  String get pickLabel =>
      now.hour >= 17 || now.hour < 5 ? "TONIGHT'S PICK" : "TODAY'S PICK";
}

final homeViewModelProvider = Provider<HomeState>((ref) {
  final access = ref.watch(memoryAccessProvider);
  final p = ref.watch(personalizationProvider);
  final recs = ref.watch(recommendationsProvider);
  final log = ref.watch(readingServiceProvider);

  final chips = <HomeChip>[
    for (final t in p.times.take(2))
      HomeChip(label: 'Reads ${t.toLowerCase()}', dot: LzColors.patterns),
    if (p.preferredFormat case final f?)
      HomeChip(label: 'Prefers ${f.toLowerCase()}', dot: LzColors.prefs),
  ];

  // Most recent book that isn't finished yet.
  Book? continueBook;
  for (final id in log.recentBookIds) {
    final b = bookById(id);
    if (b != null && log.progressOf(id) < b.pages) {
      continueBook = b;
      break;
    }
  }

  return HomeState(
    connected: access.connected,
    chips: chips,
    pick: recs.pick,
    shelf: recs.shelf,
    preferredFormat: p.preferredFormat,
    continueBook: continueBook,
    continuePage: continueBook == null ? 0 : log.progressOf(continueBook.id),
    greetingName: p.firstName,
    now: DateTime.now(),
  );
});
