import 'package:flutter/material.dart';
import '../../../app/theme/app_spacing.dart';

class TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  TabBarHeaderDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant TabBarHeaderDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}