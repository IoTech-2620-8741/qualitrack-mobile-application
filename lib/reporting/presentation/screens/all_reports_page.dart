import 'package:flutter/material.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/presentation/l10n/app_localizations.dart';
import '../../domain/entities/reporting_entities.dart';
import '../widgets/history_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/modern_filter_chip.dart';
import '../widgets/report_labels.dart';

class AllReportsPage extends StatefulWidget {
  const AllReportsPage({super.key, required this.reports});
  final List<AuditReport> reports;

  @override
  State<AllReportsPage> createState() => _AllReportsPageState();
}

class _AllReportsPageState extends State<AllReportsPage> {
  String? _type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final types = widget.reports.map((r) => r.reportType).toSet().toList()..sort();
    final visible = _type == null
        ? widget.reports
        : widget.reports.where((r) => r.reportType == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ModernFilterChipBar(
            children: [
              ModernFilterChip(
                label: l10n.filterAll,
                selected: _type == null,
                onSelected: () => setState(() => _type = null),
              ),
              for (final t in types)
                ModernFilterChip(
                  label: reportTypeLabel(l10n, t),
                  selected: _type == t,
                  onSelected: () => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (visible.isEmpty)
            EmptyStateView(
              icon: Icons.history,
              message: l10n.reportHistoryEmpty,
            )
          else
            for (final r in visible) HistoryRow(report: r),
        ],
      ),
    );
  }
}