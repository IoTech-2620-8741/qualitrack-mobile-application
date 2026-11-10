/// This file contains the screen that displays the complete list of
/// deviation trends, allowing the user to filter them by severity.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/toggle_button.dart';
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
class AllDeviationsScreen extends StatefulWidget {
  const AllDeviationsScreen({super.key, required this.data});

  /// The consolidated data from the Facade, containing the trends.
  final ReportsData data;

  @override
  State<AllDeviationsScreen> createState() => _AllDeviationsScreenState();
}

class _AllDeviationsScreenState extends State<AllDeviationsScreen> {
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
        title: AppBarTitle(title: i18n.deviationsLabel),
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
                  child: ToggleButton(
                    label: f.label(i18n, count(f)),
                    selected: isSelected,
                    onPressed: () => setState(() => _filter = f),
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