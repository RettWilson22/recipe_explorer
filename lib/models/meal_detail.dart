/// A fully populated meal record returned by TheMealDB `lookup.php?i=<id>`
/// endpoint. Contains the heavyweight fields (instructions, ingredient list,
/// video/source links) that the list screen does not need.
class MealDetail {
  final String id;
  final String name;
  final String thumbnailUrl;
  final String? category;
  final String? area;
  final String? instructions;
  final String? youtubeUrl;
  final String? sourceUrl;
  final List<Ingredient> ingredients;
  final List<String> tags;

  const MealDetail({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.category,
    required this.area,
    required this.instructions,
    required this.youtubeUrl,
    required this.sourceUrl,
    required this.ingredients,
    required this.tags,
  });

  /// Parses a single meal object from TheMealDB. The API stores ingredients in
  /// up to 20 parallel fields (`strIngredient1`..`strIngredient20`) with
  /// matching measurement fields (`strMeasure1`..`strMeasure20`); this factory
  /// stitches the two together and drops empty rows so callers get a clean
  /// list of [Ingredient] objects.
  factory MealDetail.fromJson(Map<String, dynamic> json) {
    final ingredients = <Ingredient>[];
    for (var i = 1; i <= 20; i++) {
      final name = (json['strIngredient$i'] ?? '').toString().trim();
      final measure = (json['strMeasure$i'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      ingredients.add(Ingredient(name: name, measure: measure));
    }

    final tagsRaw = (json['strTags'] ?? '').toString();
    final tags = tagsRaw.isEmpty
        ? <String>[]
        : tagsRaw
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList();

    String? nonEmpty(dynamic v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    return MealDetail(
      id: (json['idMeal'] ?? '').toString(),
      name: (json['strMeal'] ?? '').toString(),
      thumbnailUrl: (json['strMealThumb'] ?? '').toString(),
      category: nonEmpty(json['strCategory']),
      area: nonEmpty(json['strArea']),
      instructions: nonEmpty(json['strInstructions']),
      youtubeUrl: nonEmpty(json['strYoutube']),
      sourceUrl: nonEmpty(json['strSource']),
      ingredients: ingredients,
      tags: tags,
    );
  }
}

/// One row in a meal's ingredient list. [measure] may be empty for ingredients
/// like "salt to taste" where the API omits a measurement.
class Ingredient {
  final String name;
  final String measure;

  const Ingredient({required this.name, required this.measure});

  /// URL of TheMealDB's auto-generated ingredient thumbnail. Used on the detail
  /// screen so each ingredient row has a small icon next to it.
  String get thumbnailUrl {
    final slug = name.trim().replaceAll(' ', '%20');
    return 'https://www.themealdb.com/images/ingredients/$slug-Small.png';
  }
}
