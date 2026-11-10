import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// One page of [SecondaryTabs].
class SecondaryTab {
  const SecondaryTab({required this.label, required this.builder});

  final String label;
  final WidgetBuilder builder;
}

/// M3 secondary tabs: switch between related sub-sections inside the content
/// of a screen (e.g. the history lists of an equipment).
///
/// Text-only labels with a full-width underline under the active one. The
/// selected page is rendered below the bar as part of the surrounding list
/// (no nested scroll view), so it can sit inside a `ListView`.
class SecondaryTabs extends StatefulWidget {
  const SecondaryTabs({super.key, required this.tabs});

  final List<SecondaryTab> tabs;

  @override
  State<SecondaryTabs> createState() => _SecondaryTabsState();
}

class _SecondaryTabsState extends State<SecondaryTabs> with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: widget.tabs.length, vsync: this)
    ..addListener(_onChanged);

  void _onChanged() {
    if (!_controller.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = _controller.index;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surface,
          child: TabBar.secondary(
            controller: _controller,
            isScrollable: widget.tabs.length > 3,
            tabAlignment: widget.tabs.length > 3 ? TabAlignment.start : TabAlignment.fill,
            tabs: [for (final tab in widget.tabs) Tab(text: tab.label)],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(index), child: widget.tabs[index].builder(context)),
        ),
      ],
    );
  }
}
