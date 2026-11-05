/// This file contains the screen that displays the complete list of
/// deviation trends, allowing the user to filter them by severity.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/deviation_entities.dart';
import '../../domain/entities/reporting_enums.dart';
import '../widgets/trend_row.dart';
import '../widgets/empty_states.dart';

/// Internal enum to handle the filtering options on the screen.
enum _DeviationFilter { all, critical, warning, onTrack, noData }

/// Extension to add behavior to the [_DeviationFilter] enum.
///
/// (Extensión para saber si una tendencia coincide con el filtro seleccionado
/// y para obtener la etiqueta traducida).
extension on _DeviationFilter {
  /// Checks if the given [DeviationTrend] matches the current filter.
  bool matches(DeviationTrend t) => switch (this) {
    _DeviationFilter.all => true,
    _DeviationFilter.critical => t.severity == DeviationSeverity.critical,
    _DeviationFilter.warning => t.severity == DeviationSeverity.warning,
    _DeviationFilter.onTrack => t.severity == DeviationSeverity.onTrack,
    _DeviationFilter.noData => t.severity == DeviationSeverity.noData,
  };

  /// Returns the localized label with the count of items for each filter.
  String label(AppLocalizations i18n, int count) => switch (this) {
    _DeviationFilter.all => '${i18n.filterAll} $count',
    _DeviationFilter.critical => '${i18n.healthCritical} $count',
    _DeviationFilter.warning => '${i18n.healthAtRisk} $count',
    _DeviationFilter.onTrack => '${i18n.healthOnTrack} $count',
    _DeviationFilter.noData => '${i18n.noData} $count',
  };
}

/// Screen that displays all deviation trends with filtering capabilities.
class AllDeviationsPage extends StatefulWidget {
  const AllDeviationsPage({super.key, required this.data});

  /// The consolidated data from the Facade, containing the trends.
  final ReportsData data;

  @override
  State<AllDeviationsPage> createState() => _AllDeviationsPageState();
}

class _AllDeviationsPageState extends State<AllDeviationsPage> {
  // Estado local para guardar qué filtro está seleccionado actualmente.
  _DeviationFilter _filter = _DeviationFilter.all;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    // Obtenemos las tendencias ordenadas por severidad (desde la Fachada)
    final trends = widget.data.sortedTrends;

    // Función rápida para contar cuántas tendencias hay por cada filtro
    int count(_DeviationFilter f) => trends.where(f.matches).length;

    // Filtramos la lista de tendencias basándonos en el filtro seleccionado
    final visible = trends.where(_filter.matches).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.deviationsLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Fila de botones (Chips) para filtrar por severidad
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _DeviationFilter.values.map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(f.label(i18n, count(f))),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
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

          // 2. Lista de tendencias (o mensaje de vacío si no hay datos)
          if (visible.isEmpty)
            EmptyStateView(
              icon: Icons.insights_outlined,
              message: i18n.noReadingsInPeriod,
            )
          else
          // Pintamos cada tendencia usando el widget reutilizable TrendRow
            for (final t in visible) TrendRow(trend: t, data: widget.data),
        ],
      ),
    );
  }
}