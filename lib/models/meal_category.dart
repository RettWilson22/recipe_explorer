/// A category from `categories.php`, like "Beef" or "Dessert".
class MealCategory {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String description;

  const MealCategory({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.description,
  });

  /// Missing fields become empty strings.
  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: (json['idCategory'] ?? '').toString(),
      name: (json['strCategory'] ?? '').toString(),
      thumbnailUrl: (json['strCategoryThumb'] ?? '').toString(),
      description: (json['strCategoryDescription'] ?? '').toString(),
    );
  }
}
