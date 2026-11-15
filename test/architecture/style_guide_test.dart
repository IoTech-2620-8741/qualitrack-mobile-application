import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_colors.dart';
import 'package:qualitrack_mobile/common/presentation/theme/app_theme.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/layout_widgets.dart';
import 'package:qualitrack_mobile/common/presentation/widgets/pressable_card.dart';

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

  // Colors in mobile context: a card background is #FFFFFF with elevation: 1.
  testWidgets('cards are white with the soft shadow of elevation 1', (tester) async {
    final cards = AppTheme.light().cardTheme;
    expect(cards.color, AppColors.surface);
    expect(cards.elevation, 1);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              const InfoCard(child: Text('section')),
              // A tinted section with a border is an outlined card, which Material 3 keeps flat.
              const InfoCard(
                color: AppColors.criticalContainer,
                borderColor: AppColors.critical,
                child: Text('rejected batch'),
              ),
              PressableCard(onTap: () {}, child: const Text('home card')),
            ],
          ),
        ),
      ),
    );
    double elevationOf(String text) =>
        tester.widget<Material>(find.ancestor(of: find.text(text), matching: find.byType(Material)).first).elevation;
    expect(elevationOf('section'), 1);
    expect(elevationOf('rejected batch'), 0);
    expect(elevationOf('home card'), 1);

    // Cards drawn by hand: a white Material with rounded corners.
    final problems = [
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart'))
          for (final (index, line) in file.readAsLinesSync().indexed)
            if (line.trimRight().endsWith('Material(') && _isFlatCard(file.readAsLinesSync().skip(index + 1).take(5)))
              '${file.path}:${index + 1}',
    ];
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}

/// Whether the arguments that open a Material make it a white rounded card without elevation 1.
bool _isFlatCard(Iterable<String> arguments) {
  final head = arguments.join('\n');
  final card = head.contains('AppColors.surface') && RegExp('borderRadius|RoundedRectangleBorder').hasMatch(head);
  return card && !RegExp(r'elevation:[^,\n]*\b1\b').hasMatch(head);
}
