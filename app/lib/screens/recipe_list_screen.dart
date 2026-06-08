import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipeListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      body: Column(
        children: [
          // meal-type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: ['all', 'breakfast', 'lunch', 'dinner', 'snack'].map((m) {
                final selected = _filter == m;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(m[0].toUpperCase() + m.substring(1)),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = m),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load recipes.\n$e')),
              data: (recipes) {
                final filtered = _filter == 'all'
                    ? recipes
                    : recipes.where((r) => r.mealType == _filter).toList();
                if (filtered.isEmpty) {
                  return const Center(child: Text('No recipes here.'));
                }
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = filtered[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(r.name),
                        subtitle: Text(
                          '${r.kcal} kcal  •  P ${r.protein} / C ${r.carbs} / F ${r.fat}'
                          '${r.prepMinutes != null ? '  •  ${r.prepMinutes} min' : ''}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/recipes/${r.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}