import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../widgets/bottom_tabs.dart';
import 'home_screen.dart';
import 'reading_screen.dart';
import 'profile_screen.dart';

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});
  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  LitlensTab _tab = LitlensTab.today;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LzColors.bg,
      body: Stack(
        children: [
          IndexedStack(
            index: _tab.index,
            children: const [HomeScreen(), ReadingScreen(), ProfileScreen()],
          ),
          BottomTabs(current: _tab, onChanged: (t) => setState(() => _tab = t)),
        ],
      ),
    );
  }
}
