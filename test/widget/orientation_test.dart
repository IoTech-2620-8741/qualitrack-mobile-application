import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qualitrack_mobile/common/presentation/orientation.dart';

void main() {
  testWidgets('only the screen inside LandscapeAllowed may turn, while it is the visible one', (tester) async {
    final requests = <List<String>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') requests.add((call.arguments as List).cast<String>());
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    const portrait = ['DeviceOrientation.portraitUp'];
    final visible = ValueNotifier(true);
    addTearDown(visible.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, enabled, _) => TickerMode(enabled: enabled, child: const LandscapeAllowed(child: SizedBox())),
      ),
    );
    expect(requests.last, containsAll(['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']));

    // Another tab is shown: its screen stays alive offstage, with tickers muted.
    visible.value = false;
    await tester.pump();
    expect(requests.last, portrait);

    visible.value = true;
    await tester.pump();
    expect(requests.last, contains('DeviceOrientation.landscapeLeft'));

    // Closing the screen goes back to portrait.
    await tester.pumpWidget(const SizedBox());
    expect(requests.last, portrait);
  });

  test('the app is laid out for portrait', () {
    expect(AppOrientation.portrait, [DeviceOrientation.portraitUp]);
  });
}
