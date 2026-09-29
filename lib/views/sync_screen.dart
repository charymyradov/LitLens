import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/memory_access_controller.dart';
import '../models/memory_item.dart';
import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/lz_fade.dart';
import '../widgets/lz_logo.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});
  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        ref.read(onboardingProvider.notifier).finishSync();
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(memoryAccessProvider);
    final items = ref
        .watch(memoryItemsProvider)
        .maybeWhen(
          data: (v) => v.where((i) => access.isOn(i.id)).toList(),
          orElse: () => const <MemoryItem>[],
        );

    return Scaffold(
      backgroundColor: LzColors.dark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _spin,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0x66E8D9BF),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(child: UmbraMark(size: 70)),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                items.isEmpty
                    ? 'Setting up Litlens'
                    : 'Filling ${items.length} '
                          '${items.length == 1 ? 'field' : 'fields'}',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  color: LzColors.cream,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 26),
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LzFadeUp(
                    delay: Duration(milliseconds: 300 + i * 200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        SizedBox(
                          width: 108,
                          child: Text(
                            items[i].field.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.3,
                              color: LzColors.inkFaint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            items[i].value,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 15,
                              color: LzColors.cream,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
