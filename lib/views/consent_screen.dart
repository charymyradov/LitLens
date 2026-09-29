import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/memory_access_controller.dart';
import '../controllers/umbra_controller.dart';
import '../models/memory_item.dart';
import '../models/memory_layer.dart';
import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_toggle.dart';

/// "What can Litlens see?" — everything Umbra holds, item by item.
/// Nothing is used until the user taps the button at the bottom.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  /// Draft choice; null until Umbra's data has loaded.
  Set<String>? _on;
  final _collapsed = <MemoryLayer>{};
  bool _saving = false;

  Future<void> _save(Set<String> on) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(onboardingProvider.notifier)
          .finishConsent(on, ref.read(umbraDataProvider).value);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(umbraErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(memoryItemsProvider);

    return Scaffold(
      backgroundColor: LzColors.bg,
      body: SafeArea(
        child: itemsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: LzColors.ink),
          ),
          error: (e, _) => _Problem(message: umbraErrorMessage(e)),
          data: (items) {
            // Start from the saved choice when re-reviewing, else all on.
            final savedAsync = ref.watch(litlensUserProvider);
            if (_on == null && savedAsync.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: LzColors.ink),
              );
            }
            final saved = savedAsync.value;
            final on = _on ??= saved?.onboarded == true
                ? {...saved!.allowedFields}
                : {for (final i in items) i.id};
            final count = items.where((i) => on.contains(i.id)).length;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 180),
                  children: [
                    const Text(
                      'What can Litlens see?',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 33,
                        height: 1.05,
                        letterSpacing: -0.5,
                        color: LzColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items.isEmpty
                          ? "Your Umbra account doesn't hold anything yet. "
                                'You can still use Litlens and pick topics next.'
                          : 'This is what Umbra knows. Turn off anything '
                                'Litlens shouldn\'t use. Umbra stays the source; '
                                'you can change this later in Profile.',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: LzColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final layer in MemoryLayer.values)
                      if (items.any((i) => i.layer == layer))
                        _Group(
                          layer: layer,
                          items: items.where((i) => i.layer == layer).toList(),
                          on: on,
                          open: !_collapsed.contains(layer),
                          onToggleOpen: () => setState(
                            () => _collapsed.contains(layer)
                                ? _collapsed.remove(layer)
                                : _collapsed.add(layer),
                          ),
                          onChanged: (ids, value) => setState(
                            () => value ? on.addAll(ids) : on.removeAll(ids),
                          ),
                        ),
                  ],
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 30,
                  child: LzButton(
                    label: _saving
                        ? 'Saving…'
                        : count > 0
                        ? 'Use $count of ${items.length} fields'
                        : 'Continue with nothing shared',
                    onPressed: _saving
                        ? null
                        : () => _save({
                            for (final i in items)
                              if (on.contains(i.id)) i.id,
                          }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.layer,
    required this.items,
    required this.on,
    required this.open,
    required this.onToggleOpen,
    required this.onChanged,
  });

  final MemoryLayer layer;
  final List<MemoryItem> items;
  final Set<String> on;
  final bool open;
  final VoidCallback onToggleOpen;
  final void Function(Iterable<String> ids, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final onCount = items.where((i) => on.contains(i.id)).length;
    final allOn = onCount == items.length;

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleOpen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            open ? Icons.expand_more : Icons.chevron_right,
                            size: 14,
                            color: LzColors.inkSoft,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            layer.title,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22,
                              color: layer.color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 22,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: layer.badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              layer.badge.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w500,
                                color: layer.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 4),
                        child: Text(
                          '$onCount of ${items.length} on · ${layer.desc}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: LzColors.inkSoft,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              LzToggle(
                value: allOn,
                partial: onCount > 0 && !allOn,
                onChanged: (v) => onChanged(items.map((i) => i.id), v),
              ),
            ],
          ),
          if (open)
            Container(
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: LzColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    _Row(
                      item: items[i],
                      showTop: i > 0,
                      isOn: on.contains(items[i].id),
                      onChanged: (v) => onChanged([items[i].id], v),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.item,
    required this.showTop,
    required this.isOn,
    required this.onChanged,
  });

  final MemoryItem item;
  final bool showTop;
  final bool isOn;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => onChanged(!isOn),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: showTop
            ? const Border(top: BorderSide(color: LzColors.dividerSoft))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedOpacity(
              opacity: isOn ? 1 : 0.45,
              duration: const Duration(milliseconds: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.field.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.3,
                      color: LzColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      height: 1.2,
                      color: LzColors.ink,
                    ),
                  ),
                  if (item.confidenceLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.confidenceLabel!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LzColors.patterns,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    item.source,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LzColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          LzToggle(value: isOn, onChanged: onChanged),
        ],
      ),
    ),
  );
}

class _Problem extends ConsumerWidget {
  const _Problem({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            height: 1.45,
            color: LzColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        LzButton(
          label: 'Sign out',
          variant: LzButtonVariant.outline,
          height: 48,
          onPressed: () => ref.read(onboardingProvider.notifier).signOut(),
        ),
      ],
    ),
  );
}
