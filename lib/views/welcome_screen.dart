import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_cover.dart';
import '../widgets/lz_fade.dart';
import '../widgets/lz_logo.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: LzColors.bg,
      body: SafeArea(
        // Scrolls on short screens; Spacer still fills tall ones.
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LzFadeIn(
                        child: Row(
                          children: [
                            LzLogo(size: 26),
                            SizedBox(width: 10),
                            Text(
                              'Litlens',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 22,
                                color: LzColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      const _CoverFan(),

                      const Spacer(),

                      const LzFadeUp(
                        delay: Duration(milliseconds: 500),
                        child: Text(
                          'Skip the setup.',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 41,
                            height: 1.1,
                            letterSpacing: -0.8,
                            color: LzColors.ink,
                          ),
                        ),
                      ),
                      const LzFadeUp(
                        delay: Duration(milliseconds: 500),
                        child: Text(
                          'Start reading.',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 41,
                            height: 1.1,
                            letterSpacing: -0.8,
                            fontStyle: FontStyle.italic,
                            color: LzColors.terracotta,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const LzFadeUp(
                        delay: Duration(milliseconds: 600),
                        child: Text(
                          'Litlens knows nothing about you until Umbra fills it in, with your say-so.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: LzColors.inkSoft,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      LzFadeUp(
                        delay: const Duration(milliseconds: 700),
                        child: Column(
                          children: [
                            LzButton(
                              label: 'Continue with Umbra',
                              leading: const UmbraMark(size: 22),
                              onPressed: () => ref
                                  .read(onboardingProvider.notifier)
                                  .openSignIn(),
                            ),
                            const SizedBox(height: 6),
                            LzButton(
                              label: 'Start blank',
                              variant: LzButtonVariant.ghost,
                              height: 48,
                              onPressed: () => ref
                                  .read(onboardingProvider.notifier)
                                  .startBlank(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverFan extends StatelessWidget {
  const _CoverFan();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.topCenter,
        children: const [
          Positioned(
            top: 48,
            child: LzCover(title: 'Klara and the Sun', width: 144, height: 216),
          ),
          Positioned(
            top: 48,
            child: LzCover(
              title: 'The Design of Everyday Things',
              width: 144,
              height: 216,
            ),
          ),
          Positioned(
            top: 10,
            child: LzCover(
              title: 'The Shallows',
              width: 160,
              height: 240,
              hero: true,
            ),
          ),
        ],
      ),
    );
  }
}
