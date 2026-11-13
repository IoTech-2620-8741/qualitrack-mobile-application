import 'dart:async';

import 'package:flutter/widgets.dart';

/// Rebuilds [builder] every minute, so an elapsed time on screen ("Updated
/// 2 min ago") keeps counting between refreshes.
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
