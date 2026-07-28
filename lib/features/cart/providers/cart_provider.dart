import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/cart.dart';
import '../../../shared/models/product.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart());

  void addItem(Product product, {int quantity = 1}) {
    state = state.addItem(product, quantity: quantity);
  }

  void removeItem(int productId) {
    state = state.removeItem(productId);
  }

  void updateQuantity(int productId, int quantity) {
    state = state.updateQuantity(productId, quantity);
  }

  void clear() {
    state = state.clear();
  }
}
