/// This file contains the TabBar Header Delegate.
///
/// It is used inside a [SliverPersistentHeader] to keep the [TabBar] pinned
/// at the top of the screen while the user scrolls through the content.
///
library;

import 'package:flutter/material.dart';

/// A delegate that builds a pinned [TabBar] header inside a CustomScrollView/NestedScrollView.
class TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  TabBarHeaderDelegate(this.tabBar);

  /// The TabBar widget to display and keep pinned.
  final TabBar tabBar;

  // The minimum height the header will take when collapsed.
  // Exactly the TabBar height: primary tabs span the full width on the surface.
  @override
  double get minExtent => tabBar.preferredSize.height;

  // The maximum height the header can take when fully expanded.
  // Since we want a fixed size, it's the same as minExtent.
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Opaque surface so the content scrolling behind it is hidden.
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  // Determines if the delegate needs to rebuild when the widget updates.
  // It only rebuilds if the TabBar instance changes.
  @override
  bool shouldRebuild(covariant TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}