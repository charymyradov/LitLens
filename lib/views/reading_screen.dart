import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../theme/tokens.dart';
import '../viewmodels/reading_viewmodel.dart';
import 'session_screen.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(readingViewModelProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
        children: [
          const Text(
            'Reading',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 38,
              height: 1.1,
              letterSpacing: -0.76,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 22),
          _StatsCard(state: s),
          const SizedBox(height: 14),
          _GoalsCard(goals: s.goals),
          const SizedBox(height: 30),
          const Text(
            'On your nightstand',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (s.nightstand.isEmpty)
            _NightstandEmpty()
          else
            for (final b in s.nightstand) ...[
              _NightstandItem(book: b),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.state});
  final ReadingState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: LzColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.sessionCount}',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 55,
                      height: 1.1,
                      color: LzColors.cream,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.sessionCount == 1 ? 'session' : 'sessions',
                    style: const TextStyle(
                      fontSize: 13,
                      color: LzColors.creamMuted,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${state.weekTotal}',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      color: LzColors.cream,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'min this week',
                    style: TextStyle(fontSize: 13, color: LzColors.creamMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < state.bars.length; i++) ...[
                  Expanded(
                    child: _Bar(
                      height: state.bars[i].height,
                      active: state.bars[i].active,
                      label: state.bars[i].day,
                    ),
                  ),
                  if (i < state.bars.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            state.sessionCount == 0
                ? 'No sessions yet. Litlens only logs what you read here.'
                : 'Tracked by Litlens',
            style: const TextStyle(fontSize: 12, color: LzColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.active, required this.label});

  final double height;
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: height),
          duration: const Duration(milliseconds: 700),
          curve: const Cubic(0.2, 0.9, 0.3, 1.0),
          builder: (_, h, _) => Container(
            width: double.infinity,
            height: h,
            decoration: BoxDecoration(
              color: active ? LzColors.orange : const Color(0x2EF3ECE0),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: LzColors.creamMuted),
        ),
      ],
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});
  final String? goals;

  @override
  Widget build(BuildContext context) {
    final on = goals != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: on ? LzColors.divider : const Color(0x331F1A15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HOW YOU LIKE TO READ',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.3,
              color: LzColors.inkSoft,
            ),
          ),
          const SizedBox(height: 6),
          if (on)
            Text(
              goals!,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                height: 1.2,
                color: LzColors.ink,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: LzColors.inkWash,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'From Umbra',
                  style: TextStyle(fontSize: 12, color: LzColors.inkSoft),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NightstandEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x2E1F1A15)),
      ),
      child: const Text(
        'Nothing yet. Books you start in Litlens show up here.',
        style: TextStyle(fontSize: 14, height: 1.45, color: LzColors.inkSoft),
      ),
    );
  }
}

class _NightstandItem extends StatelessWidget {
  const _NightstandItem({required this.book});
  final ({Book book, int pct, String meta}) book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LzColors.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _MiniCover(title: book.book.title),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.book.title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    height: 1.1,
                    color: LzColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: book.pct / 100,
                    minHeight: 3,
                    backgroundColor: const Color(0x191F1A15),
                    valueColor: const AlwaysStoppedAnimation(
                      LzColors.terracotta,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  book.meta,
                  style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SessionScreen(book: book.book)),
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: LzColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: LzColors.cream,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCover extends StatelessWidget {
  const _MiniCover({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final hash = title.codeUnits.fold(0, (a, b) => a + b);
    final base = [
      const Color(0xFF6D4E3A),
      const Color(0xFF3E5A7A),
      const Color(0xFF4A6B3E),
      const Color(0xFF8A5A1E),
      const Color(0xFFA4492A),
    ][hash % 5];

    return Container(
      width: 52,
      height: 78,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x333C2814),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
    );
  }
}
