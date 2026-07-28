import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/shop_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../shared/models/category.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../widgets/product_card.dart';
import '../widgets/promo_carousel.dart';
import '../widgets/product_skeleton.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    ref.read(shopFilterProvider.notifier).update(
          (s) => s.copyWith(searchQuery: query),
        );
  }

  void _updateSort(String? value) {
    if (value == null) return;
    ref.read(shopFilterProvider.notifier).update(
          (s) => s.copyWith(sortBy: value),
        );
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(shopFilterProvider.notifier).state = const ShopFilter();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(shopFilterProvider);
    final productsAsync = ref.watch(productsProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);
    final favorites = ref.watch(favoritesProvider);
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authStateProvider);
    final isLoggedIn = auth.asData?.value != null;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ─── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: theme.colorScheme.surface,
            elevation: 0,
            scrolledUnderElevation: 1,
            title: Row(
              children: [
                const AppLogo(size: 32),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diaba',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Marketplace sénégalaise',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Toggle thème
              IconButton(
                icon: Icon(
                  themeMode == ThemeMode.dark
                      ? Icons.wb_sunny_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                tooltip: 'Changer le thème',
              ),
              // Connexion si pas connecté
              if (!isLoggedIn)
                TextButton.icon(
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Connexion'),
                  onPressed: () => context.push('/auth/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _SearchBar(
                controller: _searchController,
                onChanged: _updateSearch,
              ),
            ),
          ),

          // ─── Promo Carousel ───────────────────────────────────────────────
          const SliverToBoxAdapter(child: PromoCarousel()),

          // ─── Filters ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _FilterBar(
              filter: filter,
              categories: categoriesAsync.asData?.value ?? [],
              onSortChanged: _updateSort,
              onCategoryChanged: (id) {
                ref.read(shopFilterProvider.notifier).update(
                      (s) => s.copyWith(selectedCategoryId: id),
                    );
              },
              onClearFilters: filter.isDefault ? null : _clearFilters,
              resultCount: filteredProducts.length,
            ),
          ),

          // ─── Product Grid ─────────────────────────────────────────────────
          productsAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => const ProductSkeleton(),
                  childCount: 12,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: _ErrorView(
                message: error.toString(),
                onRetry: () => ref.invalidate(productsProvider),
              ),
            ),
            data: (_) {
              if (filteredProducts.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyView(
                    hasFilters: !filter.isDefault,
                    onClear: _clearFilters,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final product = filteredProducts[i];
                      final isFav = favorites.any((p) => p.id == product.id);
                      return ProductCard(
                        product: product,
                        isFavorite: isFav,
                        onTap: () => context.push('/product/${product.slug}'),
                        onAddToCart: () {
                          cartNotifier.addItem(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} ajouté au panier'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Voir',
                                onPressed: () => context.go('/cart'),
                              ),
                            ),
                          );
                        },
                        onToggleFavorite: () {
                          favoritesNotifier.toggleFavorite(product);
                        },
                      );
                    },
                    childCount: filteredProducts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar Widget ─────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final ShopFilter filter;
  final List<Category> categories;
  final ValueChanged<String?> onSortChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback? onClearFilters;
  final int resultCount;

  const _FilterBar({
    required this.filter,
    required this.categories,
    required this.onSortChanged,
    required this.onCategoryChanged,
    this.onClearFilters,
    required this.resultCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Catégories + tri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All categories chip
                _CategoryChip(
                  label: 'Toutes',
                  isSelected: filter.selectedCategoryId == null,
                  onTap: () => onCategoryChanged(null),
                ),
                ...categories.map((cat) => _CategoryChip(
                      label: cat.name,
                      isSelected: filter.selectedCategoryId == cat.id.toString(),
                      onTap: () => onCategoryChanged(cat.id.toString()),
                    )),
                const SizedBox(width: 8),
                // Sort dropdown
                DropdownButton<String>(
                  value: filter.sortBy,
                  underline: const SizedBox(),
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('A-Z')),
                    DropdownMenuItem(value: 'price-asc', child: Text('Prix ↑')),
                    DropdownMenuItem(value: 'price-desc', child: Text('Prix ↓')),
                  ],
                  onChanged: onSortChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Résultats + clear
          Row(
            children: [
              Text(
                '$resultCount produit${resultCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (onClearFilters != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClearFilters,
                  child: Text(
                    '· Réinitialiser',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error & Empty Views ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyView({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Aucun produit trouvé',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Essayez de modifier vos critères de recherche'
                : 'La boutique est vide pour le moment',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (hasFilters) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.filter_alt_off_outlined),
              label: const Text('Réinitialiser les filtres'),
            ),
          ],
        ],
      ),
    );
  }
}
