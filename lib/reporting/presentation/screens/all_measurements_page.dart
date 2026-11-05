import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/presentation/l10n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/measurement_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/environment_header.dart';
import '../widgets/modern_filter_chip.dart';

class AllMeasurementsPage extends StatefulWidget {
  const AllMeasurementsPage({super.key, required this.data});
  final ReportsData data;

  @override
  State<AllMeasurementsPage> createState() => _AllMeasurementsPageState();
}

class _AllMeasurementsPageState extends State<AllMeasurementsPage> {
  int? _environmentId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final grouped = widget.data.measurementsByEnvironment;
    final environmentIds = grouped.keys.toList()..sort();

    final visibleGrouped = _environmentId == null
        ? grouped
        : {if (grouped.containsKey(_environmentId)) _environmentId!: grouped[_environmentId]!};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMeasurements, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ModernFilterChipBar(
            children: [
              ModernFilterChip(
                label: l10n.filterAll,
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

          if (visibleGrouped.isEmpty)
            EmptyStateView(
              icon: Icons.analytics_outlined,
              message: l10n.noReadingsInPeriod,
            )
          else
            for (final entry in visibleGrouped.entries) ...[
              EnvironmentHeader(name: widget.data.environmentNames[entry.key] ?? ''),
              for (final s in entry.value) MeasurementRow(summary: s, data: widget.data),
            ],
        ],
      ),
    );
  }
}