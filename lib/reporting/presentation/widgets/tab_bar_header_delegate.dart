/// This file contains the TabBar Header Delegate.
///
/// It is used inside a [SliverPersistentHeader] to keep the [TabBar] pinned
/// at the top of the screen while the user scrolls through the content.
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

/// A delegate that builds a pinned [TabBar] header inside a CustomScrollView/NestedScrollView.
class TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  TabBarHeaderDelegate(this.tabBar);

  /// The TabBar widget to display and keep pinned.
  final TabBar tabBar;

  // The minimum height the header will take when collapsed.
  // We add 16 to the default TabBar height to account for vertical padding.
  @override
  double get minExtent => tabBar.preferredSize.height + 16;

  // The maximum height the header can take when fully expanded.
  // Since we want a fixed size, it's the same as minExtent.
  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      // Use the scaffold background color so the content scrolling behind it is hidden
      color: Theme.of(context).scaffoldBackgroundColor,
      // Add some padding around the TabBar to make it look nice
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: tabBar,
    );
  }

  // Determines if the delegate needs to rebuild when the widget updates.
  // It only rebuilds if the TabBar instance changes.
  @override
  bool shouldRebuild(covariant TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}