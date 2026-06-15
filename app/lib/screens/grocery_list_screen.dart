import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import '../providers/grocery_provider.dart';

class GroceryListScreen extends ConsumerStatefulWidget {
  const GroceryListScreen({super.key});

  @override
  ConsumerState<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends ConsumerState<GroceryListScreen> {
  final Set<String> _checked = {};

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(groceryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load grocery list.\n$e')),
        data: (list) {
          if (list == null || list.sections.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No grocery list yet.\n'
                  'Generate a week first, then come back here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final sec in list.sections) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                  child: Text(sec.section,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      for (final item in sec.items)
                        _itemTile(sec.section, item),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _itemTile(String section, GroceryItem item) {
    final key = '$section|${item.name}';
    final checked = _checked.contains(key);
    return CheckboxListTile(
      value: checked,
      onChanged: (v) => setState(() {
        if (v == true) {
          _checked.add(key);
        } else {
          _checked.remove(key);
        }
      }),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: checked ? TextDecoration.lineThrough : null,
          color: checked ? Theme.of(context).colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(
        item.notes.isNotEmpty ? '${item.quantity}  •  ${item.notes}' : item.quantity,
      ),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
    );
  }
}