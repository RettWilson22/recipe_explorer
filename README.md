# Recipe Explorer

A Flutter mobile app that loads recipes from a remote REST API
([TheMealDB](https://www.themealdb.com/api.php)), displays them in a scrollable
grid, and opens a detail screen with ingredients, instructions, and source
links for the selected recipe.

Built for COMP 4970 — Mobile Applications Development, Module 4 (Remote Data &
APIs).

## Features

- **Live remote data.** Every screen pulls from TheMealDB's public REST API —
  no hardcoded recipe lists.
- **Category filter & search.** A horizontally-scrolling chip row lets the user
  switch categories (Beef, Chicken, Dessert, Seafood, …) and a search bar
  queries meals by name with input debouncing.
- **Detail screen.** Tapping a card opens a full recipe page with a hero
  image, category/area pills, an ingredient list with thumbnails, full
  instructions, and external links to the YouTube tutorial and original
  source.
- **Polished UI.** Material 3 with a warm orange color scheme, custom card
  styles, image gradients for legibility, and section headers.
- **Graceful failure.** Loading spinners, retry buttons on API errors, friendly
  empty states when a search returns nothing, and per-image error fallbacks so
  one broken thumbnail never breaks the grid.

## Project structure

```
lib/
  main.dart                  // app entry / MaterialApp
  theme/
    app_theme.dart           // Material 3 theme
  models/
    meal_category.dart       // categories.php
    meal_summary.dart        // filter.php / search.php list items
    meal_detail.dart         // lookup.php full record + Ingredient
  services/
    meal_api.dart            // HTTP client + JSON parsing + error mapping
  screens/
    home_screen.dart         // grid + search + category chips
    detail_screen.dart       // hero image + ingredients + instructions
  widgets/
    meal_card.dart           // grid tile
    status_views.dart        // loading / empty / error-retry views
test/
  meal_detail_test.dart      // JSON -> model conversion tests
```

## API

[TheMealDB](https://www.themealdb.com/api.php) — free, public, no API key
required (the demo key `1` is used). Endpoints consumed:

| Endpoint | Purpose |
| --- | --- |
| `GET /categories.php` | Populate the category chip row |
| `GET /filter.php?c=<name>` | Meals inside a selected category |
| `GET /search.php?s=<query>` | Meal search by name |
| `GET /lookup.php?i=<id>` | Full record (instructions + ingredients) |

## Running

```bash
flutter pub get
flutter run
```

## Dependencies

- `http` – REST calls
- `cached_network_image` – cached, placeholder-friendly image loading
- `url_launcher` – open YouTube / source links externally
