import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory_item.dart';
import '../models/memory_layer.dart';
import '../umbra/umbra_connect.dart';
import 'umbra_controller.dart';

/// Which Umbra fields Litlens may use: only the ones the user picked.
class MemoryAccessState {
  const MemoryAccessState({required this.connected, required this.allowed});

  final bool connected;
  final Set<String> allowed;

  bool isOn(String id) => connected && allowed.contains(id);
  int countOn(List<MemoryItem> items) => items.where((i) => isOn(i.id)).length;
}

final memoryAccessProvider = Provider<MemoryAccessState>((ref) {
  final user = ref.watch(litlensUserProvider).value;
  return MemoryAccessState(
    connected: ref.watch(umbraDataProvider).value != null,
    allowed: user?.onboarded == true ? user!.allowedFields : const {},
  );
});

/// Everything Umbra shares, as rows the consent screen and Profile can
/// show and toggle.
final memoryItemsProvider = Provider<AsyncValue<List<MemoryItem>>>(
  (ref) => ref
      .watch(umbraDataProvider)
      .whenData((data) => data == null ? const [] : memoryItemsFromUmbra(data)),
);

const _fromUmbra = 'From Umbra';

List<MemoryItem> memoryItemsFromUmbra(UmbraData data) => [
  if (data.firstName != null)
    MemoryItem(
      id: 'name',
      layer: MemoryLayer.identity,
      field: 'First name',
      value: data.firstName!,
      source: _fromUmbra,
    ),
  if (data.topics.isNotEmpty)
    MemoryItem(
      id: 'topics',
      layer: MemoryLayer.prefs,
      field: 'Reading topics',
      value: data.topics.join(', '),
      source: _fromUmbra,
    ),
  if (data.formats.isNotEmpty)
    MemoryItem(
      id: 'formats',
      layer: MemoryLayer.prefs,
      field: 'Formats',
      value: data.formats.join(', '),
      source: _fromUmbra,
    ),
  if (data.times.isNotEmpty)
    MemoryItem(
      id: 'times',
      layer: MemoryLayer.prefs,
      field: 'Reading times',
      value: data.times.join(', '),
      source: _fromUmbra,
    ),
  for (final p in data.preferences)
    MemoryItem(
      id: 'pref:$p',
      layer: MemoryLayer.prefs,
      field: 'Preference',
      value: p,
      source: _fromUmbra,
    ),
  for (final p in data.patterns)
    MemoryItem(
      id: 'pattern:${p.text}',
      layer: MemoryLayer.patterns,
      field: 'Noticed',
      value: p.text,
      confidence: p.confidence,
      confidenceLabel: p.confidence == null
          ? null
          : '${(p.confidence! * 100).round()}% confident',
      source: _fromUmbra,
    ),
  for (final l in data.live)
    MemoryItem(
      id: 'live:$l',
      layer: MemoryLayer.live,
      field: 'Right now',
      value: l,
      source: _fromUmbra,
    ),
];
