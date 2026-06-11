/// A high-level food category (e.g. "Beef", "Dessert", "Seafood") returned by
/// TheMealDB `categories.php` endpoint. Used to drive the category filter row
/// on the home screen.
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

  /// Builds a [MealCategory] from a single JSON object inside the
  /// `categories` array. Missing fields fall back to empty strings so a
  /// partial response from the API never crashes the UI.
  factory MealCategory.fromJson(Map<String, dynamic> json) {
    return MealCategory(
      id: (json['idCategory'] ?? '').toString(),
      name: (json['strCategory'] ?? '').toString(),
      thumbnailUrl: (json['strCategoryThumb'] ?? '').toString(),
      description: (json['strCategoryDescription'] ?? '').toString(),
    );
  }
}
