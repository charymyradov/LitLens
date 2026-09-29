import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LzChip extends StatelessWidget {
  const LzChip({super.key, required this.label, required this.dot});
  final String label;
  final Color dot;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: LzColors.surfaceAlt,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: LzColors.ink,
          ),
        ),
      ],
    ),
  );
}
