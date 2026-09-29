import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// "Continue with Umbra": Litlens opens the Umbra app, the user approves
/// there, and Umbra's auth worker turns that approval into a sign-in as the
/// same user (project umbra-a97d8). Litlens then only sees what Umbra shares
/// with it — no email, no password, no access to the rest of Umbra.
class UmbraConfig {
  UmbraConfig._();

  /// Litlens's id in Umbra. Must match Umbra's `kExternalApps`, the worker's
  /// `APP_SCOPES` and the Firestore rules.
  static const appId = 'litlens';

  /// Umbra's Firestore database is named "default" — not the SDK's
  /// implicit "(default)" — so it must be named explicitly.
  static const databaseId = 'default';

  /// Umbra's token server (`umbra-auth-worker`).
  static const workerUrl = 'https://umbra-auth.oraz-umbra.workers.dev';

  /// Where Umbra sends its answer. Umbra only ever answers at the callback it
  /// has registered for Litlens, so this must match it (and the manifests).
  static const callbackScheme = 'litlens';
  static const callbackHost = 'umbra-callback';

  /// What Litlens asks Umbra for (Umbra's `kScopeCatalog`).
  static const scopes = [
    'identity.name',
    'reading.profile',
    'memory.preferences',
    'memory.patterns',
    'memory.live',
  ];

  /// The one document Umbra shares with Litlens. Read-only; Umbra deletes
  /// it when the user disconnects Litlens.
  static String sharedDoc(String uid) => 'users/$uid/shared/$appId';

  /// Litlens's own data. Nothing Litlens writes lives outside this path
  /// (plus suggestions, which Umbra reviews).
  static String appUserDoc(String uid) => 'apps/$appId/users/$uid';
}

/// Error codes: `umbra_missing`, `denied`, `expired`, `network`,
/// `no_access`, `auth_failed`.
class UmbraException implements Exception {
  const UmbraException(this.code, [this.message]);
  final String code;
  final String? message;

  @override
  String toString() =>
      'UmbraException($code${message == null ? '' : ': $message'})';
}

/// One "Continue with Umbra" attempt (PKCE): the verifier never leaves
/// Litlens, Umbra only sees its hash, and the answer must echo [state].
class UmbraAuthRequest {
  const UmbraAuthRequest._(this.verifier, this.state);

  factory UmbraAuthRequest.create([Random? random]) {
    final r = random ?? Random.secure();
    String token(int bytes) =>
        _b64url([for (var i = 0; i < bytes; i++) r.nextInt(256)]);
    return UmbraAuthRequest._(token(32), token(16));
  }

  /// 43 base64url characters.
  final String verifier;
  final String state;

  String get challenge => _b64url(sha256.convert(ascii.encode(verifier)).bytes);

  Map<String, String> get _query => {
    'app': UmbraConfig.appId,
    'challenge': challenge,
    'scopes': UmbraConfig.scopes.join(','),
    'state': state,
  };

  /// Opens the Umbra app.
  Uri get authorizeUri =>
      Uri(scheme: 'umbra', host: 'authorize', queryParameters: _query);

  /// The same request as a web page, for when the Umbra app isn't installed.
  Uri get webAuthorizeUri => Uri.parse(
    '${UmbraConfig.workerUrl}/authorize',
  ).replace(queryParameters: _query);

  /// Whether [uri] is Umbra's answer to this request.
  bool isAnswer(Uri uri) =>
      uri.scheme == UmbraConfig.callbackScheme &&
      uri.host == UmbraConfig.callbackHost &&
      uri.queryParameters['state'] == state;

  static String _b64url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}

/// What Umbra shares with Litlens, in reading-app terms.
class UmbraData {
  const UmbraData({
    this.firstName,
    this.topics = const [],
    this.formats = const [],
    this.times = const [],
    this.preferences = const [],
    this.patterns = const [],
    this.live = const [],
  });

  final String? firstName;
  final List<String> topics;
  final List<String> formats;
  final List<String> times;
  final List<String> preferences;
  final List<UmbraPattern> patterns;

  /// What's going on for the user right now; each expires on its own.
  final List<String> live;

  /// The reading quiz already told us what they read about.
  bool get canSkipOnboarding => topics.isNotEmpty;

