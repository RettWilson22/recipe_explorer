import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/meal_summary.dart';

/// A card representing one meal in the home-screen grid. Shows the meal's
/// thumbnail with a gradient overlay so the name stays readable on top of the
/// photo. Tapping the card invokes [onTap], which the parent uses to push the
/// detail route.
class MealCard extends StatelessWidget {
  final MealSummary meal;
  final VoidCallback onTap;

  const MealCard({super.key, required this.meal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cached thumbnail with a graceful placeholder + error icon so a
            // single broken image never breaks the grid layout.
            CachedNetworkImage(
              imageUrl: meal.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, _, __) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.restaurant_rounded, size: 40),
                ),
              ),
            ),
            // Dark gradient at the bottom so the title is readable regardless
            // of how busy the underlying photo is.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.78),
                      Colors.black.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                meal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
