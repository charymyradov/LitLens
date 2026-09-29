import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/recommendation_reason.dart';
import '../services/recommender.dart';

class DetailState {
  const DetailState({
    required this.book,
    required this.reasons,
    required this.statB,
    required this.statBLabel,
    required this.statC,
    required this.statCLabel,
  });
  final Book book;
  final List<RecommendationReason> reasons;
  final String statB, statBLabel, statC, statCLabel;
}

final detailViewModelProvider = Provider.family<DetailState, Book>((ref, book) {
  final p = ref.watch(personalizationProvider);
  final format = p.preferredFormat;
  // ~1.5 min a page is a typical adult reading pace.
  final hours = (book.pages * 1.5 / 60).round();

  return DetailState(
    book: book,
    reasons: reasonsFor(book, p),
    statB: '$hours h',
    statBLabel: 'to read',
    statC: format ?? 'Book',
    statCLabel: format == null ? 'format' : 'your format',
  );
});
