import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/formatting/context_locale.dart';
import '../../../common/presentation/formatting/formatters.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/remote_state.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/section_card.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../../common/application/section.dart';
import '../../domain/entities/billing_summary.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_payment.dart';
import '../bloc/billing_bloc.dart';
import '../../../common/presentation/labels.dart';

BadgeTone subscriptionTone(String status) => switch (status) {
  'ACTIVE' => BadgeTone.success,
  'PENDING_PAYMENT' => BadgeTone.warning,
  'CANCELLED' || 'EXPIRED' => BadgeTone.critical,
  _ => BadgeTone.neutral,
};

BadgeTone paymentTone(String status) => switch (status) {
  'PAID' => BadgeTone.success,
  'PENDING' => BadgeTone.warning,
  'FAILED' || 'CANCELLED' => BadgeTone.critical,
  'REFUNDED' => BadgeTone.info,
  _ => BadgeTone.neutral,
};

/// "Resumen de Facturación" mockup, read-only. Plan changes, checkout and
/// cancellation are managed in QualiTrack Web.
class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    void reload() => context.read<BillingBloc>().add(const BillingRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: AppBarTitle(title: i18n.billingTitle, subtitle: i18n.billingSubtitle)),
      body: BlocBuilder<BillingBloc, RemoteState<BillingSummary>>(
        builder: (context, state) => RemoteStateView<BillingSummary>(
          state: state,
          onRetry: reload,
          emptyIcon: Icons.receipt_long_outlined,
          emptyMessage: i18n.billingEmpty,
          builder: (context, summary) => RefreshIndicator(
            onRefresh: () async => reload(),
            child: _BillingBody(summary: summary),
          ),
        ),
      ),
    );
  }
}

class _BillingBody extends StatelessWidget {
  const _BillingBody({required this.summary});

  final BillingSummary summary;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    final locale = context.localeName;
    final active = summary.active;
    final plan = summary.plan;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        InfoCard(
          title: i18n.currentSubscription,
          child: active == null
              ? Text(i18n.noActiveSubscription)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DetailList(
                      children: [
                        DetailRow(label: i18n.plan, value: plan?.name ?? active.planCode),
                        DetailRow(
                          label: i18n.status,
                          value: codeLabel(i18n, active.status),
                          valueWidget: StatusBadge(
                            label: codeLabel(i18n, active.status),
                            tone: subscriptionTone(active.status),
                          ),
                        ),
                        DetailRow(label: i18n.billingCycle, value: codeLabel(i18n, active.billingCycle)),
                        DetailRow(
                          label: i18n.periodStart,
                          value: Formatters.date(active.currentPeriodStart, locale),
                        ),
                        DetailRow(
                          label: i18n.periodEnd,
                          value: Formatters.date(active.currentPeriodEnd, locale),
                        ),
                        if (plan != null && plan.amount != null)
                          DetailRow(
                            label: i18n.amount,
                            value: Formatters.money(plan.amount, plan.currency, locale),
                          ),
                        if (plan != null && plan.maxUsers != null)
                          DetailRow(label: i18n.maxUsers, value: '${plan.maxUsers}'),
                        if (plan != null && plan.maxEquipment != null)
                          DetailRow(label: i18n.maxEquipment, value: '${plan.maxEquipment}'),
                      ],
                    ),
                    if (active.cancelAtPeriodEnd) ...[
                      const SizedBox(height: AppSpacing.md),
                      StatusBadge(
                        label: i18n.renewalCancelled(Formatters.date(active.currentPeriodEnd, locale)),
                        tone: BadgeTone.warning,
                        icon: Icons.event_busy_outlined,
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<SubscriptionPayment>(
          title: i18n.paymentHistory,
          section: Section(summary.payments),
          emptyMessage: i18n.paymentsEmpty,
          itemBuilder: (context, p) => SectionRow(
            leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
            title: Formatters.money(p.amount, p.currency, locale),
            subtitle: [
              if (p.provider != null) '${i18n.provider}: ${p.provider}',
              Formatters.dateTime(p.paidAt, locale),
            ].join(' · '),
            trailing: StatusBadge(label: codeLabel(i18n, p.status), tone: paymentTone(p.status)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<Subscription>(
          title: i18n.subscriptionHistory,
          section: Section(summary.subscriptions),
          itemBuilder: (context, s) => SectionRow(
            title: '${summary.planNameOf(s)} · ${codeLabel(i18n, s.billingCycle)}',
            subtitle:
                '${Formatters.date(s.currentPeriodStart, locale)} – ${Formatters.date(s.currentPeriodEnd, locale)}',
            trailing: StatusBadge(label: codeLabel(i18n, s.status), tone: subscriptionTone(s.status)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.desktop_windows_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(i18n.billingManagedOnWeb, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}
