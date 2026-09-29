import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum LitlensTab { today, reading, profile }

class BottomTabs extends StatelessWidget {
  const BottomTabs({super.key, required this.current, required this.onChanged});
  final LitlensTab current;
  final ValueChanged<LitlensTab> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      LitlensTab.today: 'Today',
      LitlensTab.reading: 'Reading',
      LitlensTab.profile: 'Profile',
    };
    return Positioned(
      left: 16,
      right: 16,
      bottom: 26,
      child: Container(
        height: 64,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xD1FBF7EF),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x243C2814),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (final t in LitlensTab.values)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: current == t ? LzColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[t]!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: current == t ? LzColors.cream : LzColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
