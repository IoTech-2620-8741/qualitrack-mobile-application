import 'package:flutter/material.dart';

/// Scroll behavior used by the whole app.
///
/// Android's Material 3 default is the "stretch" overscroll effect, which
/// visually deforms cards, charts and text when the list is dragged past its
/// edge. QualiTrack shows dense operational data, so overscroll is clamped
/// instead: the content stops at the edge and nothing is distorted.
/// `RefreshIndicator` keeps working because it listens to the drag, not to the
/// overscroll indicator.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics(parent: RangeMaintainingScrollPhysics());
}
