import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/favorites_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/price_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Favoris'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tout supprimer',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vider les favoris'),
                    content: const Text(
                        'Êtes-vous sûr de vouloir supprimer tous vos favoris ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: favorites.isEmpty
          ? _EmptyFavorites(
              onBrowse: () => context.go('/'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final product = favorites[i];
                return _FavoriteProductTile(
                  product: product,
                  onRemove: () =>
                      ref.read(favoritesProvider.notifier).toggleFavorite(product),
                  onAddToCart: () {
                    ref.read(cartProvider.notifier).addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ajouté au panier'),
                        action: SnackBarAction(
                          label: 'Voir',
                          onPressed: () => context.go('/cart'),
                        ),
                      ),
                    );
                  },
                  onTap: () => context.push('/product/${product.slug}'),
                );
              },
            ),
    );
  }
}

class _FavoriteProductTile extends StatelessWidget {
  final dynamic product;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const _FavoriteProductTile({
    required this.product,
    required this.onRemove,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.textTertiary),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName != null)
                    Text(
                      product.categoryName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PriceFormatter.format(product.priceAsDouble),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite, color: AppColors.error),
                  onPressed: onRemove,
                  tooltip: 'Retirer des favoris',
                ),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart_outlined,
                      color: AppColors.primary),
                  onPressed: onAddToCart,
                  tooltip: 'Ajouter au panier',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyFavorites({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_outline, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Aucun favori',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits à vos favoris\nen appuyant sur le cœur ❤️',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Découvrir les produits'),
          ),
        ],
      ),
    );
  }
}
