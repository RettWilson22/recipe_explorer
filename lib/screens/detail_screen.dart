import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/meal_detail.dart';
import '../models/meal_summary.dart';
import '../services/meal_api.dart';
import '../widgets/status_views.dart';

/// Detail screen for one meal. Receives a [MealSummary] (id + name + thumb)
/// from the home screen and immediately fires off the full lookup. The header
/// shows the thumbnail straight from the summary so users see SOMETHING
/// instant while the rest of the record loads.
class DetailScreen extends StatefulWidget {
  final MealSummary meal;
  const DetailScreen({super.key, required this.meal});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final MealApi _api = MealApi();
  late Future<MealDetail?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = _api.fetchMealDetail(widget.meal.id);
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _detailFuture = _api.fetchMealDetail(widget.meal.id);
    });
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<MealDetail?>(
        future: _detailFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _ScaffoldShell(
              title: widget.meal.name,
              thumbnailUrl: widget.meal.thumbnailUrl,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: LoadingView(label: 'Loading recipe…'),
              ),
            );
          }
          if (snap.hasError) {
            return _ScaffoldShell(
              title: widget.meal.name,
              thumbnailUrl: widget.meal.thumbnailUrl,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: ErrorRetryView(
                  message: snap.error is MealApiException
                      ? (snap.error as MealApiException).message
                      : 'Unexpected error: ${snap.error}',
                  onRetry: _retry,
                ),
              ),
            );
          }

          final detail = snap.data;
          if (detail == null) {
            return _ScaffoldShell(
              title: widget.meal.name,
              thumbnailUrl: widget.meal.thumbnailUrl,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: EmptyView(
                  icon: Icons.no_food_rounded,
                  title: 'Recipe details unavailable',
                  message:
                      'The API did not return details for this recipe. '
                      'Please try another.',
                ),
              ),
            );
          }

          return _ScaffoldShell(
            title: detail.name,
            thumbnailUrl: detail.thumbnailUrl,
            child: _DetailBody(detail: detail, onOpenUrl: _openUrl),
          );
        },
      ),
    );
  }
}

/// The shared layout chrome used by every detail-screen state. Pulls the hero
/// image up into the app bar via a [SliverAppBar] so the header looks polished
/// even when the body is still loading.
class _ScaffoldShell extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final Widget child;

  const _ScaffoldShell({
    required this.title,
    required this.thumbnailUrl,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 260,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                shadows: [
                  Shadow(blurRadius: 8, color: Colors.black54),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (context, _, __) => Container(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Center(
                      child: Icon(Icons.restaurant_rounded, size: 56),
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.45, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: child),
      ],
    );
  }
}

/// Renders the loaded [MealDetail] inside the scroll view: meta-chips,
/// ingredients table, instructions text, and any source / video links the API
/// gave us.
class _DetailBody extends StatelessWidget {
  final MealDetail detail;
  final void Function(String url) onOpenUrl;
  const _DetailBody({required this.detail, required this.onOpenUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetaChips(context),
          if (detail.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in detail.tags)
                  Chip(
                    label: Text(t),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          const _SectionHeader(icon: Icons.shopping_basket_rounded, label: 'Ingredients'),
          const SizedBox(height: 12),
          _IngredientsList(detail: detail),
          const SizedBox(height: 28),
          const _SectionHeader(icon: Icons.menu_book_rounded, label: 'Instructions'),
          const SizedBox(height: 12),
          Text(
            detail.instructions?.trim().isNotEmpty == true
                ? detail.instructions!.trim()
                : 'No instructions were provided for this recipe.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          if (detail.youtubeUrl != null || detail.sourceUrl != null) ...[
            const SizedBox(height: 28),
            const _SectionHeader(icon: Icons.link_rounded, label: 'Links'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (detail.youtubeUrl != null)
                  FilledButton.icon(
                    onPressed: () => onOpenUrl(detail.youtubeUrl!),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Watch tutorial'),
                  ),
                if (detail.sourceUrl != null)
                  OutlinedButton.icon(
                    onPressed: () => onOpenUrl(detail.sourceUrl!),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Original recipe'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaChips(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <Widget>[];

    if (detail.category != null) {
      items.add(_MetaPill(
        icon: Icons.local_dining_rounded,
        text: detail.category!,
        color: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ));
    }
    if (detail.area != null) {
      items.add(_MetaPill(
        icon: Icons.public_rounded,
        text: detail.area!,
        color: scheme.secondaryContainer,
        foreground: scheme.onSecondaryContainer,
      ));
    }
    items.add(_MetaPill(
      icon: Icons.format_list_numbered_rounded,
      text: '${detail.ingredients.length} ingredients',
      color: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
    ));

    return Wrap(spacing: 8, runSpacing: 8, children: items);
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 22, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color foreground;
  const _MetaPill({
    required this.icon,
    required this.text,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientsList extends StatelessWidget {
  final MealDetail detail;
  const _IngredientsList({required this.detail});

  @override
  Widget build(BuildContext context) {
    if (detail.ingredients.isEmpty) {
      return Text(
        'No ingredients were provided for this recipe.',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < detail.ingredients.length; i++) ...[
            if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: detail.ingredients[i].thumbnailUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, _, __) => Container(
                        width: 40,
                        height: 40,
                        color: scheme.surfaceVariant,
                        child: const Icon(Icons.eco_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      detail.ingredients[i].name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    detail.ingredients[i].measure,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
