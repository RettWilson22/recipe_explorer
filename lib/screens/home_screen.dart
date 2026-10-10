import 'dart:async';

import 'package:flutter/material.dart';

import '../models/meal_category.dart';
import '../models/meal_summary.dart';
import '../services/auth_service.dart';
import '../services/meal_api.dart';
import '../widgets/meal_card.dart';
import '../widgets/status_views.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MealApi _api = MealApi();
  final AuthService _auth = AuthService();

  late Future<List<MealCategory>> _categoriesFuture;
  late Future<List<MealSummary>> _mealsFuture;

  // Beef has plenty of meals, so the grid isn't empty on first load.
  String _selectedCategory = 'Beef';

  /// When non-empty, the grid shows search results instead of the category.
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _api.fetchCategories();
    _mealsFuture = _api.fetchMealsByCategory(_selectedCategory);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _api.dispose();
    super.dispose();
  }

  void _reloadMeals() {
    setState(() {
      if (_searchQuery.isNotEmpty) {
        _mealsFuture = _api.searchMeals(_searchQuery);
      } else {
        _mealsFuture = _api.fetchMealsByCategory(_selectedCategory);
      }
    });
  }

  void _onCategoryTap(String name) {
    // Tapping a category leaves search mode, including a search still waiting
    // on the debounce.
    _debounce?.cancel();
    _searchController.clear();
    _searchQuery = '';
    setState(() {
      _selectedCategory = name;
      _mealsFuture = _api.fetchMealsByCategory(name);
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final trimmed = value.trim();
      if (trimmed == _searchQuery) return;
      setState(() {
        _searchQuery = trimmed;
        _mealsFuture = trimmed.isEmpty
            ? _api.fetchMealsByCategory(_selectedCategory)
            : _api.searchMeals(trimmed);
      });
    });
  }

  void _openDetail(MealSummary meal) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailScreen(meal: meal)),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will be returned to the sign-in screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Explorer'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reloadMeals,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoryRow(),
            const SizedBox(height: 4),
            Expanded(child: _buildMealGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search recipes…',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 48,
      child: FutureBuilder<List<MealCategory>>(
        future: _categoriesFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          if (snap.hasError) return const SizedBox.shrink();
          final categories = snap.data ?? const [];
          if (categories.isEmpty) return const SizedBox.shrink();

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final cat = categories[i];
              final isSelected =
                  _searchQuery.isEmpty && cat.name == _selectedCategory;
              return ChoiceChip(
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) => _onCategoryTap(cat.name),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMealGrid() {
    return FutureBuilder<List<MealSummary>>(
      future: _mealsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: 'Loading recipes…');
        }
        if (snap.hasError) {
          return ErrorRetryView(
            message: snap.error is MealApiException
                ? (snap.error as MealApiException).message
                : 'Unexpected error: ${snap.error}',
            onRetry: _reloadMeals,
          );
        }
        final meals = snap.data ?? const [];
        if (meals.isEmpty) {
          return EmptyView(
            title: _searchQuery.isEmpty
                ? 'No recipes in this category'
                : 'No recipes match "$_searchQuery"',
            message: 'Try a different category or search term.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _reloadMeals();
            await _mealsFuture;
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemCount: meals.length,
            itemBuilder: (context, i) {
              final meal = meals[i];
              return MealCard(meal: meal, onTap: () => _openDetail(meal));
            },
          ),
        );
      },
    );
  }
}
