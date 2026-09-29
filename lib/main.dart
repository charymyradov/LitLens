import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'controllers/umbra_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Litlens still runs (blank) if Firebase isn't set up yet.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase unavailable, Umbra disabled: $e');
  }

  final mobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  runApp(
    ProviderScope(
      overrides: [
        firebaseReadyProvider.overrideWithValue(firebaseReady),
        // Umbra's answers to "Continue with Umbra". app_links closes its
        // stream once the last listener leaves (every time the sign-in
        // screen goes away), so each listener asks it for a fresh one.
        if (mobile)
          incomingLinksProvider.overrideWithValue(
            Stream<Uri>.multi((c) {
              final sub = AppLinks().uriLinkStream.listen(
                c.add,
                onError: c.addError,
              );
              c.onCancel = sub.cancel;
            }),
          ),
      ],
      child: const LitlensApp(),
    ),
  );
}
