import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/meal_category.dart';
import '../models/meal_detail.dart';
import '../models/meal_summary.dart';

/// Thrown when an API call fails (network down, non-200 response, malformed
/// JSON). The screens catch this and show a friendly retry view instead of
/// letting the exception crash the app.
class MealApiException implements Exception {
  final String message;
  MealApiException(this.message);
  @override
  String toString() => message;
}

/// Thin wrapper around TheMealDB's public REST API.
///
/// TheMealDB is a free, key-less recipe API. We use the public test key `1`
/// which is the standard demo key advertised on themealdb.com.
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

  /// Returns every top-level meal category. Used to render the chip row on the
  /// home screen.
  Future<List<MealCategory>> fetchCategories() async {
    final json = await _getJson('$_base/categories.php');
    final list = json['categories'];
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(MealCategory.fromJson)
        .toList();
  }

  /// Returns meal summaries inside [categoryName] (e.g. "Beef", "Dessert").
  /// `filter.php` returns `{"meals": null}` for empty categories — we normalize
  /// that to an empty list so the caller doesn't have to special-case null.
  Future<List<MealSummary>> fetchMealsByCategory(String categoryName) async {
    final uri = '$_base/filter.php?c=${Uri.encodeQueryComponent(categoryName)}';
    return _parseMealSummaries(await _getJson(uri));
  }

  /// Full-text search across meal names. Same null-meals handling as
  /// [fetchMealsByCategory].
  Future<List<MealSummary>> searchMeals(String query) async {
    final uri = '$_base/search.php?s=${Uri.encodeQueryComponent(query)}';
    final json = await _getJson(uri);
    // `search.php` returns the FULL meal record per hit, but we only need the
    // summary fields here; MealSummary.fromJson tolerates extra fields.
    return _parseMealSummaries(json);
  }

  /// Fetches the complete record for a single meal id, including instructions
  /// and ingredients. Returns null if TheMealDB has no meal with that id.
  Future<MealDetail?> fetchMealDetail(String id) async {
    final uri = '$_base/lookup.php?i=${Uri.encodeQueryComponent(id)}';
    final json = await _getJson(uri);
    final meals = json['meals'];
    if (meals is! List || meals.isEmpty) return null;
    final first = meals.first;
    if (first is! Map<String, dynamic>) return null;
    return MealDetail.fromJson(first);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<MealSummary> _parseMealSummaries(Map<String, dynamic> json) {
    final meals = json['meals'];
    if (meals is! List) return const []; // null or unexpected shape
    return meals
        .whereType<Map<String, dynamic>>()
        .map(MealSummary.fromJson)
        .toList();
  }

  /// Issues a GET, validates the status code, and decodes the body as JSON.
  /// Any failure — DNS error, timeout, non-200, malformed body — is mapped to
  /// a [MealApiException] with a human-readable message.
  Future<Map<String, dynamic>> _getJson(String url) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw MealApiException('Network error. Check your connection.');
    }

    if (response.statusCode != 200) {
      throw MealApiException(
        'Server returned ${response.statusCode}. Please try again.',
      );
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Top-level JSON was not an object.');
      }
      return decoded;
    } catch (_) {
      throw MealApiException('Could not read the response from the server.');
    }
  }

  void dispose() => _client.close();
}
