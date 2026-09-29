import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memory_layer.dart';

/// Which memory groups are collapsed on Profile. Deliberately watches
/// nothing, so toggling a field doesn't re-expand every group.
class ProfileViewModel extends Notifier<Set<MemoryLayer>> {
  @override
  Set<MemoryLayer> build() => const {};

  void toggleGroup(MemoryLayer layer) {
    final s = Set<MemoryLayer>.from(state);
    s.contains(layer) ? s.remove(layer) : s.add(layer);
    state = s;
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, Set<MemoryLayer>>(ProfileViewModel.new);
