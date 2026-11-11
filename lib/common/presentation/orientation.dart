import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Orientations of the app. It is laid out for portrait (Report, Mobile Style
/// Guidelines); only the telemetry history chart may also turn to landscape.
abstract final class AppOrientation {
  static const List<DeviceOrientation> portrait = [DeviceOrientation.portraitUp];

  static const List<DeviceOrientation> portraitOrLandscape = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  static Future<void> lockPortrait() => SystemChrome.setPreferredOrientations(portrait);
}

/// Lets the screen turn to landscape while [child] is the visible screen, and
/// goes back to portrait when it is closed or another tab is shown (the tabs
/// keep their screens alive, offstage, with their tickers muted).
class LandscapeAllowed extends StatefulWidget {
  const LandscapeAllowed({super.key, required this.child});

  final Widget child;

  @override
  State<LandscapeAllowed> createState() => _LandscapeAllowedState();
}

class _LandscapeAllowedState extends State<LandscapeAllowed> {
  bool? _visible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    SystemChrome.setPreferredOrientations(visible ? AppOrientation.portraitOrLandscape : AppOrientation.portrait);
  }

  @override
  void dispose() {
    AppOrientation.lockPortrait();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
