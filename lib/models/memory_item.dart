import 'memory_layer.dart';

class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.layer,
    required this.field,
    required this.value,
    required this.source,
    this.confidence,
    this.confidenceLabel,
  });

  final String id;
  final MemoryLayer layer;
  final String field;
  final String value;
  final String source;
  final double? confidence;
  final String? confidenceLabel;
}
