import '../../core/constants/app_config.dart';

class Product {
  final int id;
  final String name;
  final String slug;
  final String price;
  final int stockQuantity;
  final String sku;
  final String status;
  final bool isActive;
  final int? supplier;
  final String? supplierName;
  final int? category;
  final String? categoryName;
  final String? description;
  final String? weight;
  final String? unite;
  final String? createdAt;
  final String? updatedAt;
  final List<String>? images;
  final double? rating;
  final int? reviewsCount;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.stockQuantity,
    required this.sku,
    required this.status,
    required this.isActive,
    this.supplier,
    this.supplierName,
    this.category,
    this.categoryName,
    this.description,
    this.weight,
    this.unite,
    this.createdAt,
    this.updatedAt,
    this.images,
    this.rating,
    this.reviewsCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      price: json['price'] as String,
      stockQuantity: json['stock_quantity'] as int? ?? 0,
      sku: json['sku'] as String? ?? '',
      status: json['status'] as String? ?? 'approved',
      isActive: json['is_active'] as bool? ?? true,
      supplier: json['supplier'] as int?,
      supplierName: json['supplier_name'] as String?,
      category: json['category'] as int?,
      categoryName: json['category_name'] as String?,
      description: json['description'] as String?,
      weight: json['weight'] as String?,
      unite: json['unite'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      rating: _parseRating(json['rating']),
      reviewsCount: json['reviews_count'] as int?,
    );
  }

  static double? _parseRating(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Retourne l'URL de l'image principale
  String? get imageUrl {
    if (images == null || images!.isEmpty) return null;
    final path = images!.first;
    if (path.startsWith('http')) return path;
    return '${AppConfig.apiBaseUrl}$path';
  }

  /// Prix formaté en XOF
  double get priceAsDouble => double.tryParse(price) ?? 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'price': price,
    'stock_quantity': stockQuantity,
    'sku': sku,
    'status': status,
    'is_active': isActive,
    'supplier': supplier,
    'supplier_name': supplierName,
    'category': category,
    'category_name': categoryName,
    'description': description,
    'images': images,
    'rating': rating,
    'reviews_count': reviewsCount,
  };
}

class PaginatedProducts {
  final int count;
  final String? next;
  final String? previous;
  final List<Product> results;

  const PaginatedProducts({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    return PaginatedProducts(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: rawResults.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
