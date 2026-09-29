import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:litlens/app.dart';
import 'package:litlens/controllers/memory_access_controller.dart';
import 'package:litlens/models/memory_layer.dart';
import 'package:litlens/services/catalog.dart';
import 'package:litlens/services/recommender.dart';
import 'package:litlens/umbra/umbra_connect.dart';

void main() {
  group('UmbraData.fromShare', () {
    // The document Umbra writes to users/{uid}/shared/litlens.
    final share = {
      'version': 1,
      'app_id': 'litlens',
      'scopes': ['identity.name', 'reading.profile', 'memory.patterns'],
      'profile': {'name': 'Maya Chen', 'first_name': 'Maya'},
      'reading': {
        'topics': ['Science', '', 'History'],
        'goals': <String>[],
        'times': ['Evenings'],
        'formats': ['Audiobook'],
      },
      'memories': {
        'preferences': ['Short chapters'],
        'patterns': [
          {'statement': 'Reads before bed', 'confidence': 1.4},
          {'statement': ''},
        ],
        'live': [
          {
            'statement': 'Flying Saturday',
            'expires_at': '2026-10-04T00:00:00Z',
          },
          {'statement': 'Old news', 'expires_at': '2026-09-01T00:00:00Z'},
        ],
      },
    };

    test('reads each granted section', () {
      final d = UmbraData.fromShare(share, now: DateTime.utc(2026, 9, 28));
      expect(d.firstName, 'Maya');
      expect(d.topics, ['Science', 'History']);
      expect(d.formats, ['Audiobook']);
      expect(d.times, ['Evenings']);
      expect(d.preferences, ['Short chapters']);
      expect(d.patterns.single.text, 'Reads before bed');
      expect(d.patterns.single.confidence, 1.0);
      expect(d.live, ['Flying Saturday']);
      expect(d.canSkipOnboarding, isTrue);
    });

    test('scopes not granted are simply missing', () {
      final d = UmbraData.fromShare({'version': 1, 'app_id': 'litlens'});
      expect(d.firstName, isNull);
      expect(d.topics, isEmpty);
      expect(d.canSkipOnboarding, isFalse);
    });
  });

  group('UmbraAuthRequest', () {
    test('asks Umbra with a PKCE challenge and checks the answer', () {
      final r = UmbraAuthRequest.create(Random(1));
      expect(r.verifier, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
      // RFC 7636 appendix B: base64url(sha256(verifier)).
      expect(
        base64Url
            .encode(sha256.convert(ascii.encode(r.verifier)).bytes)
            .replaceAll('=', ''),
        r.challenge,
      );

      final uri = r.authorizeUri;
      expect(uri.scheme, 'umbra');
      expect(uri.host, 'authorize');
      expect(uri.queryParameters['app'], 'litlens');
      expect(uri.queryParameters['challenge'], r.challenge);
      expect(uri.queryParameters['state'], r.state);
      expect(uri.queryParameters['scopes']!.split(','), UmbraConfig.scopes);

      // Without the Umbra app: the same request on Umbra's sign-in page.
      final web = r.webAuthorizeUri;
      expect('${web.origin}${web.path}', '${UmbraConfig.workerUrl}/authorize');
      expect(web.queryParameters, uri.queryParameters);

      expect(
        r.isAnswer(
          Uri.parse('litlens://umbra-callback?code=x&state=${r.state}'),
        ),
        isTrue,
      );
      expect(
        r.isAnswer(Uri.parse('litlens://umbra-callback?code=x&state=other')),
        isFalse,
      );
      expect(
        r.isAnswer(Uri.parse('evil://umbra-callback?code=x&state=${r.state}')),
        isFalse,
      );
    });
  });

  test('every shared field becomes a toggleable row', () {
    final items = memoryItemsFromUmbra(
      const UmbraData(
        firstName: 'Maya',
        topics: ['fantasy'],
        live: ['Flying Saturday'],
      ),
    );
    expect(items.map((i) => i.id), ['name', 'topics', 'live:Flying Saturday']);
    expect(items.last.layer, MemoryLayer.live);
  });

  test('only chosen fields count', () {
    const access = MemoryAccessState(connected: true, allowed: {'topics'});
    expect(access.isOn('topics'), isTrue);
    expect(access.isOn('name'), isFalse);
  });

  group('recommender', () {
    test('matches synonyms and multi-word topics', () {
      final hailMary = bookById('hailmary')!;
      expect(matchedTopics(hailMary, ['Sci-Fi']), ['Sci-Fi']);
      expect(matchedTopics(bookById('sapiens')!, ['Popular science']), [
        'Popular science',
      ]);
      expect(matchedTopics(hailMary, ['Romance']), isEmpty);
    });

    test('reasons use format and times', () {
      final reasons = reasonsFor(
        bookById('extended')!,
        const Personalization(
          topics: ['psychology'],
          formats: ['Kindle'],
          times: ['Evenings'],
        ),
      );
      expect(reasons.map((r) => r.text), [
        'You read about psychology.',
        'Litlens suggests the e-book edition, your usual format.',
        'Plan it for evenings, when you usually read.',
      ]);
    });
  });

  testWidgets('without Firebase: Continue with Umbra explains, Start blank '
      'opens app', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LitlensApp()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue with Umbra'));
    await tester.tap(find.text('Continue with Umbra'));
    await tester.pumpAndSettle();
    expect(find.text('Continue in Umbra'), findsOneWidget);
    expect(
      find.text("Litlens couldn't start Firebase, so Umbra is off."),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start blank'));
    await tester.tap(find.text('Start blank'));
    await tester.pumpAndSettle();
    expect(find.text('Litlens starts blank.'), findsOneWidget);
  });
}
