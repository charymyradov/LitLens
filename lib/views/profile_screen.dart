import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/memory_access_controller.dart';
import '../controllers/umbra_controller.dart';
import '../models/memory_item.dart';
import '../models/memory_layer.dart';
import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_logo.dart';
import '../widgets/lz_toggle.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(memoryAccessProvider);
    final collapsed = ref.watch(profileViewModelProvider);
    final signedIn = ref.watch(authUserProvider).value != null;
    final itemsAsync = ref.watch(memoryItemsProvider);

    return SafeArea(
      child: itemsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: LzColors.ink)),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final onCount = items.where((i) => access.isOn(i.id)).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Your profile',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 38,
                    height: 1.1,
                    letterSpacing: -0.76,
                    color: LzColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (access.connected)
                _ConnectionCard(count: onCount, total: items.length)
              else
                _DisconnectedCard(signedIn: signedIn),

              for (final layer in MemoryLayer.values)
                if (items.any((i) => i.layer == layer))
                  _ProfileGroupSection(
                    layer: layer,
                    items: items.where((i) => i.layer == layer).toList(),
                    access: access,
                    open: !collapsed.contains(layer),
                  ),

              if (signedIn) ...[
                const SizedBox(height: 32),
                if (items.isNotEmpty) ...[
                  LzButton(
                    label: 'Review what Litlens can see',
                    variant: LzButtonVariant.outline,
                    height: 52,
                    onPressed: () =>
                        ref.read(onboardingProvider.notifier).reviewConsent(),
                  ),
                  const SizedBox(height: 10),
                ],
                const _DisconnectButton(),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Litlens forgets your choice and signs out. '
                    'Your data stays in Umbra.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: LzColors.inkSoft),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.count, required this.total});

  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LzColors.dark,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const UmbraMark(size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filled by Umbra',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 21,
                    height: 1.1,
                    color: LzColors.cream,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Litlens uses $count of $total fields',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LzColors.creamMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisconnectedCard extends ConsumerWidget {
  const _DisconnectedCard({required this.signedIn});
  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x331F1A15), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            signedIn ? 'Umbra has nothing yet.' : 'Every field is blank.',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 21,
              height: 1.05,
              color: LzColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            signedIn
                ? 'Once your Umbra account holds data, you can choose what '
                      'Litlens uses here.'
                : "Litlens doesn't ask you to fill these in. Umbra does it, "
                      'once you approve.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: LzColors.inkSoft,
            ),
          ),
          if (!signedIn) ...[
            const SizedBox(height: 16),
            LzButton(
              label: 'Connect Umbra',
              variant: LzButtonVariant.dark,
              height: 48,
              leading: const UmbraMark(size: 18),
              onPressed: () =>
                  ref.read(onboardingProvider.notifier).openSignIn(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileGroupSection extends ConsumerWidget {
  const _ProfileGroupSection({
    required this.layer,
    required this.items,
    required this.access,
    required this.open,
  });

  final MemoryLayer layer;
  final List<MemoryItem> items;
  final MemoryAccessState access;
  final bool open;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onCount = items.where((i) => access.isOn(i.id)).length;
    final allOn = onCount == items.length && access.connected;
    final actions = ref.read(umbraActionsProvider);

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
                  onTap: () => ref
                      .read(profileViewModelProvider.notifier)
                      .toggleGroup(layer),
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
                          Flexible(
                            child: Text(
                              layer.title,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 22,
                                color: layer.color,
                              ),
                              overflow: TextOverflow.ellipsis,
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
                          access.connected
                              ? '$onCount of ${items.length}'
                              : 'Blank',
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
              if (access.connected)
                LzToggle(
                  value: allOn,
                  partial: onCount > 0 && !allOn,
                  onChanged: (v) =>
                      actions.setFieldsAllowed(items.map((i) => i.id), v),
                ),
            ],
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: LzColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: layer.dashed
                      ? Border.all(color: const Color(0x664A6B3E))
                      : null,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _ProfileItemRow(
                        item: items[i],
                        showTop: i > 0,
                        isOn: access.isOn(items[i].id),
                        connected: access.connected,
                        showToggle: access.connected,
                        onTap: () {
                          if (!access.connected) return;
                          actions.setFieldsAllowed([
                            items[i].id,
                          ], !access.isOn(items[i].id));
                        },
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileItemRow extends StatelessWidget {
  const _ProfileItemRow({
    required this.item,
    required this.showTop,
    required this.isOn,
    required this.connected,
    required this.showToggle,
    required this.onTap,
  });

  final MemoryItem item;
  final bool showTop;
  final bool isOn;
  final bool connected;
  final bool showToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final filled = connected && isOn;

    return GestureDetector(
      onTap: onTap,
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
                  const SizedBox(height: 4),
                  if (filled) ...[
                    Text(
                      item.value,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        height: 1.2,
                        color: LzColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.source,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LzColors.inkSoft,
                      ),
                    ),
                  ] else
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
                        Text(
                          connected ? 'Not shared' : 'From Umbra',
                          style: const TextStyle(
                            fontSize: 12,
                            color: LzColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (showToggle) ...[
              const SizedBox(width: 14),
              LzToggle(value: isOn, onChanged: (_) => onTap()),
            ],
          ],
        ),
      ),
    );
  }
}

class _DisconnectButton extends ConsumerWidget {
  const _DisconnectButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => ref.read(onboardingProvider.notifier).disconnect(),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0x66A4492A)),
        ),
        alignment: Alignment.center,
        child: const Text(
          'Disconnect Umbra',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: LzColors.terracotta,
          ),
        ),
      ),
    );
  }
}
