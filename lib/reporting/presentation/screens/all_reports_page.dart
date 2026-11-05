/// This file contains the screen that displays the complete history of
/// audit reports, allowing filtering by report type.
///
library;

import 'package:flutter/material.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../domain/entities/audit_entities.dart';
import '../widgets/history_row.dart';
import '../widgets/empty_states.dart';
import '../widgets/modern_filter_chip.dart';
import '../widgets/report_labels.dart';

/// Screen that displays all audit reports with filtering capabilities.
class AllReportsPage extends StatefulWidget {
  const AllReportsPage({super.key, required this.reports});

  /// The full list of reports passed from the previous screen.
  final List<AuditReport> reports;

  @override
  State<AllReportsPage> createState() => _AllReportsPageState();
}

class _AllReportsPageState extends State<AllReportsPage> {
  /// Local state to hold the currently selected report type.
  /// Null means "All types".
  String? _type;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;

    // Extract unique report types and sort them alphabetically for the filter chips
    final types = widget.reports.map((r) => r.reportType).toSet().toList()..sort();

    // Filter the reports based on the selected type
    final visible = _type == null
        ? widget.reports
        : widget.reports.where((r) => r.reportType == _type).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.reportHistory, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 1. Filter bar with report types (including "All")
          ModernFilterChipBar(
            children: [
              ModernFilterChip(
                label: i18n.filterAll,
                selected: _type == null,
                onSelected: () => setState(() => _type = null),
              ),
              for (final t in types)
                ModernFilterChip(
                  label: reportTypeLabel(i18n, t),
                  selected: _type == t,
                  onSelected: () => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. List of reports (or empty state)
          if (visible.isEmpty)
            EmptyStateView(
              icon: Icons.history,
              message: i18n.reportHistoryEmpty,
            )
          else
          // Display each report using the reusable HistoryRow widget
            for (final r in visible) HistoryRow(report: r),
        ],
      ),
    );
  }
}