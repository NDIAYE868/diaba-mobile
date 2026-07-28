class Category {
  final int id;
  final String name;
  final String? description;
  final int? parent;
  final List<Category> children;
  final String? image;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.parent,
    this.children = const [],
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'] as List<dynamic>? ?? [];
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      parent: json['parent'] as int?,
      image: json['image'] as String?,
      children: childrenJson
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Retourne tous les IDs descendants (enfants récursifs)
  Set<int> get descendantIds {
    final ids = <int>{id};
    for (final child in children) {
      ids.addAll(child.descendantIds);
    }
    return ids;
  }
}
