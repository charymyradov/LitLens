import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/memory_access_controller.dart';
import '../controllers/umbra_controller.dart';
import '../models/book.dart';
import '../models/memory_layer.dart';
import '../models/recommendation_reason.dart';
import '../umbra/umbra_connect.dart';
import 'catalog.dart';

/// What Litlens may use right now: Umbra's share minus anything the user
/// switched off in Litlens.
class Personalization {
  const Personalization({
    this.firstName,
    this.topics = const [],
    this.formats = const [],
    this.times = const [],
    this.preferences = const [],
    this.patterns = const [],
  });

  final String? firstName;
  final List<String> topics;
  final List<String> formats;
  final List<String> times;
  final List<String> preferences;
  final List<UmbraPattern> patterns;

  /// 'Audiobook', 'E-book' or 'Print', from the first format we recognise.
  String? get preferredFormat {
    for (final f in formats) {
      final s = f.toLowerCase();
      if (s.contains('audio')) return 'Audiobook';
      if (s.contains('e-book') ||
          s.contains('ebook') ||
          s.contains('digital') ||
          s.contains('kindle')) {
        return 'E-book';
      }
      if (s.contains('print') || s.contains('paper') || s.contains('book')) {
        return 'Print';
      }
    }
    return null;
  }
}

final personalizationProvider = Provider<Personalization>((ref) {
  final data = ref.watch(umbraDataProvider).value;
  final localTopics = ref.watch(litlensUserProvider).value?.topics ?? const [];
  if (data == null) return Personalization(topics: localTopics);
  final access = ref.watch(memoryAccessProvider);
  bool on(String id) => access.isOn(id);

  return Personalization(
    firstName: on('name') ? data.firstName : null,
    topics: {if (on('topics')) ...data.topics, ...localTopics}.toList(),
    formats: on('formats') ? data.formats : const [],
    times: on('times') ? data.times : const [],
    preferences: [
      for (final p in data.preferences)
        if (on('pref:$p')) p,
    ],
    patterns: [
      for (final p in data.patterns)
        if (on('pattern:${p.text}')) p,
    ],
  );
});

class Recommendations {
  const Recommendations({this.pick, this.shelf = const []});
  final Book? pick;
  final List<Book> shelf;
}

final recommendationsProvider = Provider<Recommendations>((ref) {
  final p = ref.watch(personalizationProvider);
  if (p.topics.isEmpty) return const Recommendations();

  final scored =
      [
        for (final (i, b) in kCatalog.indexed)
          (book: b, score: matchedTopics(b, p.topics).length, order: i),
      ].where((e) => e.score > 0).toList()..sort(
        (a, b) => b.score != a.score ? b.score - a.score : a.order - b.order,
      );

  if (scored.isEmpty) return const Recommendations();
  return Recommendations(
    pick: scored.first.book,
    shelf: [for (final e in scored.skip(1).take(6)) e.book],
  );
});

/// Why [book] fits, in the user's own words where we have them.
List<RecommendationReason> reasonsFor(Book book, Personalization p) {
  final reasons = <RecommendationReason>[];
  void add(MemoryLayer layer, String text) => reasons.add(
    RecommendationReason(source: layer.title, text: text, layer: layer),
  );

  final matched = matchedTopics(book, p.topics);
  if (matched.isNotEmpty) {
    add(MemoryLayer.prefs, 'You read about ${_list(matched)}.');
  }
  final format = p.preferredFormat;
  if (format != null) {
    add(
      MemoryLayer.prefs,
      'Litlens suggests the ${format.toLowerCase()} edition, your usual format.',
    );
  }
  if (p.times.isNotEmpty) {
    add(
      MemoryLayer.prefs,
      'Plan it for ${p.times.first.toLowerCase()}, when you usually read.',
    );
  }
  final bookWords = {
    ...book.tags.expand(_words),
    ..._words(book.title),
    if (format != null) ..._words(format),
  };
  for (final pref in p.preferences) {
    if (_words(pref).any(bookWords.contains)) {
      add(MemoryLayer.prefs, 'You told Umbra: "$pref"');
    }
  }
  for (final pattern in p.patterns) {
    if (_words(pattern.text).any(bookWords.contains)) {
      add(MemoryLayer.patterns, 'Umbra noticed: ${pattern.text}');
    }
  }
  return reasons;
}

/// The user's topics that [book] covers.
List<String> matchedTopics(Book book, List<String> topics) => [
  for (final t in topics)
    if (_matches(_canonical(t), book.tags)) t,
];

const _synonyms = {
  'sci fi': 'science fiction',
  'scifi': 'science fiction',
  'sf': 'science fiction',
  'self help': 'self improvement',
  'personal growth': 'self improvement',
  'productivity': 'self improvement',
  'ai': 'technology',
  'tech': 'technology',
  'computers': 'technology',
  'finance': 'economics',
  'money': 'economics',
  'novels': 'fiction',
  'literary fiction': 'fiction',
  'literature': 'fiction',
  'thriller': 'mystery',
  'thrillers': 'mystery',
  'crime': 'mystery',
  'memoir': 'biography',
  'memoirs': 'biography',
  'biographies': 'biography',
  'neuroscience': 'psychology',
  'cognitive science': 'psychology',
  'mind': 'psychology',
  'wellness': 'health',
  'climate': 'nature',
  'environment': 'nature',
  'classic': 'classics',
};

String _canonical(String topic) {
  final s = topic
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  return _synonyms[s] ?? s;
}

bool _matches(String topic, List<String> tags) {
  if (topic.isEmpty) return false;
  for (final tag in tags) {
    if (tag == topic) return true;
    // "popular science" ↔ "science", "history of science" ↔ "history".
    if (topic.split(' ').contains(tag) || tag.split(' ').contains(topic)) {
      return true;
    }
  }
  return false;
}

Set<String> _words(String s) => {
  for (final w in s.toLowerCase().split(RegExp(r'[^a-z]+')))
    if (w.length > 3) w,
};

String _list(List<String> xs) => switch (xs.length) {
  1 => xs.first.toLowerCase(),
  2 => '${xs[0].toLowerCase()} and ${xs[1].toLowerCase()}',
  _ =>
    '${xs.take(xs.length - 1).map((x) => x.toLowerCase()).join(', ')} and ${xs.last.toLowerCase()}',
};
