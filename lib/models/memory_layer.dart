import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum MemoryLayer {
  identity(
    title: 'Identity',
    badge: 'Stable',
    color: LzColors.identity,
    badgeBg: LzColors.identityBg,
    dashed: false,
    desc: 'Stable facts about you.',
  ),
  prefs(
    title: 'Preferences',
    badge: 'Confirmed',
    color: LzColors.prefs,
    badgeBg: LzColors.prefsBg,
    dashed: false,
    desc: 'What you like, confirmed by you.',
  ),
  patterns(
    title: 'Patterns',
    badge: 'Probable',
    color: LzColors.patterns,
    badgeBg: LzColors.patternsBg,
    dashed: false,
    desc: 'Things Umbra noticed. Estimates, not facts.',
  ),
  live(
    title: 'Live context',
    badge: 'Temporary',
    color: LzColors.live,
    badgeBg: LzColors.liveBg,
    dashed: true,
    desc: "What's happening now. Expires on its own.",
  );

  const MemoryLayer({
    required this.title,
    required this.badge,
    required this.color,
    required this.badgeBg,
    required this.dashed,
    required this.desc,
  });

  final String title;
  final String badge;
  final Color color;
  final Color badgeBg;
  final bool dashed;
  final String desc;
}
