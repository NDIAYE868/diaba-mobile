import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.priceAsDouble * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }
}

class Cart {
  final List<CartItem> items;

  const Cart({this.items = const []});

  double get total => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  int get uniqueItemCount => items.length;
  bool get isEmpty => items.isEmpty;

  Cart addItem(Product product, {int quantity = 1}) {
    final existingIndex = items.indexWhere((i) => i.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(items);
      updated[existingIndex] = CartItem(
        product: product,
        quantity: updated[existingIndex].quantity + quantity,
      );
      return Cart(items: updated);
    }
    return Cart(items: [...items, CartItem(product: product, quantity: quantity)]);
  }

  Cart removeItem(int productId) {
    return Cart(items: items.where((i) => i.product.id != productId).toList());
  }

  Cart updateQuantity(int productId, int quantity) {
    if (quantity <= 0) return removeItem(productId);
    final updated = items.map((item) {
      if (item.product.id == productId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    return Cart(items: updated);
  }

  Cart clear() => const Cart();

  List<Map<String, dynamic>> toApiPayload() {
    return items.map((item) => {
      'product_id': item.product.id,
      'quantity': item.quantity,
    }).toList();
  }
}
