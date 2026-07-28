import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/cart_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/price_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mon Panier (${cart.uniqueItemCount})'),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vider le panier'),
                    content: const Text('Supprimer tous les articles ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Annuler')),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Vider',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Vider'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart(onBrowse: () => context.go('/'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return _CartItemTile(
                        item: item,
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeItem(item.product.id),
                        onIncrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.product.id, item.quantity + 1),
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.product.id, item.quantity - 1),
                      );
                    },
                  ),
                ),

                // ─── Order Summary ─────────────────────────────────────────
                _OrderSummary(
                  cart: cart,
                  onCheckout: () => context.push('/checkout'),
                ),
              ],
            ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onRemove;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartItemTile({
    required this.item,
    required this.onRemove,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = item.product;

    return Container(
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
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Quantity + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                color: AppColors.textSecondary,
                tooltip: 'Supprimer',
              ),
              Row(
                children: [
                  _QtyButton(icon: Icons.remove, onTap: onDecrement),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _QtyButton(icon: Icons.add, onTap: onIncrement),
                ],
              ),
              Text(
                PriceFormatter.format(item.totalPrice),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final dynamic cart;
  final VoidCallback onCheckout;

  const _OrderSummary({required this.cart, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${cart.totalItems} article${cart.totalItems > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium),
              Text(
                PriceFormatter.format(cart.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onCheckout,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('Commander'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onBrowse;

  const _EmptyCart({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text('Panier vide', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des produits depuis la boutique',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onBrowse,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Aller à la boutique'),
          ),
        ],
      ),
    );
  }
}
