/// This file contains the Period Filter widget.
///
/// It displays a horizontal list of chips to select the time period
/// (24 hours, 7 days, 31 days) for the reports.
///
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
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
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal scroll view to prevent overflow on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // Iterate over all available periods in the enum
              children: ReportPeriod.values.map((p) {
                final isSelected = state.period == p;

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(reportPeriodLabel(l10n, p)),
                    selected: isSelected,
                    // Dispatch the event to the BLoC when tapped
                    onSelected: (_) => bloc.add(ReportsPeriodChanged(p)),

                    // Styling (same as ModernFilterChip)
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}