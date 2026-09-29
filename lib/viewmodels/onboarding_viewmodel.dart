import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/umbra_controller.dart';
import '../umbra/umbra_connect.dart';

enum OnboardingStep { starting, welcome, signIn, consent, topics, sync, done }

class OnboardingViewModel extends Notifier<OnboardingStep> {
  @override
  OnboardingStep build() {
    Future.microtask(_restore);
    return OnboardingStep.starting;
  }

  /// Signed in and already chose what to share? Straight into the app.
  Future<void> _restore() async {
    final umbra = ref.read(umbraConnectProvider);
    if (umbra == null) return _go(OnboardingStep.welcome);
    try {
      final user = await umbra.authStateChanges().first;
      if (user == null) return _go(OnboardingStep.welcome);
      // Only sessions opened through "Continue with Umbra" (older builds
      // signed in with the Umbra password, which reaches all of Umbra).
      final claims = (await user.getIdTokenResult()).claims;
      if (claims?['app'] != UmbraConfig.appId) return signOut();
      _go(await _nextAfterSignIn(user.uid));
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        // Disconnected in Umbra while Litlens was closed.
        return signOut();
      }
      // Offline or Firestore hiccup: a signed-in user keeps their app.
      debugPrint('Restoring session failed: $e');
      _go(
        umbra.currentUser == null
            ? OnboardingStep.welcome
            : OnboardingStep.done,
      );
    }
  }

  void openSignIn() => _go(OnboardingStep.signIn);
  void backToWelcome() => _go(OnboardingStep.welcome);
  void startBlank() => _go(OnboardingStep.done);
  void finishSync() => _go(OnboardingStep.done);

  /// Umbra approved and Litlens is signed in as the same user.
  Future<void> signedIn(String uid) async => _go(await _nextAfterSignIn(uid));

  Future<OnboardingStep> _nextAfterSignIn(String uid) async {
    final umbra = ref.read(umbraConnectProvider)!;
    final doc = await umbra.appUserDoc(uid).get();
    return doc.data()?['onboarded'] == true
        ? OnboardingStep.done
        : OnboardingStep.consent;
  }

  /// Consent screen's "Use N fields". Skips the topics question when the
  /// user shared Umbra's reading topics.
  Future<void> finishConsent(Set<String> allowed, UmbraData? data) async {
    final actions = ref.read(umbraActionsProvider);
    await actions.setAllowedFields(allowed);
    final hasTopics =
        data != null && data.canSkipOnboarding && allowed.contains('topics');
    if (hasTopics) {
      await actions.markOnboarded();
      _go(OnboardingStep.sync);
    } else {
      _go(OnboardingStep.topics);
    }
  }

  /// End of the short onboarding: save in Litlens, suggest back to Umbra.
  Future<void> finishTopics(List<String> topics) async {
    final actions = ref.read(umbraActionsProvider);
    await actions.markOnboarded(topics: topics);
    for (final t in topics) {
      // Fire and forget; Umbra shows these as "Is this you?" cards.
      actions.suggest(
        statement: 'Likes reading about $t',
        prompt: 'You picked "$t" while setting up Litlens.',
      );
    }
    _go(OnboardingStep.sync);
  }

  /// Profile → "Change what Litlens can see".
  void reviewConsent() => _go(OnboardingStep.consent);

  /// Forget the choice and sign out.
  Future<void> disconnect() async {
    try {
      await ref.read(umbraActionsProvider).forgetChoice();
    } catch (e) {
      debugPrint('Forgetting choice failed: $e');
    }
    await signOut();
  }

  Future<void> signOut() async {
    await ref.read(umbraConnectProvider)?.signOut();
    _go(OnboardingStep.welcome);
  }

  void _go(OnboardingStep step) {
    if (ref.mounted) state = step;
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingViewModel, OnboardingStep>(
      OnboardingViewModel.new,
    );
