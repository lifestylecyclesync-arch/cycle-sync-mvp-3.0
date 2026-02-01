import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/domain/entities/recipe.dart';
import 'package:cycle_sync_mvp_2/presentation/providers/recipe_provider.dart';

/// Recipes Screen - Browse and save recipes
class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: SearchBar(
              controller: _searchController,
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).setQuery(value);
              },
              leading: Icon(Icons.search, color: AppColors.textSecondary),
              hintText: 'Search recipes...',
            ),
          ),

          // Tabs: Discover | Favorites
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Discover'),
              Tab(text: 'Favorites'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDiscoverTab(context),
                _buildFavoritesTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedPhase = ref.watch(phaseFilterProvider);

    return CustomScrollView(
      slivers: [
        // Phase filter chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: selectedPhase == null,
                    onSelected: (selected) {
                      ref
                          .read(phaseFilterProvider.notifier)
                          .setPhase(selected ? null : null);
                    },
                  ),
                  ...['Menstrual', 'Follicular', 'Ovulation', 'Luteal']
                      .map((phase) => Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: FilterChip(
                              label: Text(phase),
                              selected: selectedPhase == phase,
                              onSelected: (selected) {
                                ref
                                    .read(phaseFilterProvider.notifier)
                                    .setPhase(selected ? phase : null);
                              },
                            ),
                          )),
                ],
              ),
            ),
          ),
        ),

        // Recipe list
        if (searchQuery.isNotEmpty)
          _buildSearchResults(searchQuery)
        else if (selectedPhase != null)
          _buildPhaseRecipes(selectedPhase)
        else
          _buildRandomRecipes(),
      ],
    );
  }

  Widget _buildSearchResults(String query) {
    return ref.watch(recipeSearchProvider(query)).when(
      data: (recipes) {
        if (recipes.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No recipes found for "$query"',
                style: AppTypography.body2,
              ),
            ),
          );
        }
        return _buildRecipeGrid(recipes);
      },
      loading: () => SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverFillRemaining(
        child: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildPhaseRecipes(String phase) {
    return ref.watch(recipesByPhaseProvider(phase)).when(
      data: (recipes) => _buildRecipeGrid(recipes),
      loading: () => SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverFillRemaining(
        child: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildRandomRecipes() {
    return ref.watch(randomRecipesProvider).when(
      data: (recipes) => _buildRecipeGrid(recipes),
      loading: () => SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => SliverFillRemaining(
        child: Center(
          child: Text('Error: $err'),
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(List<Recipe> recipes) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _RecipeCard(recipe: recipes[index]),
        childCount: recipes.length,
      ),
    );
  }

  Widget _buildFavoritesTab(BuildContext context) {
    return ref.watch(userFavoritesProvider).when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline,
                    size: 64, color: AppColors.textTertiary),
                SizedBox(height: AppSpacing.lg),
                Text(
                  'No favorite recipes yet',
                  style: AppTypography.subtitle2,
                ),
                Text(
                  'Add recipes from the Discover tab',
                  style: AppTypography.body2
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            final fav = favorites[index];
            return _FavoriteRecipeCard(favorite: fav);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(),
      ),
      error: (err, stack) => Center(
        child: Text('Error: $err'),
      ),
    );
  }
}

/// Recipe card for grid display
class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Navigate to recipe detail
        _showRecipeDetail(context, ref, recipe);
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: recipe.image.isNotEmpty
                    ? Image.network(
                        recipe.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image_not_supported);
                        },
                      )
                    : Icon(Icons.restaurant),
              ),
            ),

            // Title and info
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 12, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text(
                        '${recipe.readyInMinutes} min',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetail(
      BuildContext context, WidgetRef ref, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecipeDetailSheet(recipe: recipe),
    );
  }
}

/// Favorite recipe list card
class _FavoriteRecipeCard extends ConsumerWidget {
  final FavoriteRecipe favorite;

