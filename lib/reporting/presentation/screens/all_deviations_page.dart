import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../application/reporting_facade_service.dart';
import '../widgets/trend_row.dart';
import '../widgets/empty_states.dart';

enum _DeviationFilter { all, critical, warning, onTrack, noData }

extension on _DeviationFilter {
  bool matches(DeviationTrend t) => switch (this) {
    _DeviationFilter.all => true,
    _DeviationFilter.critical => t.severity == DeviationSeverity.critical,
    _DeviationFilter.warning => t.severity == DeviationSeverity.warning,
    _DeviationFilter.onTrack => t.severity == DeviationSeverity.onTrack,
    _DeviationFilter.noData => t.severity == DeviationSeverity.noData,
  };

  String label(AppLocalizations l10n, int count) => switch (this) {
    _DeviationFilter.all => '${l10n.filterAll} $count',
    _DeviationFilter.critical => '${l10n.healthCritical} $count',
    _DeviationFilter.warning => '${l10n.healthAtRisk} $count',
    _DeviationFilter.onTrack => '${l10n.healthOnTrack} $count',
    _DeviationFilter.noData => '${l10n.noData} $count',
  };
}

class AllDeviationsPage extends StatefulWidget {
  const AllDeviationsPage({super.key, required this.data});
  final ReportsData data;

  @override
  State<AllDeviationsPage> createState() => _AllDeviationsPageState();
}

class _AllDeviationsPageState extends State<AllDeviationsPage> {
  _DeviationFilter _filter = _DeviationFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final trends = widget.data.sortedTrends;
    int count(_DeviationFilter f) => trends.where(f.matches).length;
    final visible = trends.where(_filter.matches).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.deviationsLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _DeviationFilter.values.map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(f.label(l10n, count(f))),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (visible.isEmpty)
            EmptyStateView(
              icon: Icons.insights_outlined,
              message: l10n.noReadingsInPeriod,
            )
          else
            for (final t in visible) TrendRow(trend: t, data: widget.data),
        ],
      ),
    );
  }
}