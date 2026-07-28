import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/product.dart';
import '../../../shared/models/category.dart';

// ─── Products Provider ────────────────────────────────────────────────────────

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final dio = ref.read(dioProvider);
  final repo = ProductRepository(dio);
  return await repo.getAllProducts();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final dio = ref.read(dioProvider);
  final repo = ProductRepository(dio);
  return await repo.getCategories();
});

final productDetailProvider = FutureProvider.family<Product, String>(
  (ref, slug) async {
    final dio = ref.read(dioProvider);
    final repo = ProductRepository(dio);
    return await repo.getProductBySlug(slug);
  },
);

// ─── Filter State ─────────────────────────────────────────────────────────────

class ShopFilter {
  final String searchQuery;
  final String? selectedCategoryId;
  final String sortBy;

  const ShopFilter({
    this.searchQuery = '',
    this.selectedCategoryId,
    this.sortBy = 'name',
  });

  ShopFilter copyWith({
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? sortBy,
  }) {
    return ShopFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get isDefault =>
      searchQuery.isEmpty && selectedCategoryId == null && sortBy == 'name';
}

final shopFilterProvider = StateProvider<ShopFilter>((ref) {
  return const ShopFilter();
});

/// Produits filtrés et triés selon le filtre actif
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final filter = ref.watch(shopFilterProvider);
  final categoriesAsync = ref.watch(categoriesProvider);

  return productsAsync.when(
    data: (products) {
      var result = List<Product>.from(products);

      // Recherche texte
      if (filter.searchQuery.isNotEmpty) {
        final q = filter.searchQuery.toLowerCase();
        result = result.where((p) {
          return p.name.toLowerCase().contains(q) ||
              (p.description?.toLowerCase().contains(q) ?? false) ||
              (p.categoryName?.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      // Filtre catégorie
      if (filter.selectedCategoryId != null) {
        final categoryId = int.tryParse(filter.selectedCategoryId!);
        if (categoryId != null) {
          // Trouver les IDs descendants
          final categories = categoriesAsync.asData?.value ?? [];
          final ids = _getDescendantIds(categoryId, categories);
          result = result
              .where((p) => p.category != null && ids.contains(p.category))
              .toList();
        }
      }

      // Tri
      result.sort((a, b) {
        switch (filter.sortBy) {
          case 'price-asc':
            return a.priceAsDouble.compareTo(b.priceAsDouble);
          case 'price-desc':
            return b.priceAsDouble.compareTo(a.priceAsDouble);
          case 'name':
          default:
            return a.name.compareTo(b.name);
        }
      });

      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

Set<int> _getDescendantIds(int categoryId, List<Category> categories) {
  Category? findById(int id, List<Category> cats) {
    for (final cat in cats) {
      if (cat.id == id) return cat;
      final found = findById(id, cat.children);
      if (found != null) return found;
    }
    return null;
  }

  final cat = findById(categoryId, categories);
  return cat?.descendantIds ?? {categoryId};
}

// ─── Repository ───────────────────────────────────────────────────────────────

class ProductRepository {
  final Dio _dio;
  ProductRepository(this._dio);

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _dio.get('/products/');
      final data = response.data;

      if (data is List) {
        return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data.containsKey('results')) {
        final results = data['results'] as List;
        return results.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<Product> getProductBySlug(String slug) async {
    try {
      final response = await _dio.get('/products/$slug/');
      return Product.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _dio.get('/products/categories/');
      final data = response.data;

      if (data is List) {
        return data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw AppException.fromDioError(e);
    }
  }
}
