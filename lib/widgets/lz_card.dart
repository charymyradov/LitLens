import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LzCard extends StatelessWidget {
  const LzCard({
    super.key,
    required this.child,
    this.color = LzColors.surface,
    this.padding = const EdgeInsets.all(18),
    this.radius = LzRadius.card,
    this.onTap,
    this.border,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: child,
    ),
  );
}
