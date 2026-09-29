import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'controllers/umbra_controller.dart';
import 'theme/tokens.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'views/consent_screen.dart';
import 'views/sign_in_screen.dart';
import 'views/welcome_screen.dart';
import 'views/topics_screen.dart';
import 'views/sync_screen.dart';
import 'views/shell.dart';
import 'widgets/lz_logo.dart';

class LitlensApp extends ConsumerWidget {
  const LitlensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingProvider);

    // Umbra deleted this user's data while signed in → sign out.
    ref.listen(umbraDataProvider, (prev, next) {
      final hadData = prev?.value != null;
      final gone = next.hasValue && next.value == null;
      final signedIn = ref.read(authUserProvider).value != null;
      if (hadData && gone && signedIn) {
        ref.read(onboardingProvider.notifier).signOut();
      }
    });

    return MaterialApp(
      title: 'Litlens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: LzColors.bg,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
      ),
      home: switch (step) {
        OnboardingStep.starting => const _Splash(),
        OnboardingStep.welcome => const WelcomeScreen(),
        OnboardingStep.signIn => const SignInScreen(),
        OnboardingStep.consent => const ConsentScreen(),
        OnboardingStep.topics => const TopicsScreen(),
        OnboardingStep.sync => const SyncScreen(),
        OnboardingStep.done => const Shell(),
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: LzColors.bg,
    body: Center(child: LzLogo(size: 40)),
  );
}
