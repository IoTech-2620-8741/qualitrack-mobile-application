import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the layer rules of the Flutter DDD guide (see docs/architecture.md):
///  - domain depends on nothing; application and infrastructure on the domain;
///    presentation on the application (and the domain entities it shows);
///  - a bounded context uses another one only through its `api/index.dart`;
///  - `shared/` (the guide's `common`) depends on no bounded context;
///  - only `app/` (the composition root) and `main.dart` may know everything.
const _layers = {'domain', 'application', 'infrastructure', 'presentation', 'api'};

/// Layers a layer may import, inside its context and from `shared/`.
const _mayImport = {
  'domain': {'domain'},
  'application': {'domain', 'application'},
  'infrastructure': {'domain', 'infrastructure'},
  'presentation': {'domain', 'application', 'presentation'},
  'api': {'domain', 'application', 'api'},
};

/// External packages a layer may use; layers not listed here are not limited.
const _onlyPackages = {
  'domain': {'equatable'},
  'application': {'equatable'},
  'api': {'equatable'},
};

const _forbiddenPackages = {
  'infrastructure': {'flutter', 'flutter_bloc', 'go_router', 'get_it'},
  'presentation': {'dio', 'flutter_secure_storage'},
};

/// Why [uri], imported by the file at [from] (path segments under `lib/`), breaks
/// a rule; null when it is allowed.
String? checkImport(List<String> from, String uri) {
  if (uri.startsWith('dart:')) {
    final blocked = uri == 'dart:ui' || uri == 'dart:io';
    return blocked && _onlyPackages.containsKey(from[1]) ? 'the ${from[1]} layer must stay pure Dart' : null;
  }
  final context = from[0];
  final layer = from[1];
  if (uri.startsWith('package:') && !uri.startsWith('package:qualitrack_mobile/')) {
    final package = uri.substring(8).split('/').first;
    final only = _onlyPackages[layer];
    if (only != null && !only.contains(package)) return 'the $layer layer must not use package:$package';
    if (_forbiddenPackages[layer]?.contains(package) ?? false) return 'the $layer layer must not use package:$package';
    return null;
  }

  final target = uri.startsWith('package:qualitrack_mobile/')
      ? uri.substring('package:qualitrack_mobile/'.length).split('/')
      : _resolve(from.sublist(0, from.length - 1), uri);
  final targetContext = target[0];
  final targetLayer = target.length > 2 ? target[1] : '';

  if (targetContext == 'app') return 'only app/ may import app/';
  if (targetContext == context || targetContext == 'shared') {
    if (!_layers.contains(targetLayer)) return null; // e.g. shared/presentation/theme is under presentation anyway
    if (targetContext == 'shared' && context == 'shared' && targetLayer == layer) return null;
    return _mayImport[layer]!.contains(targetLayer) ? null : 'the $layer layer must not import the $targetLayer layer';
  }
  if (context == 'shared') return 'shared/ must not depend on a bounded context ($targetContext)';
  if (layer != 'application' && layer != 'presentation') return 'the $layer layer must not import another context';
  final isEntryPoint = target.length == 3 && target[1] == 'api' && target[2] == 'index.dart';
  return isEntryPoint ? null : 'use $targetContext/api/index.dart instead of its internals';
}

List<String> _resolve(List<String> dir, String relative) {
  final parts = [...dir];
  for (final part in relative.split('/')) {
    if (part == '..') {
      parts.removeLast();
    } else if (part != '.') {
      parts.add(part);
    }
  }
  return parts;
}

void main() {
  test('the layer rules hold in lib/', () {
    final directive = RegExp(r"^(?:import|export)\s+'([^']+)'", multiLine: true);
    final problems = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final segments = entity.uri.pathSegments.skipWhile((s) => s != 'lib').skip(1).toList();
      if (segments.length < 3 || segments[0] == 'app' || !_layers.contains(segments[1])) continue;
      for (final match in directive.allMatches(entity.readAsStringSync())) {
        final reason = checkImport(segments, match.group(1)!);
        if (reason != null) problems.add('${segments.join('/')}: ${match.group(1)} -> $reason');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  group('the checker', () {
    test('rejects what the guide forbids', () {
      expect(checkImport(['equipment', 'domain', 'a.dart'], 'package:flutter/material.dart'), isNotNull);
      expect(checkImport(['equipment', 'domain', 'a.dart'], '../../tracking/api/index.dart'), isNotNull);
      expect(checkImport(['equipment', 'application', 'a.dart'], '../presentation/b.dart'), isNotNull);
      expect(checkImport(['equipment', 'presentation', 'a.dart'], '../infrastructure/b.dart'), isNotNull);
      expect(checkImport(['equipment', 'presentation', 'pages', 'a.dart'], '../../../tracking/domain/t.dart'), isNotNull);
      expect(checkImport(['shared', 'presentation', 'a.dart'], '../../batch/api/index.dart'), isNotNull);
      expect(checkImport(['equipment', 'presentation', 'a.dart'], 'package:qualitrack_mobile/app/app.dart'), isNotNull);
    });

    test('accepts what the guide allows', () {
      expect(checkImport(['equipment', 'presentation', 'pages', 'a.dart'], '../../../tracking/api/index.dart'), isNull);
      expect(checkImport(['equipment', 'application', 'a.dart'], '../../shared/domain/failure.dart'), isNull);
      expect(checkImport(['equipment', 'infrastructure', 'a.dart'], '../../shared/infrastructure/http/api_client.dart'), isNull);
      expect(checkImport(['equipment', 'domain', 'a.dart'], 'package:equatable/equatable.dart'), isNull);
      expect(checkImport(['equipment', 'presentation', 'a.dart'], '../application/b.dart'), isNull);
    });
  });
}
