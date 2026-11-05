/// This file contains the main screen for the Reports and KPIs.
///
/// It acts as a layout orchestrator, connecting the BLoC state with
/// the tabbed UI (Deviations, Measurements, and History) and the period filter.
///
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../application/reporting_facade_service.dart';
import '../../domain/entities/reporting_enums.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/period_filter.dart';
import '../widgets/tab_bar_header_delegate.dart';
import '../tabs/deviations_tab.dart';
import '../tabs/measurements_tab.dart';
import '../tabs/history_tab.dart';

/// Main screen for displaying reports and KPIs.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final bloc = context.read<ReportsBloc>();

    // Callback to trigger a manual refresh from the UI
    void reload() => bloc.add(const ReportsRequested(refresh: true));

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.reportsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      // Listen to the BLoC state to rebuild the UI
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) => RemoteStateView<ReportsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.insights_outlined,
          emptyMessage: i18n.reportsEmpty,

          // If data is loaded successfully, build the tabbed layout
          builder: (context, data) => DefaultTabController(
            length: 3,
            child: NestedScrollView(
              // 1. Header that scrolls with the page (Period Filter)
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(
                  child: PeriodFilter(state: state, bloc: bloc),
                ),

                // 2. Pinned TabBar (stays at the top when scrolling)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: TabBarHeaderDelegate(
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: i18n.tabDeviations(data.criticalTrendsCount)),
                        Tab(text: i18n.tabMeasurements),
                        Tab(text: i18n.tabHistory),
                      ],
                    ),
                  ),
                ),
              ],

              // 3. The content for each tab
              body: TabBarView(
                children: [
                  DeviationsTab(
                    data: data,
                    onReload: reload,
                    onSeeLast31Days: () => bloc.add(const ReportsPeriodChanged(ReportPeriod.last31Days)),
                  ),
                  MeasurementsTab(
                    data: data,
                    onReload: reload,
                    onSeeLast31Days: () => bloc.add(const ReportsPeriodChanged(ReportPeriod.last31Days)),
                  ),
                  HistoryTab(data: data, onReload: reload),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}