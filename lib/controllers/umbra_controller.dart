import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../umbra/umbra_connect.dart';

/// Overridden in main() with whether Firebase.initializeApp succeeded.
final firebaseReadyProvider = Provider<bool>((_) => false);

/// Incoming `litlens://umbra-callback` links. Null where there are none
/// (desktop, tests); set in main().
final incomingLinksProvider = Provider<Stream<Uri>?>((_) => null);

/// Opens the Umbra app (`umbra://`) or Umbra's sign-in page (`https://`,
/// inside Litlens). False when nothing can open it. Replaced in tests.
final openUrlProvider = Provider<Future<bool> Function(Uri)>(
  (_) => (uri) async {
    try {
      return await launchUrl(
        uri,
        mode: uri.scheme == 'https'
            ? LaunchMode.inAppBrowserView
            : LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  },
);

/// Closes Umbra's sign-in page once it has answered (iOS keeps it open).
final closeWebViewProvider = Provider<Future<void> Function()>(
  (_) => () async {
    try {
      await closeInAppWebView();
    } catch (_) {}
  },
);

/// Null when Firebase isn't configured; Litlens then only runs blank.
final umbraConnectProvider = Provider<UmbraConnect?>(
  (ref) => ref.watch(firebaseReadyProvider) ? UmbraConnect() : null,
);

final authUserProvider = StreamProvider<User?>((ref) {
  final umbra = ref.watch(umbraConnectProvider);
  return umbra == null ? Stream.value(null) : umbra.authStateChanges();
});

final _uidProvider = Provider<String?>(
  (ref) => ref.watch(authUserProvider.select((u) => u.value?.uid)),
);

/// What Umbra shares with Litlens (before the user's choice in Litlens is
/// applied). Null = signed out, or Umbra shares nothing.
final umbraDataProvider = StreamProvider<UmbraData?>((ref) {
  final umbra = ref.watch(umbraConnectProvider);
  final uid = ref.watch(_uidProvider);
  if (umbra == null || uid == null) return Stream.value(null);
  return umbra.watchData(uid);
});

/// Litlens's own record at apps/litlens/users/{uid}.
class LitlensUser {
  const LitlensUser({
    this.onboarded = false,
    this.topics = const [],
    this.allowedFields = const {},
  });

  final bool onboarded;

  /// Picked in Litlens's onboarding when Umbra had none.
  final List<String> topics;

  /// Umbra fields the user chose to let Litlens use. Anything Umbra adds
  /// later stays off until the user turns it on.
  final Set<String> allowedFields;

  factory LitlensUser.fromMap(Map<String, dynamic>? m) => LitlensUser(
    onboarded: m?['onboarded'] == true,
    topics: [
      for (final t in (m?['topics'] as List?) ?? const [])
        if (t is String) t,
    ],
    allowedFields: {
      for (final f in (m?['allowedFields'] as List?) ?? const [])
        if (f is String) f,
    },
  );
}

final litlensUserProvider = StreamProvider<LitlensUser?>((ref) {
  final umbra = ref.watch(umbraConnectProvider);
  final uid = ref.watch(_uidProvider);
  if (umbra == null || uid == null) return Stream.value(null);
  return umbra
      .appUserDoc(uid)
      .snapshots()
      .map((s) => LitlensUser.fromMap(s.data()));
});

/// Writes to Litlens's own document and to Umbra's suggestion inbox.
class UmbraActions {
  const UmbraActions(this._umbra);
  final UmbraConnect? _umbra;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = _umbra?.currentUser?.uid;
    return uid == null ? null : _umbra!.appUserDoc(uid);
  }

  /// Saves the consent screen's choice.
  Future<void> setAllowedFields(Iterable<String> ids) async {
    await _doc?.set({
      'allowedFields': ids.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setFieldsAllowed(Iterable<String> ids, bool allowed) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    await _doc?.set({
      'allowedFields': allowed
          ? FieldValue.arrayUnion(list)
          : FieldValue.arrayRemove(list),
    }, SetOptions(merge: true));
  }

  Future<void> markOnboarded({List<String>? topics}) async {
    await _doc?.set({
      'onboarded': true,
      'topics': ?topics,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Disconnect: forget the choice so the next sign-in asks again.
  Future<void> forgetChoice() async {
    await _doc?.set({
      'allowedFields': <String>[],
      'onboarded': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Best effort: a failed suggestion must never block the user.
  Future<void> suggest({
    required String statement,
    required String prompt,
  }) async {
    try {
      await _umbra?.suggestToUmbra(statement: statement, prompt: prompt);
    } catch (e) {
      debugPrint('suggestToUmbra failed: $e');
    }
  }
}

final umbraActionsProvider = Provider<UmbraActions>(
  (ref) => UmbraActions(ref.watch(umbraConnectProvider)),
);

/// User-facing text for an Umbra error.
String umbraErrorMessage(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    error = const UmbraException('no_access');
  }
  if (error is! UmbraException) return "Couldn't reach Umbra. Try again.";
  return switch (error.code) {
    'no_firebase' => "Litlens couldn't start Firebase, so Umbra is off.",
    'umbra_missing' => "Couldn't open Umbra on this phone.",
    'denied' => 'You said no in Umbra, so nothing was shared.',
    'expired' => 'That took too long. Try again.',
    'network' => 'No connection. Check your internet and try again.',
    'no_access' =>
      'Umbra no longer shares anything with Litlens. Connect again '
          'from Umbra to continue.',
    _ => "Couldn't reach Umbra. Try again.",
  };
}
