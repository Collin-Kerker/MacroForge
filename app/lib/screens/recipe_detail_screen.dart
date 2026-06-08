import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Recipe')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load recipe.\n$e')),
        data: (r) {
          if (r == null) return const Center(child: Text('Recipe not found.'));
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
              if (r.description != null) ...[
                const SizedBox(height: 8),
                Text(r.description!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              // macro summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _macroChip('${r.kcal}', 'kcal'),
                      _macroChip('${r.protein}g', 'protein'),
                      _macroChip('${r.carbs}g', 'carbs'),
                      _macroChip('${r.fat}g', 'fat'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('${r.servings} serving${r.servings > 1 ? 's' : ''}'
                  '${r.prepMinutes != null ? '  •  ${r.prepMinutes} min' : ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Divider(height: 32),
              Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...r.ingredients.map((ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text('${ing.amount}  ${ing.item}')),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              Text('Steps', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...r.steps.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key + 1}.  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(entry.value)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _macroChip(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
}

// family provider: fetches one recipe's detail by id
final _recipeDetailProvider =
    FutureProvider.family<RecipeDetail?, String>((ref, id) async {
  return ref.watch(recipeServiceProvider).detail(id);
});