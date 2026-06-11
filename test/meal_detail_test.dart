import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_explorer/models/meal_detail.dart';
import 'package:recipe_explorer/models/meal_summary.dart';

/// Sanity tests for the JSON -> model conversion. These exercise the parts of
/// the code that are most prone to silent breakage (key typos, off-by-one on
/// the 20 ingredient slots, empty-string normalization).
void main() {
  group('MealSummary.fromJson', () {
    test('reads id, name, thumb', () {
      final m = MealSummary.fromJson({
        'idMeal': '52772',
        'strMeal': 'Teriyaki Chicken Casserole',
        'strMealThumb': 'https://example.com/x.jpg',
      });
      expect(m.id, '52772');
      expect(m.name, 'Teriyaki Chicken Casserole');
      expect(m.thumbnailUrl, 'https://example.com/x.jpg');
    });

    test('tolerates missing fields', () {
      final m = MealSummary.fromJson({});
      expect(m.id, '');
      expect(m.name, '');
      expect(m.thumbnailUrl, '');
    });
  });

  group('MealDetail.fromJson', () {
    test('stitches ingredients and measurements; drops empties', () {
      final detail = MealDetail.fromJson({
        'idMeal': '1',
        'strMeal': 'Test Meal',
        'strMealThumb': '',
        'strCategory': 'Beef',
        'strArea': '  ',
        'strInstructions': 'Cook it.',
        'strYoutube': '',
        'strSource': 'https://example.com',
        'strTags': 'easy, quick, ',
        'strIngredient1': 'Beef',
        'strMeasure1': '1 lb',
        'strIngredient2': 'Salt',
        'strMeasure2': '',
        'strIngredient3': '',
        'strMeasure3': '1 tsp', // orphan measure should be ignored
        'strIngredient4': 'Pepper',
        'strMeasure4': '1/2 tsp',
      });

      expect(detail.id, '1');
      expect(detail.category, 'Beef');
      expect(detail.area, isNull, reason: 'whitespace should normalize to null');
      expect(detail.youtubeUrl, isNull);
      expect(detail.sourceUrl, 'https://example.com');
      expect(detail.tags, ['easy', 'quick']);
      expect(detail.ingredients.length, 3);
      expect(detail.ingredients[0].name, 'Beef');
      expect(detail.ingredients[0].measure, '1 lb');
      expect(detail.ingredients[1].measure, '');
      expect(detail.ingredients[2].name, 'Pepper');
    });

    test('ingredient thumbnail URL encodes spaces', () {
      const i = Ingredient(name: 'Olive Oil', measure: '2 tbsp');
      expect(i.thumbnailUrl,
          'https://www.themealdb.com/images/ingredients/Olive%20Oil-Small.png');
    });
  });
}
