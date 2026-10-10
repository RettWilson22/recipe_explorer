/// The id, name and thumbnail that `filter.php` returns for each meal. The
/// full record is fetched when a detail page opens.
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
