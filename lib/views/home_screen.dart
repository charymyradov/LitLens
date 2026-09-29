import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../theme/tokens.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/lz_card.dart';
import '../widgets/lz_chip.dart';
import '../widgets/lz_cover.dart';
import '../widgets/lz_fade.dart';
import '../widgets/lz_logo.dart';
import 'detail_screen.dart';
import 'session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(homeViewModelProvider);
    final pick = s.pick;
    final continueBook = s.continueBook;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 120),
        children: [
          Row(
            children: [
              Text(
                s.dayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.7,
                  color: LzColors.inkSoft,
                ),
              ),
              const Spacer(),
              if (s.connected)
                const UmbraMark(size: 20)
              else
                const Icon(
                  Icons.person_outline,
                  color: LzColors.inkSoft,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 10),

          LzFadeUp(
            delay: const Duration(milliseconds: 50),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 38,
                  height: 1.1,
                  letterSpacing: -0.76,
                  color: LzColors.ink,
                ),
                children: [
                  TextSpan(text: s.greeting),
                  if (s.greetingName != null)
                    TextSpan(
                      text: ', ${s.greetingName}.',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    )
                  else
                    const TextSpan(text: '.'),
                ],
              ),
            ),
          ),

          if (s.chips.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in s.chips) LzChip(label: c.label, dot: c.dot),
              ],
            ),
          ],

          const SizedBox(height: 24),

          if (pick == null)
            _BlankCard(connected: s.connected)
          else
            _TonightPick(
              book: pick,
              label: s.pickLabel,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DetailScreen(book: pick)),
              ),
            ),

          if (continueBook != null) ...[
            const SizedBox(height: 34),
            const Text(
              'Continue',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                color: LzColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            _ContinueCard(book: continueBook, page: s.continuePage),
          ],

          if (s.shelf.isNotEmpty) ...[
            const SizedBox(height: 34),
            const Text(
              'On your list',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                color: LzColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: s.shelf.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => _ShelfItem(
                  book: s.shelf[i],
                  meta: [
                    _titleCase(s.shelf[i].tags.first),
                    ?s.preferredFormat?.toLowerCase(),
                  ].join(' · '),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _TonightPick extends StatelessWidget {
  const _TonightPick({
    required this.book,
    required this.label,
    required this.onTap,
  });
  final Book book;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LzFadeUp(
    delay: const Duration(milliseconds: 200),
    child: LzCard(
      color: LzColors.heroCard,
      radius: 30,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.7,
              color: LzColors.inkSoft,
            ),
          ),
          const SizedBox(height: 18),
          LzCover(title: book.title, width: 170, height: 255, hero: true),
          const SizedBox(height: 20),
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              height: 1.05,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            style: const TextStyle(fontSize: 14, color: LzColors.inkSoft),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: const Color(0x2E1F1A15)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${book.pages} pages',
                  style: const TextStyle(fontSize: 13, color: LzColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: LzColors.ink,
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Why this',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: LzColors.cream,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BlankCard extends ConsumerWidget {
  const _BlankCard({required this.connected});
  final bool connected;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LzFadeUp(
    delay: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x331F1A15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            connected ? 'Not enough to go on.' : 'Litlens starts blank.',
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              height: 1.05,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            connected
                ? 'Share your reading topics in Umbra to get a pick.'
                : 'No name, no taste, no history. Umbra fills these in once you approve.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: LzColors.inkSoft,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.book, required this.page});
  final Book book;
  final int page;

  @override
  Widget build(BuildContext context) => LzCard(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        LzCover(title: book.title, width: 58, height: 87),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 17,
                  height: 1.1,
                  color: LzColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                book.author,
                style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: page / book.pages,
                  minHeight: 3,
                  backgroundColor: const Color(0x191F1A15),
                  valueColor: const AlwaysStoppedAnimation(LzColors.live),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'p. $page of ${book.pages}',
                style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => SessionScreen(book: book))),
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: LzColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              color: LzColors.cream,
              size: 20,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ShelfItem extends StatelessWidget {
  const _ShelfItem({required this.book, required this.meta});
  final Book book;
  final String meta;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 116,
    child: GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DetailScreen(book: book))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LzCover(title: book.title, width: 116, height: 174),
          const SizedBox(height: 10),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.25,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            meta,
            style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
          ),
        ],
      ),
    ),
  );
}
