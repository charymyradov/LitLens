import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Placeholder cover — swap for real asset later.
class LzCover extends StatelessWidget {
  const LzCover({
    super.key,
    required this.title,
    required this.width,
    required this.height,
    this.hero = false,
  });
  final String title;
  final double width, height;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    // Deterministic tint from title.
    final hash = title.codeUnits.fold(0, (a, b) => a + b);
    final base = [
      const Color(0xFF6D4E3A),
      const Color(0xFF3E5A7A),
      const Color(0xFF4A6B3E),
      const Color(0xFF8A5A1E),
      const Color(0xFFA4492A),
    ][hash % 5];

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LzRadius.cover),
        boxShadow: hero
            ? const [
                BoxShadow(
                  color: Color(0x4D3C2814),
                  blurRadius: 50,
                  offset: Offset(0, 26),
                ),
                BoxShadow(
                  color: Color(0x333C2814),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x2E3C2814),
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LzRadius.cover),
        child: Container(
          color: base,
          padding: const EdgeInsets.all(14),
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            style: const TextStyle(
              color: LzColors.cream,
              fontFamily: 'serif',
              fontSize: 15,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