  /// Reads Umbra's share document (`users/{uid}/shared/litlens`):
  /// `profile`, `reading` and `memories`, each present only when the user
  /// granted its scope.
  factory UmbraData.fromShare(Map<String, dynamic> m, {DateTime? now}) {
    final profile = _map(m['profile']);
    final reading = _map(m['reading']);
    final memories = _map(m['memories']);
    final at = now ?? DateTime.now();

    final name = profile['first_name'] ?? profile['name'];
    final firstName = name is String
        ? name.trim().split(RegExp(r'\s+')).first
        : null;

    return UmbraData(
      firstName: firstName == null || firstName.isEmpty ? null : firstName,
      topics: _strings(reading['topics']),
      formats: _strings(reading['formats']),
      times: _strings(reading['times']),
      preferences: _strings(memories['preferences']),
      patterns: [
        for (final p in (memories['patterns'] as List?) ?? const [])
          ?UmbraPattern.tryParse(p),
      ],
      live: [
        for (final l in (memories['live'] as List?) ?? const [])
          if (l is Map && _notExpired(l['expires_at'], at))
            ..._strings([l['statement']]),
      ],
    );
  }
}

/// Something Umbra noticed. [confidence] is 0..1 when Umbra provides it.
class UmbraPattern {
  const UmbraPattern(this.text, {this.confidence});
  final String text;
  final double? confidence;

  static UmbraPattern? tryParse(Object? raw) {
    if (raw is String) {
      return raw.trim().isEmpty ? null : UmbraPattern(raw.trim());
    }
    if (raw is Map) {
      final text = raw['statement'];
      if (text is! String || text.trim().isEmpty) return null;
      final c = raw['confidence'];
      return UmbraPattern(
        text.trim(),
        confidence: c is num ? c.toDouble().clamp(0, 1) : null,
      );
    }
    return null;
  }
}

Map<String, dynamic> _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : const {};

List<String> _strings(Object? raw) => [
  for (final v in raw is List ? raw : const [])
    if (v is String && v.trim().isNotEmpty) v.trim(),
];

bool _notExpired(Object? expiresAt, DateTime now) {
  final t = expiresAt is String ? DateTime.tryParse(expiresAt) : null;
  return t == null || t.isAfter(now);
}

class UmbraConnect {
  UmbraConnect({FirebaseAuth? auth, FirebaseFirestore? db, http.Client? client})
    : _auth = auth ?? FirebaseAuth.instance,
      _db =
          db ??
          FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: UmbraConfig.databaseId,
          ),
      _http = client ?? http.Client();

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final http.Client _http;

  User? get currentUser => _auth.currentUser;

  /// First event is the restored session (or null), then every change.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Swaps Umbra's answer (a one-time code, valid 60 s) for a sign-in as the
  /// same user. The session carries `app: litlens`, so Firestore only lets
  /// it read what Umbra shares.
  Future<User> finishSignIn(UmbraAuthRequest request, Uri answer) async {
    final q = answer.queryParameters;
    if (q['error'] != null) throw UmbraException('denied', q['error']);
    final code = q['code'];
    if (code == null || code.isEmpty) {
      throw const UmbraException('auth_failed', 'no code');
    }

    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse('${UmbraConfig.workerUrl}/token'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'app': UmbraConfig.appId,
              'code': code,
              'verifier': request.verifier,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw UmbraException('network', '$e');
    }
    Object? body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {}
    final token = body is Map ? body['token'] : null;
    if (res.statusCode != 200 || token is! String) {
      final error = body is Map ? body['error'] : null;
      throw UmbraException(
        error == 'invalid_or_expired_code' ? 'expired' : 'auth_failed',
        '${res.statusCode} $error',
      );
    }

    try {
      final cred = await _auth.signInWithCustomToken(token);
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw UmbraException(
        e.code == 'network-request-failed' ? 'network' : 'auth_failed',
        e.message,
      );
    }
  }

  /// Live share. `null` when Umbra shares nothing (e.g. Litlens was
  /// disconnected in Umbra).
  Stream<UmbraData?> watchData(String uid) => _db
      .doc(UmbraConfig.sharedDoc(uid))
      .snapshots()
      .map(_dataFrom)
      .handleError((Object e) {
        if (e is FirebaseException && e.code == 'permission-denied') {
          throw const UmbraException('no_access');
        }
        throw e;
      });

  /// Leaves a suggestion in Umbra; it shows up as an "Is this you?" card
  /// until the user keeps or rejects it.
  Future<void> suggestToUmbra({
    required String statement,
    required String prompt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = _db.collection('events').doc();
    await doc.set({
      'user_id': uid,
      'app_id': UmbraConfig.appId,
      'kind': 'proposal',
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'payload': {
        'pending_id': doc.id,
        'layer': 'preference',
        'statement': statement,
        'prompt': prompt,
        'source': 'crossapp',
        'connection': UmbraConfig.appId,
      },
    });
  }

  DocumentReference<Map<String, dynamic>> appUserDoc(String uid) =>
      _db.doc(UmbraConfig.appUserDoc(uid));

  Future<void> signOut() => _auth.signOut();

  UmbraData? _dataFrom(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data();
    return !snap.exists || data == null ? null : UmbraData.fromShare(data);
  }
}
