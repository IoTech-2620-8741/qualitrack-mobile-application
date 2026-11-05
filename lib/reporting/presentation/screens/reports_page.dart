import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../domain/entities/reporting_entities.dart';
import '../../application/reporting_facade_service.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/period_filter.dart';
import '../widgets/tab_bar_header_delegate.dart';
import '../tabs/deviations_tab.dart';
import '../tabs/measurements_tab.dart';
import '../tabs/history_tab.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<ReportsBloc>();
    void reload() => bloc.add(const ReportsRequested(refresh: true));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocBuilder<ReportsBloc, ReportsState>(
        builder: (context, state) => RemoteStateView<ReportsData>(
          state: state.remote,
          onRetry: reload,
          emptyIcon: Icons.insights_outlined,
          emptyMessage: l10n.reportsEmpty,
          builder: (context, data) => DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) => [
                SliverToBoxAdapter(child: PeriodFilter(state: state, bloc: bloc)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: TabBarHeaderDelegate(
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.grey.shade600,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: l10n.tabDeviations(data.criticalTrendsCount)),
                        Tab(text: l10n.tabMeasurements),
                        Tab(text: l10n.tabHistory),
                      ],
                    ),
                  ),
                ),
              ],
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