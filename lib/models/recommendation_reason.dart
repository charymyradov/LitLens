import 'memory_layer.dart';

import 'package:flutter/material.dart';

class RecommendationReason {
  const RecommendationReason({
    required this.source,
    required this.text,
    required this.layer,
  });

  final String source;
  final String text;
  final MemoryLayer layer;

  Color get color => layer.color;
}
