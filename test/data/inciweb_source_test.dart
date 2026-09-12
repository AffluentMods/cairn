// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:cairn/data/sources/inciweb_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final feed = parseInciwebFeed(
      File('test/fixtures/inciweb_rss.xml').readAsStringSync());

  test('feed parses titles and links, upgrading http to https', () {
    expect(feed.length, 5); // the item without a link is skipped
    expect(feed.first.title, 'WAGPF Backbone Fire');
    expect(feed.first.url.toString(),
        'https://inciweb.wildfire.gov/incident-information/wagpf-backbone-fire');
    expect(feed.every((e) => e.url.scheme == 'https'), isTrue);
  });

  test('malformed XML yields an empty feed', () {
    expect(parseInciwebFeed('<rss><channel><item>'), isEmpty);
    expect(parseInciwebFeed(''), isEmpty);
  });

  test('name normalization drops the unit, year, "fire" and punctuation', () {
    expect(normalizeIncidentName('Backbone'), 'backbone');
    expect(normalizeIncidentName('Backbone Fire'), 'backbone');
    expect(normalizeIncidentName('2026 Moonshine Fire'), 'moonshine');
    expect(normalizeIncidentName("Mt. Tom's Creek"), 'mt tom s creek');
    expect(normalizeIncidentName('Cispus Rx'), 'cispus');
  });

  test('unit id breaks ties between same-named fires', () {
    final wa = matchInciweb(feed, name: 'Backbone', unitId: 'WAGPF');
    expect(wa?.url.path, '/incident-information/wagpf-backbone-fire');
    final or = matchInciweb(feed, name: 'Backbone', unitId: 'ORMHF');
    expect(or?.url.path, '/incident-information/ormhf-backbone-fire');
    // Unknown unit: the first name match wins.
    final any = matchInciweb(feed, name: 'Backbone', unitId: 'CAXYZ');
    expect(any?.url.path, '/incident-information/wagpf-backbone-fire');
  });

  test('matches WFIGS names against InciWeb titles', () {
    expect(
      matchInciweb(feed, name: 'Mount Tom Creek', unitId: 'WAOLP')?.url.path,
      '/incident-information/waolp-mount-tom-creek-fire',
    );
    expect(
      matchInciweb(feed, name: 'Moonshine')?.url.path,
      '/incident-information/wywys-2026-moonshine-fire',
    );
    // A title without a unit prefix still matches on the name.
    expect(
      matchInciweb(feed, name: 'Follow', unitId: 'TXTXS')?.url.path,
      '/incident-information/txtxs-follow',
    );
    expect(matchInciweb(feed, name: 'Nonexistent'), isNull);
    expect(matchInciweb(feed, name: '   '), isNull);
  });
}
