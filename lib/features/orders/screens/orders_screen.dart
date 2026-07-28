import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/utils/price_formatter.dart';
import '../../../shared/models/order.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final ordersProvider = FutureProvider.family<List<Order>, String?>((ref, statusFilter) async {
  final dio = ref.read(dioProvider);
  try {
    final queryParams = statusFilter != null && statusFilter != 'all'
        ? {'status': statusFilter}
        : <String, dynamic>{};
    final response = await dio.get('/orders/my-orders/', queryParameters: queryParams);
    final data = response.data;

    if (data is List) {
      return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    } else if (data is Map && data.containsKey('orders')) {
      final orders = data['orders'] as List;
      return orders.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } on DioException catch (e) {
    throw AppException.fromDioError(e);
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _statusFilter = 'all';

  static const _filters = [
    ('all', 'Toutes'),
    ('pending', 'En attente'),
    ('confirmed', 'Confirmées'),
    ('processing', 'En traitement'),
    ('shipped', 'Expédiées'),
    ('at_depot', 'Au dépôt'),
    ('ready_for_pickup', 'À récupérer'),
    ('delivered', 'Livrées'),
    ('cancelled', 'Annulées'),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isLoggedIn = auth.asData?.value != null;

    if (!isLoggedIn) {
      return _NotLoggedInView(onLogin: () => context.push('/auth/login'));
    }

    final ordersAsync = ref.watch(ordersProvider(_statusFilter));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: Column(
        children: [
          // ─── Filter chips ──────────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (ctx, i) {
                final (value, label) = _filters[i];
                final isSelected = _statusFilter == value;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Orders list ───────────────────────────────────────────────
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(error.toString()),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(ordersProvider(_statusFilter)),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 80, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune commande',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _statusFilter == 'all'
                              ? "Vous n'avez pas encore passé de commande."
                              : 'Aucune commande avec ce statut.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  Color get _statusColor {
    switch (widget.order.status) {
      case OrderStatus.pending: return AppColors.statusPending;
      case OrderStatus.confirmed: return AppColors.statusConfirmed;
      case OrderStatus.processing: return AppColors.statusProcessing;
      case OrderStatus.shipped: return AppColors.statusShipped;
      case OrderStatus.atDepot: return AppColors.statusAtDepot;
      case OrderStatus.readyForPickup: return AppColors.statusReady;
      case OrderStatus.delivered: return AppColors.statusDelivered;
      case OrderStatus.cancelled: return AppColors.statusCancelled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // ─── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusBadge(
                        label: order.statusDisplay.isNotEmpty
                            ? order.statusDisplay
                            : order.status.label,
                        color: _statusColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(order.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PriceFormatter.format(order.totalAmountDouble),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${order.itemsCount} article${order.itemsCount > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(
                        _expanded ? 'Réduire' : 'Détails',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Expanded details ────────────────────────────────────────────
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Items
                  ...order.items.map((item) => _OrderItemRow(item: item)),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Address
                  if (order.shippingAddress.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.shippingAddress,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Depot
                  if (order.shipmentDepotName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.store_outlined,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.shipmentDepotName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Payment
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payment_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        order.paymentTimingDisplay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '${item.quantity}×',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.productName,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            PriceFormatter.format(
                double.tryParse(item.totalPrice) ?? 0),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  final VoidCallback onLogin;
  const _NotLoggedInView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: AppColors.textTertiary),
              const SizedBox(height: 24),
              Text(
                'Connectez-vous pour voir vos commandes',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
