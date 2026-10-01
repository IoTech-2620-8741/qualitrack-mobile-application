#!/usr/bin/env python3
"""Generates lib/shared/presentation/l10n/app_localizations.dart from l10n/strings.tsv.

Columns: key, English, Spanish, optional placeholders ("name:type,name:type").
Run from the project root:  python tool/generate_l10n.py
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'l10n' / 'strings.tsv'
TARGET = ROOT / 'lib' / 'shared' / 'presentation' / 'l10n' / 'app_localizations.dart'




def main() -> None:
    rows = []
    for line in SOURCE.read_text(encoding='utf-8').splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        cols = line.split('\t')
        key, en, es = cols[0], cols[1], cols[2]
        params = []
        if len(cols) > 3 and cols[3].strip():
            params = [tuple(p.split(':')) for p in cols[3].split(',')]
        for text in (en, es):
            found = set(re.findall(r'\{(\w+)\}', text))
            if found != {p[0] for p in params}:
                raise SystemExit(f'Placeholder mismatch in "{key}": {found} vs {params}')
        rows.append((key, en, es, params))

    keys = [r[0] for r in rows]
    if len(keys) != len(set(keys)):
        raise SystemExit('Duplicated keys in strings.tsv')

    out = []
    out.append('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    out.append('// Source: l10n/strings.tsv — regenerate with `python tool/generate_l10n.py`.')
    out.append('')
    out.append("import 'package:flutter/foundation.dart';")
    out.append("import 'package:flutter/widgets.dart';")
    out.append('')
    out.append('/// Localized strings for English (default) and Spanish.')
    out.append('class AppLocalizations {')
    out.append('  AppLocalizations(this.locale)')
    out.append("    : _values = locale.languageCode == 'es' ? _es : _en;")
    out.append('')
    out.append('  final Locale locale;')
    out.append('  final Map<String, String> _values;')
    out.append('')
    out.append("  static const List<Locale> supportedLocales = [Locale('en'), Locale('es')];")
    out.append('')
    out.append('  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();')
    out.append('')
    out.append('  static AppLocalizations of(BuildContext context) {')
    out.append('    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);')
    out.append("    assert(value != null, 'AppLocalizations.delegate is not registered');")
    out.append('    return value!;')
    out.append('  }')
    out.append('')
    out.append('  /// English is used for any unsupported device language.')
    out.append('  static Locale resolve(Locale? locale, Iterable<Locale> supported) {')
    out.append('    for (final candidate in supported) {')
    out.append('      if (candidate.languageCode == locale?.languageCode) return candidate;')
    out.append('    }')
    out.append("    return const Locale('en');")
    out.append('  }')
    out.append('')
    out.append('  @visibleForTesting')
    out.append('  static Set<String> get englishKeys => _en.keys.toSet();')
    out.append('')
    out.append('  @visibleForTesting')
    out.append('  static Set<String> get spanishKeys => _es.keys.toSet();')
    out.append('')
    out.append("  String _t(String key) => _values[key] ?? _en[key] ?? key;")
    out.append('')
    for key, en, es, params in rows:
        if params:
            sig = ', '.join(f'{t} {n}' for n, t in params)
            out.append(f'  String {key}({sig}) => _t(\'{key}\')')
            for n, _ in params:
                out.append(f"      .replaceAll('{{{n}}}', '${n}')")
            out[-1] = out[-1] + ';'
        else:
            out.append(f"  String get {key} => _t('{key}');")
    out.append('}')
    out.append('')
    for name, idx in (('_en', 1), ('_es', 2)):
        out.append(f'const Map<String, String> {name} = {{')
        for row in rows:
            text = row[idx].replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
            out.append(f"  '{row[0]}': '{text}',")
        out.append('};')
        out.append('')
    out.append('class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {')
    out.append('  const _AppLocalizationsDelegate();')
    out.append('')
    out.append('  @override')
    out.append("  bool isSupported(Locale locale) => const ['en', 'es'].contains(locale.languageCode);")
    out.append('')
    out.append('  @override')
    out.append('  Future<AppLocalizations> load(Locale locale) =>')
    out.append('      SynchronousFuture<AppLocalizations>(AppLocalizations(locale));')
    out.append('')
    out.append('  @override')
    out.append('  bool shouldReload(_AppLocalizationsDelegate old) => false;')
    out.append('}')
    out.append('')
    out.append('extension AppLocalizationsX on BuildContext {')
    out.append('  AppLocalizations get l10n => AppLocalizations.of(this);')
    out.append('}')
    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text('\n'.join(out) + '\n', encoding='utf-8')
    print(f'Generated {TARGET.relative_to(ROOT)} with {len(rows)} keys')


if __name__ == '__main__':
    main()
