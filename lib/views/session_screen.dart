import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/reading_session.dart';
import '../services/reading_service.dart';
import '../theme/tokens.dart';
import '../viewmodels/session_viewmodel.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.book});
  final Book book;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  @override
  void initState() {
    super.initState();
    // Kick off the session after first frame (can't touch ref in initState directly).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(sessionViewModelProvider.notifier)
          .start(
            widget.book,
            startPage: ref
                .read(readingServiceProvider)
                .progressOf(widget.book.id),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionViewModelProvider);

    // Nothing to show until start() has run.
    if (s == null) {
      return const Scaffold(backgroundColor: LzColors.darkSession);
    }

    return Scaffold(
      backgroundColor: LzColors.darkSession,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(running: s.running, onClose: () => _close(context)),
              const SizedBox(height: 30),
              _BookHeader(book: s.book),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        s.timer,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 89,
                          height: 1.1,
                          letterSpacing: -1.8,
                          color: LzColors.cream,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (_nudge(s) != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: LzColors.creamWarm,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _nudge(s)!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: LzColors.creamMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _PageStepper(
                page: s.page,
                totalPages: s.book.pages,
                onUp: () =>
                    ref.read(sessionViewModelProvider.notifier).pageUp(),
                onDown: () =>
                    ref.read(sessionViewModelProvider.notifier).pageDown(),
              ),
              const SizedBox(height: 14),
              _ProgressBar(pct: s.pct),
              const SizedBox(height: 30),
              _TransportControls(
                running: s.running,
                onToggle: () =>
                    ref.read(sessionViewModelProvider.notifier).togglePlay(),
                onFinish: () => _finish(context, s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Based on sessions logged in Litlens; silent until there are a few.
  String? _nudge(SessionState s) {
    final past = ref.read(readingServiceProvider).sessions;
    if (past.length < 3) return null;
    final usual = (past.fold<int>(0, (a, p) => a + p.minutes) / past.length)
        .round();
    if (s.elapsed < 60) return 'Your usual sitting is $usual min';
    if (s.elapsed > usual * 60) return "You're past your usual sitting";
    return null;
  }

  void _close(BuildContext context) {
    ref.read(sessionViewModelProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  void _finish(BuildContext context, SessionState s) {
    ref.read(sessionViewModelProvider.notifier).stop();
    ref
        .read(readingServiceProvider.notifier)
        .recordSession(
          ReadingSession(
            bookId: s.book.id,
            minutes: s.minutes,
            pagesRead: s.pagesRead,
            at: DateTime.now(),
          ),
          s.page,
        );
    showSessionSummarySheet(
      context,
      minutes: s.minutes,
      pages: s.pagesRead,
      onDone: () {
        ref.read(sessionViewModelProvider.notifier).clear();
        Navigator.of(context).pop();
      },
    );
  }
}

// ---------- Sub-widgets ----------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.running, required this.onClose});
  final bool running;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1AF3ECE0),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: LzColors.cream, size: 18),
          ),
        ),
        const Spacer(),
        Text(
          running ? 'READING' : 'PAUSED',
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.9,
            color: LzColors.creamMuted,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Cover(book: book),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 21,
                  height: 1.05,
                  color: LzColors.cream,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                style: const TextStyle(
                  fontSize: 13,
                  color: LzColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final hash = book.title.codeUnits.fold(0, (a, b) => a + b);
    final base = [
      const Color(0xFF6D4E3A),
      const Color(0xFF3E5A7A),
      const Color(0xFF4A6B3E),
      const Color(0xFF8A5A1E),
      const Color(0xFFA4492A),
    ][hash % 5];

    return Container(
      width: 60,
      height: 90,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
    );
  }
}

class _PageStepper extends StatelessWidget {
  const _PageStepper({
    required this.page,
    required this.totalPages,
    required this.onUp,
    required this.onDown,
  });

  final int page;
  final int totalPages;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x12F3ECE0),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          _StepperButton(label: '−', onTap: onDown),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'PAGE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: LzColors.creamMuted,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 29,
                      height: 1.1,
                      color: LzColors.cream,
                    ),
                    children: [
                      TextSpan(text: '$page'),
                      TextSpan(
                        text: ' / $totalPages',
                        style: const TextStyle(
                          fontSize: 18,
                          color: LzColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _StepperButton(label: '+', onTap: onUp),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33F3ECE0)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            height: 1.0,
            color: LzColors.cream,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.pct});
  final double pct;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct.clamp(0, 1)),
        duration: const Duration(milliseconds: 300),
        builder: (_, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: 3,
          backgroundColor: const Color(0x1FF3ECE0),
          valueColor: const AlwaysStoppedAnimation(LzColors.orange),
        ),
      ),
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({
    required this.running,
    required this.onToggle,
    required this.onFinish,
  });

  final bool running;
  final VoidCallback onToggle;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 64),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: onToggle,
              child: AnimatedScale(
                scale: running ? 1.0 : 1.05,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: LzColors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x59C8663F),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    running ? Icons.pause : Icons.play_arrow,
                    color: LzColors.darkSession,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: GestureDetector(
            onTap: onFinish,
            child: const Text(
              'Finish',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: LzColors.cream),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------- Summary sheet ----------

Future<void> showSessionSummarySheet(
  BuildContext context, {
  required int minutes,
  required int pages,
  required VoidCallback onDone,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x6614100C),
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: LzColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0x2E1F1A15),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Nice sitting.',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 29,
              height: 1.05,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: LzColors.divider),
                bottom: BorderSide(color: LzColors.divider),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Stat(value: '$minutes', label: 'minutes'),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: LzColors.divider)),
                  ),
                  child: _Stat(value: '$pages', label: 'pages'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDone,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: LzColors.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: LzColors.cream,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 26,
            color: LzColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: LzColors.inkSoft),
        ),
      ],
    );
  }
}
