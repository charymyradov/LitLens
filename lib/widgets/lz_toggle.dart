import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class LzToggle extends StatelessWidget {
  const LzToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.partial = false,
    this.width = 48,
    this.height = 30,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool partial;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    final track = value
        ? LzColors.ink
        : partial
        ? LzColors.trackPartial
        : LzColors.trackOff;
    final left = value
        ? width - height + 3
        : partial
        ? (width - height) / 2
        : 3.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: const Cubic(0.3, 1.5, 0.5, 1.0),
              left: left,
              top: 3,
              child: Container(
                width: height - 6,
                height: height - 6,
                decoration: BoxDecoration(
                  color: LzColors.knob,
                  borderRadius: BorderRadius.circular((height - 6) / 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
