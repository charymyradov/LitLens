import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/umbra_controller.dart';
import '../theme/tokens.dart';
import '../viewmodels/onboarding_viewmodel.dart';
import '../viewmodels/sign_in_viewmodel.dart';
import '../widgets/lz_button.dart';
import '../widgets/lz_fade.dart';
import '../widgets/lz_logo.dart';

/// "Continue with Umbra": Umbra opens, the user approves there, and Litlens
/// signs in as the same user when Umbra hands back.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  @override
  void initState() {
    super.initState();
    // One tap: arriving here opens Umbra.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(signInProvider.notifier).openUmbra();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(signInProvider);
    final error = s.error;

    return Scaffold(
      backgroundColor: LzColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: s.busy
                    ? null
                    : () =>
                          ref.read(onboardingProvider.notifier).backToWelcome(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: LzColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: LzColors.ink,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            const LzFadeUp(child: UmbraMark(size: 44, bg: LzColors.bg)),
            const SizedBox(height: 20),
            LzFadeUp(
              delay: const Duration(milliseconds: 80),
              child: Text(
                s.busy ? 'Signing in…' : 'Continue in Umbra',
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 33,
                  height: 1.05,
                  letterSpacing: -0.5,
                  color: LzColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Umbra opens (the app, or its sign-in page if the app isn't "
              'installed) and shows exactly what Litlens asks for. Tap Allow '
              "there and you're back here, signed in.",
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: LzColors.inkSoft,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                umbraErrorMessage(error),
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: LzColors.terracotta,
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (s.busy)
              const Center(
                child: CircularProgressIndicator(color: LzColors.ink),
              )
            else
              LzButton(
                label: s.waiting ? 'Open Umbra again' : 'Open Umbra',
                leading: const UmbraMark(size: 22),
                onPressed: () => ref.read(signInProvider.notifier).openUmbra(),
              ),
          ],
        ),
      ),
    );
  }
}
