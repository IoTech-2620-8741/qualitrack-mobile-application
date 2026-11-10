import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../common/presentation/theme/app_colors.dart';
import '../../../common/presentation/theme/app_spacing.dart';
import '../../../common/presentation/theme/app_typography.dart';
import '../../../common/presentation/i18n/app_localizations.dart';
import '../../../common/presentation/widgets/layout_widgets.dart';
import '../../../common/presentation/widgets/remote_state_view.dart';
import '../../../common/presentation/widgets/state_views.dart';
import '../../../common/presentation/widgets/status_badge.dart';
import '../../domain/entities/lab_environment.dart';
import '../../domain/entities/pharmaceutical_product.dart';
import '../../domain/entities/product_catalog.dart';
import '../bloc/products_bloc.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  void _reload(BuildContext context) =>
      context.read<ProductsBloc>().add(const ProductsRequested(refresh: true));

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            final products = state.remote.data?.products;
            return AppBarTitle(
              title: i18n.productsTitle,
              subtitle: products == null ? null : i18n.productsCount(products.length),
            );
          },
        ),
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) => RemoteStateView<ProductCatalog>(
          state: state.remote,
          onRetry: () => _reload(context),
          emptyIcon: Icons.medication_outlined,
          emptyMessage: i18n.productsEmpty,
          builder: (context, _) {
            final items = state.visible;
            return RefreshIndicator(
              onRefresh: () async => _reload(context),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  SearchField(
                    hint: i18n.searchProducts,
                    onChanged: (q) => context.read<ProductsBloc>().add(ProductsQueryChanged(q)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (items.isEmpty)
                    SizedBox(height: 240, child: EmptyView(title: i18n.noResults))
                  else
                    for (final product in items) ...[
                      _ProductTile(
                        product: product,
                        environment: state.remote.data?.environment(product.environmentId),
                      ),
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
  const _ProductTile({required this.product, this.environment});

  final PharmaceuticalProduct product;
  final LabEnvironment? environment;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Card(
      child: ListTile(
        onTap: () => context.push('/products/${product.id}'),
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          environment?.displayName ?? product.description ?? '',
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
              StatusBadge(label: i18n.inactive, tone: BadgeTone.neutral),
          ],
        ),
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ProductsBloc, ProductsState>(
          builder: (context, state) {
            final product = state.byId(productId);
            return AppBarTitle(title: product?.name ?? i18n.productDetail, subtitle: product?.code);
          },
        ),
      ),
      body: BlocBuilder<ProductsBloc, ProductsState>(
        builder: (context, state) => RemoteStateView<ProductCatalog>(
          state: state.remote,
          onRetry: () => context.read<ProductsBloc>().add(const ProductsRequested()),
          builder: (context, _) {
            final product = state.byId(productId);
            if (product == null) return EmptyView(title: i18n.errorNotFound);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                InfoCard(
                  child: DetailList(
                    children: [
                      DetailRow(label: i18n.code, value: product.code),
                      DetailRow(
                        label: i18n.environment,
                        value: state.remote.data?.environment(product.environmentId)?.displayName ?? '—',
                      ),
                      DetailRow(
                        label: i18n.status,
                        value: product.active ? i18n.active : i18n.inactive,
                        valueWidget: StatusBadge(
                          label: product.active ? i18n.active : i18n.inactive,
                          tone: product.active ? BadgeTone.success : BadgeTone.neutral,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: i18n.description,
                  child: Text(product.description?.isNotEmpty == true ? product.description! : '—'),
                ),
                const SizedBox(height: AppSpacing.md),
                InfoCard(
                  title: i18n.bpmSpecifications,
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
