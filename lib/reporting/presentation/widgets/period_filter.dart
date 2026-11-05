import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/report_labels.dart';

class PeriodFilter extends StatelessWidget {
  const PeriodFilter({super.key, required this.state, required this.bloc});
  final ReportsState state;
  final ReportsBloc bloc;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ReportPeriod.values.map((p) {
                final isSelected = state.period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(reportPeriodLabel(l10n, p)),
                    selected: isSelected,
                    onSelected: (_) => bloc.add(ReportsPeriodChanged(p)),
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