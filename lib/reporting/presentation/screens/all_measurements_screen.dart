/// This file contains the screen that displays the complete list of
/// measurement summaries, grouped by environment, allowing filtering by environment.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/measurement_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/environment_header.dart';
import '../widgets/modern_filter_chip.dart';

/// Screen that displays all measurement summaries.
class AllMeasurementsScreen extends StatefulWidget {
  const AllMeasurementsScreen({super.key, required this.data});

  /// The consolidated data from the Facade, containing the measurements.
  final ReportsData data;

  @override
  State<AllMeasurementsScreen> createState() => _AllMeasurementsScreenState();
}

class _AllMeasurementsScreenState extends State<AllMeasurementsScreen> {
  /// Local state to hold the currently selected environment ID.
  /// Null means "All environments".
  int? _environmentId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    // Get the map of measurements grouped by environment ID
    final grouped = widget.data.measurementsByEnvironment;

    // Get a sorted list of environment IDs to display in the filter chips
    final environmentIds = grouped.keys.toList()..sort();

    // Filter the grouped measurements based on the selected environment
    final visibleGrouped = _environmentId == null
        ? grouped
        : {if (grouped.containsKey(_environmentId)) _environmentId!: grouped[_environmentId]!};

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: i18n.tabMeasurements),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Filter bar with environment options (including "All")
          ModernFilterChipBar(
            children: [
              ModernFilterChip(
                label: i18n.filterAll,
                selected: _environmentId == null,
                onSelected: () => setState(() => _environmentId = null),
              ),
              for (final id in environmentIds)
                ModernFilterChip(
                  label: widget.data.environmentNames[id] ?? '#$id',
                  selected: _environmentId == id,
                  onSelected: () => setState(() => _environmentId = id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. List of measurements (or empty state)
          if (visibleGrouped.isEmpty)
            EmptyStateView(
              icon: Icons.analytics_outlined,
              message: i18n.noReadingsInPeriod,
            )
          else
          // Iterate over the grouped measurements
            for (final entry in visibleGrouped.entries) ...[
              // Display the environment name as a header
              EnvironmentHeader(name: widget.data.environmentNames[entry.key] ?? ''),

              // Display each measurement summary in that environment
              for (final s in entry.value) MeasurementRow(summary: s, data: widget.data),
            ],
        ],
      ),
    );
  }
}