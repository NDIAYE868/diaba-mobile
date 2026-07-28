import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../features/shop/providers/shop_provider.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/favorites/providers/favorites_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../shared/utils/price_formatter.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  int _imageIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.slug));
    final cartNotifier = ref.read(cartProvider.notifier);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final favorites = ref.watch(favoritesProvider);

    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(productDetailProvider(widget.slug));
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
      data: (product) {
        final isFav = favorites.any((p) => p.id == product.id);
        final isOutOfStock = product.stockQuantity <= 0;
        final images = product.images ?? [];
        final theme = Theme.of(context);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ─── SliverAppBar avec galerie images ─────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_outline,
                        color: isFav ? Colors.red : Colors.white,
                      ),
                    ),
                    onPressed: () => favoritesNotifier.toggleFavorite(product),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Image slider
                      images.isNotEmpty
                          ? PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (i) =>
                                  setState(() => _imageIndex = i),
                              itemBuilder: (ctx, i) {
                                String imageUrl = images[i];
                                if (!imageUrl.startsWith('http')) {
                                  imageUrl = '${AppConfig.apiBaseUrl}$imageUrl';
                                }
                                return CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image_outlined,
                                  size: 80, color: AppColors.textTertiary),
                            ),

                      // Page indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _imageIndex == i ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _imageIndex == i
                                      ? Colors.white
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ─── Product Info ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Catégorie
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Nom
                      Text(
                        product.name,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 12),

                      // Prix + Stock
                      Row(
                        children: [
                          Text(
                            PriceFormatter.format(product.priceAsDouble),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isOutOfStock
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOutOfStock
                                  ? 'Rupture de stock'
                                  : '${product.stockQuantity} en stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOutOfStock
                                    ? AppColors.error
                                    : AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Note / Rating
                      if (product.rating != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: product.rating!,
                              itemBuilder: (ctx, _) => const Icon(
                                Icons.star_rounded,
                                color: AppColors.accent,
                              ),
                              itemSize: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${product.rating!.toStringAsFixed(1)} / 5',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (product.reviewsCount != null)
                              Text(
                                ' (${product.reviewsCount} avis)',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ],

                      // Fournisseur
                      if (product.supplierName != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.store_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Vendu par ${product.supplierName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Description
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        Text(
                          'Description',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Poids / Unité
                      if (product.weight != null) ...[
                        const Divider(),
                        const SizedBox(height: 12),
                        _DetailRow(
                          icon: Icons.scale_outlined,
                          label: 'Poids',
                          value:
                              '${product.weight} ${product.unite ?? 'kg'}',
                        ),
                      ],

                      const SizedBox(height: 100), // espace pour le bouton flottant
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─── Bottom Action Bar ───────────────────────────────────────────
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Sélecteur quantité
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity--)
                            : null,
                      ),
                      Text(
                        '$_quantity',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Bouton ajouter au panier
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              cartNotifier.addItem(product,
                                  quantity: _quantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${product.name} ajouté au panier'),
                                  action: SnackBarAction(
                                    label: 'Voir le panier',
                                    onPressed: () => context.go('/cart'),
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(isOutOfStock
                          ? 'Indisponible'
                          : 'Ajouter au panier'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label : ',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
