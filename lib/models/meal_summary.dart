/// A lightweight meal record returned by TheMealDB `filter.php` endpoint.
///
/// `filter.php` only returns three fields per meal (`idMeal`, `strMeal`,
/// `strMealThumb`), so this model is intentionally small. The full record is
/// loaded lazily by [MealApi.fetchMealDetail] when the user opens a detail
/// page.
class MealSummary {
  final String id;
  final String name;
  final String thumbnailUrl;

  const MealSummary({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory MealSummary.fromJson(Map<String, dynamic> json) {
    return MealSummary(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? '').toString(),
      thumbnailUrl: (json['strMealThumb'] ?? '').toString(),
    );
  }
}
