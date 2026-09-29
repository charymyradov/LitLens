import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/umbra_controller.dart';
import '../umbra/umbra_connect.dart';
import 'onboarding_viewmodel.dart';

class SignInState {
  const SignInState({this.waiting = false, this.busy = false, this.error});

  /// Umbra is open; Litlens waits for its answer.
  final bool waiting;

  /// Swapping Umbra's answer for a sign-in.
  final bool busy;
  final Object? error;
}

/// "Continue with Umbra": opens Umbra with a fresh request and signs in
/// when Umbra answers at `litlens://umbra-callback`.
class SignInViewModel extends Notifier<SignInState> {
  UmbraAuthRequest? _request;

  @override
  SignInState build() {
    final sub = ref
        .read(incomingLinksProvider)
        ?.listen(_onLink, onError: (Object _) {});
    ref.onDispose(() => sub?.cancel());
    return const SignInState();
  }

  /// Opens Umbra, which asks the user what Litlens may see: the Umbra app
  /// when it's installed, otherwise Umbra's sign-in page.
  Future<void> openUmbra() async {
    if (state.busy) return;
    if (ref.read(umbraConnectProvider) == null) {
      state = const SignInState(error: UmbraException('no_firebase'));
      return;
    }
    final request = _request = UmbraAuthRequest.create();
    state = const SignInState(waiting: true);
    final open = ref.read(openUrlProvider);
    final opened =
        await open(request.authorizeUri) ||
        (ref.mounted &&
            identical(_request, request) &&
            await open(request.webAuthorizeUri));
    if (!opened && ref.mounted && identical(_request, request)) {
      _request = null;
      state = const SignInState(error: UmbraException('umbra_missing'));
    }
  }

  Future<void> _onLink(Uri uri) async {
    final request = _request;
    final umbra = ref.read(umbraConnectProvider);
    // Only the answer to the request we sent, and only once.
    if (request == null || umbra == null || !request.isAnswer(uri)) return;
    _request = null;
    await ref.read(closeWebViewProvider)();
    if (!ref.mounted) return;
    state = const SignInState(busy: true);
    try {
      final user = await umbra.finishSignIn(request, uri);
      await ref.read(onboardingProvider.notifier).signedIn(user.uid);
    } catch (e) {
      debugPrint('Continue with Umbra failed: $e');
      if (ref.mounted) state = SignInState(error: e);
    }
  }
}

final signInProvider =
    NotifierProvider.autoDispose<SignInViewModel, SignInState>(
      SignInViewModel.new,
    );
