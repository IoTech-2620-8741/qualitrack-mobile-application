/// This file contains the main screen for the Reports and KPIs.
///
/// It acts as a layout orchestrator, connecting the BLoC state with
/// the tabbed UI (Deviations, Measurements, and History) and the period filter.
///
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
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
        title: AppBarTitle(title: i18n.reportsTitle),
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
                    // Primary tabs: the three main views of the reports.
                    TabBar(
                      tabs: [
                        Tab(
                          icon: const Icon(Icons.insights_outlined),
                          text: i18n.tabDeviations(data.criticalTrendsCount),
                        ),
                        Tab(icon: const Icon(Icons.analytics_outlined), text: i18n.tabMeasurements),
                        Tab(icon: const Icon(Icons.history), text: i18n.tabHistory),
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