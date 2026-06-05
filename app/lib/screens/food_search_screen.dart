import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food.dart';
import '../providers/food_provider.dart';

class FoodSearchScreen extends ConsumerStatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _searchCtrl = TextEditingController();
  List<FoodItem> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) return;
    setState(() => _searching = true);
    final results = await ref.read(foodServiceProvider).search(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  Future<void> _showLogDialog(FoodItem food) async {
    final gramsCtrl = TextEditingController(text: '100');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(food.description, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Per 100g: ${food.kcalPer100g?.round() ?? 0} kcal, '
                'P ${food.proteinPer100g?.round() ?? 0}g / '
                'C ${food.carbsPer100g?.round() ?? 0}g / '
                'F ${food.fatPer100g?.round() ?? 0}g',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: gramsCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Grams',
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log it')),
        ],
      ),
    );

    if (result == true) {
      final grams = double.tryParse(gramsCtrl.text);
      if (grams == null || grams <= 0) return;
      final error = await ref.read(dayLogProvider.notifier)
          .logFood(foodItemId: food.id, grams: grams);
      if (!mounted) return;
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged ${food.description}')),
        );
        Navigator.pop(context); // back to home
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runSearch(),
              decoration: InputDecoration(
                hintText: 'Search foods (e.g. chicken, rice)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _runSearch),
              ),
            ),
          ),
          if (_searching) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final f = _results[i];
                return ListTile(
                  title: Text(f.description),
                  subtitle: Text('${f.kcalPer100g?.round() ?? 0} kcal / 100g  •  '
                      'P ${f.proteinPer100g?.round() ?? 0}g'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => _showLogDialog(f),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}