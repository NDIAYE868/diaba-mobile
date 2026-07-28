import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/product.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<Product>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<List<Product>> {
  FavoritesNotifier() : super([]);

  void toggleFavorite(Product product) {
    final exists = state.any((p) => p.id == product.id);
    if (exists) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      state = [...state, product];
    }
  }

  bool isFavorite(int productId) {
    return state.any((p) => p.id == productId);
  }

  void clear() {
    state = [];
  }
}
