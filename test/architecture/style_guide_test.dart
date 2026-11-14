import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rules of the style guide (qualitrack-report, chapter V) that can be checked
/// by reading the code.
void main() {
  test('every text uses the theme font, Rubik', () {
    // A font family other than AppTypography.fontFamily, such as 'monospace'.
    final otherFont = RegExp(r'fontFamily:(?!\s*(?:AppTypography\.)?fontFamily\b)');
    final problems = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart'))
          for (final line in file.readAsLinesSync())
            if (otherFont.hasMatch(line)) '${file.path}: ${line.trim()}',
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
