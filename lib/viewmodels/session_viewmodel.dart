import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

class SessionState {
  const SessionState({
    required this.book,
    required this.elapsed,
    required this.page,
    required this.startPage,
    required this.running,
  });

  final Book book;
  final int elapsed; // seconds
  final int page;
  final int startPage;
  final bool running;

  String get timer {
    final m = (elapsed ~/ 60).toString().padLeft(2, '0');
    final s = (elapsed % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  int get minutes => elapsed < 60 ? 1 : (elapsed / 60).round();
  int get pagesRead => (page - startPage).clamp(0, 1 << 30);
  double get pct => page / book.pages;

  SessionState copyWith({int? elapsed, int? page, bool? running}) =>
      SessionState(
        book: book,
        elapsed: elapsed ?? this.elapsed,
        page: page ?? this.page,
        startPage: startPage,
        running: running ?? this.running,
      );
}

/// State is nullable: no session until [start] is called.
class SessionViewModel extends Notifier<SessionState?> {
  Timer? _t;

  @override
  SessionState? build() {
    ref.onDispose(() => _t?.cancel());
    return null; // nothing to show until the View calls start(book)
  }

  void start(Book book, {int startPage = 1}) {
    _t?.cancel();
    final page = startPage.clamp(1, book.pages);
    state = SessionState(
      book: book,
      elapsed: 0,
      page: page,
      startPage: page,
      running: true,
    );
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      final s = state;
      // Paused sessions shouldn't keep counting.
      if (s != null && s.running) state = s.copyWith(elapsed: s.elapsed + 1);
    });
  }

  void togglePlay() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(running: !s.running);
  }

  void pageUp() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(page: (s.page + 1).clamp(1, s.book.pages));
  }

  void pageDown() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(page: (s.page - 1).clamp(1, s.book.pages));
  }

  void stop() {
    _t?.cancel();
    final s = state;
    if (s != null) state = s.copyWith(running: false);
  }

  void clear() {
    _t?.cancel();
    state = null;
  }
}

final sessionViewModelProvider =
    NotifierProvider<SessionViewModel, SessionState?>(SessionViewModel.new);
