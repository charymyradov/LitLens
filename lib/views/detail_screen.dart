import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../theme/tokens.dart';
import '../viewmodels/detail_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_cover.dart';
import 'session_screen.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(detailViewModelProvider(book));

    return Scaffold(
      backgroundColor: LzColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                  decoration: const BoxDecoration(
                    color: LzColors.heroCard,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xB3FFFDF8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: LzColors.ink,
                                size: 20,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xB3FFFDF8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_border,
                              color: LzColors.ink,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LzCover(
                        title: book.title,
                        width: 190,
                        height: 285,
                        hero: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.category,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.7,
                          fontWeight: FontWeight.w500,
                          color: LzColors.terracotta,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 34,
                          height: 1.1,
                          letterSpacing: -0.5,
                          color: LzColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 15,
                          color: LzColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: LzColors.divider),
                            bottom: BorderSide(color: LzColors.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            _Stat(value: '${book.pages}', label: 'pages'),
                            _Stat(
                              value: s.statB,
                              label: s.statBLabel,
                              left: true,
                            ),
                            _Stat(
                              value: s.statC,
                              label: s.statCLabel,
                              left: true,
                            ),
                          ],
                        ),
                      ),
                      if (s.reasons.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        const Text(
                          'Why it fits you',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            color: LzColors.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final r in s.reasons)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 14),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: LzColors.dividerSoft,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 7),
                                    decoration: BoxDecoration(
                                      color: r.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.text,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.4,
                                            color: LzColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          r.source.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            letterSpacing: 1.3,
                                            fontWeight: FontWeight.w500,
                                            color: r.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: LzButton(
                label: 'Start reading',
                leading: const Icon(
                  Icons.play_arrow,
                  color: LzColors.cream,
                  size: 16,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SessionScreen(book: book)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.left = false});
  final String value, label;
  final bool left;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.fromLTRB(left ? 14 : 0, 14, 0, 14),
      decoration: BoxDecoration(
        border: left
            ? const Border(left: BorderSide(color: LzColors.divider))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              color: LzColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
          ),
        ],
      ),
    ),
  );
}
