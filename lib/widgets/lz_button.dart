import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum LzButtonVariant { primary, dark, danger, outline, ghost }

class LzButton extends StatefulWidget {
  const LzButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = LzButtonVariant.primary,
    this.leading,
    this.trailing,
    this.height = 58,
  });

  final String label;
  final VoidCallback? onPressed;
  final LzButtonVariant variant;
  final Widget? leading;
  final Widget? trailing;
  final double height;

  @override
  State<LzButton> createState() => _LzButtonState();
}

class _LzButtonState extends State<LzButton> {
  bool _down = false;

  ({Color bg, Color fg, Border? border}) get _s => switch (widget.variant) {
    LzButtonVariant.primary => (
      bg: LzColors.ink,
      fg: LzColors.cream,
      border: null,
    ),
    LzButtonVariant.dark => (
      bg: LzColors.dark,
      fg: LzColors.cream,
      border: null,
    ),
    LzButtonVariant.danger => (
      bg: LzColors.terracotta,
      fg: LzColors.surface,
      border: null,
    ),
    LzButtonVariant.outline => (
      bg: Colors.transparent,
      fg: LzColors.ink,
      border: Border.all(color: LzColors.divider),
    ),
    LzButtonVariant.ghost => (
      bg: Colors.transparent,
      fg: LzColors.inkSoft,
      border: null,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: s.bg,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: s.border,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: s.fg,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
