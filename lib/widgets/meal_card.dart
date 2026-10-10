import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/meal_summary.dart';

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
            // Keeps the white title readable on bright photos.
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
