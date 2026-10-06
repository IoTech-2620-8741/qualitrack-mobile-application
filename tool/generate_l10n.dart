// Generates lib/shared/presentation/l10n/app_localizations.dart from l10n/strings.tsv.
//
// Columns: key, English, Spanish, optional placeholders ("name:type,name:type").
// Run from the project root:  dart run tool/generate_l10n.dart
import 'dart:io';

void main() {
  final root = File(Platform.script.toFilePath()).parent.parent;
  final source = File('${root.path}/l10n/strings.tsv');
  final target = File('${root.path}/lib/shared/presentation/l10n/app_localizations.dart');

  final rows = <({String key, String en, String es, List<(String, String)> params})>[];
  for (final line in source.readAsLinesSync()) {
    if (line.trim().isEmpty || line.startsWith('#')) continue;
    final cols = line.split('\t');
    final params = cols.length > 3 && cols[3].trim().isNotEmpty
        ? [
            for (final p in cols[3].split(','))
              (p.split(':')[0], p.split(':')[1]),
          ]
        : <(String, String)>[];
    for (final text in [cols[1], cols[2]]) {
      final found = RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();
      final expected = params.map((p) => p.$1).toSet();
      if (found.length != expected.length || !found.containsAll(expected)) {
        stderr.writeln('Placeholder mismatch in "${cols[0]}": $found vs $expected');
        exit(1);
      }
    }
    rows.add((key: cols[0], en: cols[1], es: cols[2], params: params));
  }

  final keys = rows.map((r) => r.key).toList();
  if (keys.length != keys.toSet().length) {
    stderr.writeln('Duplicated keys in strings.tsv');
    exit(1);
  }

  final out = <String>[
    '// GENERATED CODE - DO NOT MODIFY BY HAND.',
    '// Source: l10n/strings.tsv — regenerate with `dart run tool/generate_l10n.dart`.',
    '',
    "import 'package:flutter/foundation.dart';",
    "import 'package:flutter/widgets.dart';",
    '',
    '/// Localized strings for English (default) and Spanish.',
    'class AppLocalizations {',
    '  AppLocalizations(this.locale)',
    "    : _values = locale.languageCode == 'es' ? _es : _en;",
    '',
    '  final Locale locale;',
    '  final Map<String, String> _values;',
    '',
    "  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];",
    '',
    '  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();',
    '',
    '  static AppLocalizations of(BuildContext context) {',
    '    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);',
    "    assert(value != null, 'AppLocalizations.delegate is not registered');",
    '    return value!;',
    '  }',
    '',
    '  /// English is used for any unsupported device language.',
    '  static Locale resolve(Locale? locale, Iterable<Locale> supported) {',
    '    for (final candidate in supported) {',
    '      if (candidate.languageCode == locale?.languageCode) return candidate;',
    '    }',
    "    return const Locale('en');",
    '  }',
    '',
    '  @visibleForTesting',
    '  static Set<String> get englishKeys => _en.keys.toSet();',
    '',
    '  @visibleForTesting',
    '  static Set<String> get spanishKeys => _es.keys.toSet();',
    '',
    '  String _t(String key) => _values[key] ?? _en[key] ?? key;',
    '',
  ];
  for (final row in rows) {
    if (row.params.isEmpty) {
      out.add("  String get ${row.key} => _t('${row.key}');");
      continue;
    }
    final signature = row.params.map((p) => '${p.$2} ${p.$1}').join(', ');
    out.add("  String ${row.key}($signature) => _t('${row.key}')");
    for (final (name, type) in row.params) {
      final value = type == 'String' ? name : "'\$$name'";
      out.add("      .replaceAll('{$name}', $value)");
    }
    out[out.length - 1] = '${out.last};';
  }
  out.add('}');
  out.add('');
  for (final (name, english) in [('_en', true), ('_es', false)]) {
    out.add('const Map<String, String> $name = {');
    for (final row in rows) {
      final text = (english ? row.en : row.es)
          .replaceAll(r'\', r'\\')
          .replaceAll("'", r"\'")
          .replaceAll(r'$', r'\$');
      out.add("  '${row.key}': '$text',");
    }
    out.add('};');
    out.add('');
  }
  out.addAll([
    'class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {',
    '  const _AppLocalizationsDelegate();',
    '',
    '  @override',
    "  bool isSupported(Locale locale) => const ['en', 'es'].contains(locale.languageCode);",
    '',
    '  @override',
    '  Future<AppLocalizations> load(Locale locale) =>',
    '      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));',
    '',
    '  @override',
    '  bool shouldReload(_AppLocalizationsDelegate old) => false;',
    '}',
    '',
    'extension AppLocalizationsX on BuildContext {',
    '  AppLocalizations get l10n => AppLocalizations.of(this);',
    '}',
  ]);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync('${out.join('\n')}\n');
  stdout.writeln('Generated lib/shared/presentation/l10n/app_localizations.dart with ${rows.length} keys');
}
