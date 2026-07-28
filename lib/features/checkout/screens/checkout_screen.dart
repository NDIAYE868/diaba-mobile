import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/order.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../shared/utils/price_formatter.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final depotsProvider = FutureProvider<List<Depot>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/shipping/depots/');
    final data = response.data;
    if (data is List) {
      return data.map((e) => Depot.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  } on DioException catch (e) {
    throw AppException.fromDioError(e);
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  String _paymentTiming = 'pay_after';
  Depot? _selectedDepot;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final cart = ref.read(cartProvider);
      final dio = ref.read(dioProvider);

      final shippingAddress = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'street': _streetController.text.trim(),
        'city': _cityController.text.trim(),
        'country': 'Sénégal',
      };

      final payload = {
        'shipping_address': shippingAddress,
        'payment_timing': _paymentTiming,
        if (_selectedDepot != null) 'commune_id': _selectedDepot!.id,
        'phone': _phoneController.text.trim(),
        'cart_items': cart.toApiPayload(),
      };

      await dio.post('/orders/place/', data: payload);

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Commande passée ! 🎉',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre commande a été enregistrée. Vous recevrez une confirmation par email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/orders');
                },
                child: const Text('Voir mes commandes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final depotsAsync = ref.watch(depotsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commander'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _placeOrder();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (ctx, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_currentStep < 2) {
                              details.onStepContinue?.call();
                            } else {
                              _placeOrder();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep < 2 ? 'Continuer' : 'Confirmer la commande'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Retour'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            // ─── Step 1: Adresse ──────────────────────────────────────────
            Step(
              title: const Text('Adresse de livraison'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Nom complet',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _streetController,
                    label: 'Rue / Quartier',
                    icon: Icons.home_outlined,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildField(
                    controller: _cityController,
                    label: 'Ville',
                    icon: Icons.location_city_outlined,
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                  ),
                ],
              ),
            ),

            // ─── Step 2: Dépôt + Paiement ─────────────────────────────────
            Step(
              title: const Text('Dépôt & Paiement'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choisir un dépôt de retrait',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  depotsAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erreur: $e'),
                    data: (depots) => DropdownButtonFormField<Depot?>(
                      value: _selectedDepot,
                      hint: const Text('Sélectionner un dépôt (optionnel)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Livraison à domicile')),
                        ...depots.map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d.name, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (d) => setState(() => _selectedDepot = d),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.store_outlined, size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Mode de paiement', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    value: 'pay_before',
                    groupValue: _paymentTiming,
                    title: 'Payer avant livraison',
                    subtitle: 'Paiement effectué lors de la commande',
                    icon: Icons.credit_card_outlined,
                    onChanged: (v) => setState(() => _paymentTiming = v!),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    value: 'pay_after',
                    groupValue: _paymentTiming,
                    title: 'Payer à la livraison',
                    subtitle: 'Vous payez quand vous récupérez votre colis',
                    icon: Icons.payments_outlined,
                    onChanged: (v) => setState(() => _paymentTiming = v!),
                  ),
                ],
              ),
            ),

            // ─── Step 3: Récapitulatif ─────────────────────────────────────
            Step(
              title: const Text('Récapitulatif'),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Articles
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}× ',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              PriceFormatter.format(item.totalPrice),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                        PriceFormatter.format(cart.total),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.person_outline, text: _nameController.text),
                  _InfoRow(icon: Icons.phone_outlined, text: _phoneController.text),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: [
                      _streetController.text,
                      _cityController.text,
                    ].where((s) => s.isNotEmpty).join(', '),
                  ),
                  if (_selectedDepot != null)
                    _InfoRow(
                        icon: Icons.store_outlined, text: _selectedDepot!.name),
                  _InfoRow(
                    icon: Icons.payment_outlined,
                    text: _paymentTiming == 'pay_before'
                        ? 'Paiement avant livraison'
                        : 'Paiement à la livraison',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
