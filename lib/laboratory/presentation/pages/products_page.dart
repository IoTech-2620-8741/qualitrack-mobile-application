import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/presentation/l10n/app_localizations.dart';
import '../../../shared/presentation/widgets/layout_widgets.dart';
import '../../../shared/presentation/widgets/remote_state_view.dart';
import '../../../shared/presentation/widgets/state_views.dart';
import '../../../shared/presentation/widgets/status_badge.dart';
import '../../domain/laboratory.dart';
import '../bloc/products_bloc.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  void _reload(BuildContext context) =>
      context.read<ProductsBloc>().add(const ProductsRequested(refresh: true));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productsTitle)),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) => RemoteStateView<List<PharmaceuticalProduct>>(
          state: state.remote,
          onRetry: () => _reload(context),
          emptyIcon: Icons.medication_outlined,
          emptyMessage: l10n.productsEmpty,
          builder: (context, _) {
            final items = state.visible;
            return RefreshIndicator(
              onRefresh: () async => _reload(context),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  PageHeader(
                    title: l10n.productsTitle,
                    subtitle: l10n.productsCount(state.remote.data?.length ?? 0),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchField(
                    hint: l10n.searchProducts,
                    onChanged: (q) => context.read<ProductsBloc>().add(ProductsQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    SizedBox(height: 240, child: EmptyView(title: l10n.noResults))
                  else
                    for (final product in items) ...[
                      _ProductTile(product: product),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final PharmaceuticalProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: ListTile(
        onTap: () => context.push('/products/${product.id}'),
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          product.specifications ?? product.description ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          child: Icon(Icons.medication_outlined, color: AppColors.primary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(product.code, style: const TextStyle(fontFamily: AppTypography.monospace)),
            if (!product.active)
              StatusBadge(label: l10n.inactive, tone: BadgeTone.neutral),
          ],
        ),
      ),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.productDetail)),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) => RemoteStateView<List<PharmaceuticalProduct>>(
          state: state.remote,
          onRetry: () => context.read<ProductsBloc>().add(const ProductsRequested()),
          builder: (context, _) {
            final product = state.byId(productId);
            if (product == null) return EmptyView(title: l10n.errorNotFound);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PageHeader(title: product.name, subtitle: product.code),
                const SizedBox(height: AppSpacing.lg),
                InfoCard(
                  child: Wrap(
                    spacing: AppSpacing.xl,
                    runSpacing: AppSpacing.lg,
                    children: [
                      KeyValue(label: l10n.code, value: product.code),
                      KeyValue(
                        label: l10n.status,
                        value: product.active ? l10n.active : l10n.inactive,
                        valueWidget: StatusBadge(
                          label: product.active ? l10n.active : l10n.inactive,
                          tone: product.active ? BadgeTone.success : BadgeTone.neutral,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: l10n.description,
                  child: Text(product.description?.isNotEmpty == true ? product.description! : '—'),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: l10n.bpmSpecifications,
                  child: Text(
                    product.specifications?.isNotEmpty == true ? product.specifications! : '—',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
