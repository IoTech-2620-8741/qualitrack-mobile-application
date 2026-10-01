import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../shared/presentation/formatting/context_locale.dart';
import '../../../shared/presentation/formatting/formatters.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/remote_state.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/section_card.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../../shared/presentation/section.dart';
import '../../application/billing_queries.dart';
import '../../domain/subscription.dart';
import '../bloc/billing_bloc.dart';

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
class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    void reload() => context.read<BillingBloc>().add(const BillingRequested(refresh: true));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billingTitle)),
      body: BlocBuilder<BillingBloc, RemoteState<BillingSummary>>(
        builder: (context, state) => RemoteStateView<BillingSummary>(
          state: state,
          onRetry: reload,
          emptyIcon: Icons.receipt_long_outlined,
          emptyMessage: l10n.billingEmpty,
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
    final l10n = context.l10n;
    final locale = context.localeName;
    final active = summary.active;
    final plan = summary.plan;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        PageHeader(title: l10n.billingTitle, subtitle: l10n.billingSubtitle),
        const SizedBox(height: AppSpacing.md),
        InfoCard(
          title: l10n.currentSubscription,
          child: active == null
              ? Text(l10n.noActiveSubscription)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.lg,
                      children: [
                        KeyValue(label: l10n.plan, value: plan?.name ?? active.planCode),
                        KeyValue(
                          label: l10n.status,
                          value: Formatters.humanize(active.status),
                          valueWidget: StatusBadge(
                            label: Formatters.humanize(active.status),
                            tone: subscriptionTone(active.status),
                          ),
                        ),
                        KeyValue(label: l10n.billingCycle, value: Formatters.humanize(active.billingCycle)),
                        KeyValue(
                          label: l10n.periodStart,
                          value: Formatters.date(active.currentPeriodStart, locale),
                        ),
                        KeyValue(
                          label: l10n.periodEnd,
                          value: Formatters.date(active.currentPeriodEnd, locale),
                        ),
                        if (plan != null && plan.amount != null)
                          KeyValue(
                            label: l10n.amount,
                            value: Formatters.money(plan.amount, plan.currency, locale),
                          ),
                        if (plan != null && plan.maxUsers != null)
                          KeyValue(label: l10n.maxUsers, value: '${plan.maxUsers}'),
                        if (plan != null && plan.maxEquipment != null)
                          KeyValue(label: l10n.maxEquipment, value: '${plan.maxEquipment}'),
                      ],
                    ),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<SubscriptionPayment>(
          title: l10n.paymentHistory,
          section: Section(summary.payments),
          emptyMessage: l10n.paymentsEmpty,
          itemBuilder: (context, p) => SectionRow(
            leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
            title: Formatters.money(p.amount, p.currency, locale),
            subtitle: [
              if (p.provider != null) '${l10n.provider}: ${p.provider}',
              Formatters.dateTime(p.paidAt, locale),
            ].join(' · '),
            trailing: StatusBadge(label: Formatters.humanize(p.status), tone: paymentTone(p.status)),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard<Subscription>(
          title: l10n.subscriptionHistory,
          section: Section(summary.subscriptions),
          itemBuilder: (context, s) => SectionRow(
            title: '${s.planCode} · ${Formatters.humanize(s.billingCycle)}',
            subtitle:
                '${Formatters.date(s.currentPeriodStart, locale)} – ${Formatters.date(s.currentPeriodEnd, locale)}',
            trailing: StatusBadge(label: Formatters.humanize(s.status), tone: subscriptionTone(s.status)),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            const Icon(Icons.desktop_windows_outlined, size: 18, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(l10n.billingManagedOnWeb, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}
