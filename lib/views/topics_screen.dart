import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/umbra_controller.dart';
import '../services/catalog.dart';
import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_fade.dart';

/// Short onboarding for when Umbra doesn't know the user's reading topics
/// yet (no reading quiz). Picks are saved in Litlens and suggested to Umbra.
class TopicsScreen extends ConsumerStatefulWidget {
  const TopicsScreen({super.key});

  @override
  ConsumerState<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends ConsumerState<TopicsScreen> {
  final _picked = <String>{};
  bool _saving = false;

  Future<void> _finish(List<String> topics) async {
    setState(() => _saving = true);
    try {
      await ref.read(onboardingProvider.notifier).finishTopics(topics);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save. Check your connection.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(umbraDataProvider).value?.firstName;

    return Scaffold(
      backgroundColor: LzColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 180),
              children: [
                LzFadeUp(
                  child: Text(
                    name == null ? 'Hi there.' : 'Hi, $name.',
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 38,
                      height: 1.1,
                      letterSpacing: -0.76,
                      color: LzColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const LzFadeUp(
                  delay: Duration(milliseconds: 100),
                  child: Text(
                    'What do you like to read about? Pick a few topics. '
                    'Litlens also suggests them to Umbra, so your other '
                    'apps can use them too.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: LzColors.inkSoft,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final t in kTopicOptions)
                      _TopicPill(
                        label: t,
                        selected: _picked.contains(t),
                        onTap: () => setState(
                          () => _picked.contains(t)
                              ? _picked.remove(t)
                              : _picked.add(t),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: Column(
                children: [
                  LzButton(
                    label: _picked.isEmpty
                        ? 'Pick at least one'
                        : 'Continue with ${_picked.length}',
                    onPressed: _picked.isEmpty || _saving
                        ? null
                        : () => _finish(_picked.toList()),
                  ),
                  const SizedBox(height: 6),
                  LzButton(
                    label: 'Skip for now',
                    variant: LzButtonVariant.ghost,
                    height: 48,
                    onPressed: _saving ? null : () => _finish(const []),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicPill extends StatelessWidget {
  const _TopicPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: selected ? LzColors.ink : LzColors.surfaceAlt,
        borderRadius: BorderRadius.circular(19),
      ),
      alignment: Alignment.center,
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: selected ? LzColors.cream : LzColors.ink,
        ),
      ),
    ),
  );
}
