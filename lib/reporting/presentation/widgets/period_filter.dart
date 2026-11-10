/// This file contains the Period Filter widget.
///
/// It displays a horizontal list of chips to select the time period
/// (24 hours, 7 days, 31 days) for the reports.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../domain/entities/reporting_enums.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/report_labels.dart';

/// A widget that displays the time period filter chips.
class PeriodFilter extends StatelessWidget {
  const PeriodFilter({super.key, required this.state, required this.bloc});

  /// The current state of the BLoC, used to highlight the selected chip.
  final ReportsState state;

  /// The BLoC instance to dispatch the period change event.
  final ReportsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connected button group: the periods are mutually exclusive options
          // of the same setting, so they are joined in a single control.
          SegmentedButton<ReportPeriod>(
            showSelectedIcon: false,
            segments: [
              for (final p in ReportPeriod.values)
                ButtonSegment(
                  value: p,
                  label: Text(reportPeriodLabel(i18n, p), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
            ],
            selected: {state.period},
            onSelectionChanged: (selection) => bloc.add(ReportsPeriodChanged(selection.first)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}