import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal_category.dart';
import '../models/meal_detail.dart';
import '../models/meal_summary.dart';

/// An API failure with a message that can be shown to the user.
class MealApiException implements Exception {
  final String message;
  MealApiException(this.message);
  @override
  String toString() => message;
}

/// Client for TheMealDB, using the public test key `1`.
///
/// Endpoints used:
///   * `categories.php`           -> high-level category list
///   * `filter.php?c=<category>`  -> meals inside a category (id/name/thumb)
///   * `search.php?s=<query>`     -> full-text search across meal names
///   * `lookup.php?i=<id>`        -> full record for one meal
class MealApi {
  static const String _base = 'https://www.themealdb.com/api/json/v1/1';

  // Allow tests to inject a mock client. Defaults to a real http.Client.
  final http.Client _client;
  MealApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<MealCategory>> fetchCategories() async {
    final json = await _getJson('$_base/categories.php');
    final list = json['categories'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MealCategory.fromJson)
        .toList();
  }

  Future<List<MealSummary>> fetchMealsByCategory(String categoryName) async {
    final uri = '$_base/filter.php?c=${Uri.encodeQueryComponent(categoryName)}';
    return _parseMealSummaries(await _getJson(uri));
  }

  Future<List<MealSummary>> searchMeals(String query) async {
    final uri = '$_base/search.php?s=${Uri.encodeQueryComponent(query)}';
    final json = await _getJson(uri);
    // search.php returns full records; only the summary fields are kept.
    return _parseMealSummaries(json);
  }

  /// Returns null if there's no meal with that id.
  Future<MealDetail?> fetchMealDetail(String id) async {
    final uri = '$_base/lookup.php?i=${Uri.encodeQueryComponent(id)}';
    final json = await _getJson(uri);
    final meals = json['meals'];
    if (meals is! List || meals.isEmpty) return null;
    final first = meals.first;
    if (first is! Map<String, dynamic>) return null;
    return MealDetail.fromJson(first);
  }

  List<MealSummary> _parseMealSummaries(Map<String, dynamic> json) {
    final meals = json['meals'];
    // TheMealDB sends "meals": null when nothing matches.
    if (meals is! List) return const [];
    return meals
        .whereType<Map<String, dynamic>>()
        .map(MealSummary.fromJson)
        .toList();
  }

  /// GETs [url] and decodes a JSON object. Network errors, timeouts, non-200
  /// responses and bad JSON all become a [MealApiException].
  Future<Map<String, dynamic>> _getJson(String url) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw MealApiException('Network error. Check your connection.');
    }

    if (response.statusCode != 200) {
      throw MealApiException(
        'Server returned ${response.statusCode}. Please try again.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Falls through to the error below.
    }
    throw MealApiException('Could not read the response from the server.');
  }

  void dispose() => _client.close();
}