  const _FavoriteRecipeCard({required this.favorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: Image.network(
                  favorite.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.restaurant);
                  },
                ),
              ),
            ),

            SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.title,
                    style: AppTypography.subtitle2,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      favorite.phaseName,
                      style: AppTypography.caption,
                    ),
                  ),
                  if (favorite.notes.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      favorite.notes,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ]
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                ref.read(removeFavoriteProvider(favorite.spoonacularId));
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Recipe detail bottom sheet
class _RecipeDetailSheet extends ConsumerWidget {
  final Recipe recipe;

  const _RecipeDetailSheet({required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorited = ref.watch(isFavoritedProvider(recipe.id));

    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                child: Image.network(
                  recipe.image,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Title and quick info
              Text(recipe.title, style: AppTypography.header2),
              SizedBox(height: AppSpacing.sm),

              Row(
                children: [
                  _InfoChip(
                      icon: Icons.schedule,
                      label: '${recipe.readyInMinutes} min'),
                  SizedBox(width: AppSpacing.sm),
                  _InfoChip(
                      icon: Icons.people,
                      label: '${recipe.servings} servings'),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Dietary tags
              if (recipe.vegetarian || recipe.vegan || recipe.glutenFree)
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    if (recipe.vegetarian)
                      Chip(
                        label: Text('Vegetarian'),
                        backgroundColor: Colors.green[100],
                      ),
                    if (recipe.vegan)
                      Chip(
                        label: Text('Vegan'),
                        backgroundColor: Colors.green[100],
                      ),
                    if (recipe.glutenFree)
                      Chip(
                        label: Text('Gluten Free'),
                        backgroundColor: Colors.amber[100],
                      ),
                  ],
                ),

              SizedBox(height: AppSpacing.lg),

              // Nutrition
              Text('Nutrition (per serving)', style: AppTypography.subtitle2),
              SizedBox(height: AppSpacing.sm),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 2,
                children: [
                  _NutritionItem(
                      label: 'Calories',
                      value: recipe.nutrition.calories.toStringAsFixed(0)),
                  _NutritionItem(
                      label: 'Protein',
                      value: '${recipe.nutrition.protein.toStringAsFixed(1)}g'),
                  _NutritionItem(
                      label: 'Carbs',
                      value: '${recipe.nutrition.carbs.toStringAsFixed(1)}g'),
                  _NutritionItem(
                      label: 'Fat',
                      value: '${recipe.nutrition.fat.toStringAsFixed(1)}g'),
                ],
              ),

              SizedBox(height: AppSpacing.lg),

              // Favorite button
              isFavorited.when(
                data: (favorited) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: favorited
                        ? () => ref.read(removeFavoriteProvider(recipe.id))
                        : () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  _AddToFavoritesDialog(recipe: recipe),
                            );
                          },
                    icon: Icon(
                        favorited ? Icons.bookmark : Icons.bookmark_outline),
                    label: Text(
                      favorited ? 'Remove from Favorites' : 'Add to Favorites',
                    ),
                  ),
                ),
                loading: () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, stack) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null,
                    child: Text('Error'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add to favorites dialog
class _AddToFavoritesDialog extends ConsumerStatefulWidget {
  final Recipe recipe;

  const _AddToFavoritesDialog({required this.recipe});

  @override
  ConsumerState<_AddToFavoritesDialog> createState() =>
      _AddToFavoritesDialogState();
}

class _AddToFavoritesDialogState extends ConsumerState<_AddToFavoritesDialog> {
  String _selectedPhase = 'Follicular';
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add to Favorites'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select cycle phase:'),
          SizedBox(height: AppSpacing.md),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedPhase,
            items: ['Menstrual', 'Follicular', 'Ovulation', 'Luteal']
                .map((phase) => DropdownMenuItem(
                      value: phase,
                      child: Text(phase),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedPhase = value ?? 'Follicular');
            },
          ),
          SizedBox(height: AppSpacing.md),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(addFavoriteProvider((widget.recipe, _selectedPhase)));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added to favorites!')),
            );
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;

  const _NutritionItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: AppTypography.subtitle2),
            Text(label,
                style: AppTypography.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
