import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/solve_provider.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  MealPlan? _working; // editable working copy
  bool _saving = false;
  bool _dirty = false;

  // colors per meal type for the chips
  static const _typeColors = {
    'breakfast': Color(0xFFFFB74D), // orange
    'lunch': Color(0xFF4FC3F7),     // blue
    'dinner': Color(0xFFE57373),    // red
    'snack': Color(0xFF81C784),     // green
    'dessert': Color(0xFFBA68C8),   // purple
  };

  Color _colorFor(String type) => _typeColors[type] ?? Colors.grey;

  void _ensureWorking(MealPlan loaded) {
    _working ??= loaded.copy();
  }

  void _addSlot(String day, String mealType) {
    setState(() {
      _working!.structure[day]!.add(mealType);
      _dirty = true;
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      _working!.structure[day]!.removeAt(index);
      _dirty = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await ref.read(mealPlanServiceProvider).update(_working!);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result != null) {
        _dirty = false;
        _working = result.copy();          // adopt the server's saved copy
        ref.invalidate(mealPlanProvider);  // force a fresh fetch next time
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Week saved')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Try again.')),
        );
      }
    });
  }

  Future<void> _generateDay(String day) async {
    final structure = _working!.structure[day]!;
    if (structure.isEmpty) return;

    // loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ref.read(solveServiceProvider).solve(
          mealStructure: structure,
        );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    if (result == null || !result.feasible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?.reason ?? 'Could not generate this day.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Text('${kDayLabels[day]} — Generated',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...result.slots.map((s) => Card(
                  child: ListTile(
                    title: Text(s.name),
                    subtitle: Text('${s.slot[0].toUpperCase()}${s.slot.substring(1)}'
                        '  •  ${s.servings}x  •  ${s.kcal} kcal  •  '
                        'P ${s.protein} / C ${s.carbs} / F ${s.fat}'),
                  ),
                )),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day Totals', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Calories: ${result.totals?['kcal']} / ${result.targets?['kcal']}'),
                    Text('Protein: ${result.totals?['protein']}g / ${result.targets?['protein']}g'),
                    Text('Carbs: ${result.totals?['carbs']}g / ${result.targets?['carbs']}g'),
                    Text('Fat: ${result.totals?['fat']}g / ${result.targets?['fat']}g'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(mealPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Week'),
        actions: [
          if (_dirty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your week.\n$e')),
        data: (loaded) {
          if (loaded == null) return const Center(child: Text('Could not load your week.'));
          _ensureWorking(loaded);

          return Column(
            children: [
              // ── The palette: draggable meal types ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Text('Drag a meal into a day',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: kMealTypes.map((type) {
                        return Draggable<String>(
                          data: type,
                          feedback: _chip(type, dragging: true),
                          childWhenDragging: Opacity(opacity: 0.4, child: _chip(type)),
                          child: _chip(type),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              // ── The seven day-boxes ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: kDayOrder.length,
                  itemBuilder: (ctx, i) {
                    final day = kDayOrder[i];
                    final slots = _working!.structure[day]!;
                    return _DayBox(
                      label: kDayLabels[day]!,
                      slots: slots,
                      colorFor: _colorFor,
                      onAccept: (type) => _addSlot(day, type),
                      onRemove: (index) => _removeSlot(day, index),
                      onGenerate: () => _generateDay(day),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String type, {bool dragging = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _colorFor(type),
          borderRadius: BorderRadius.circular(20),
          boxShadow: dragging ? [const BoxShadow(blurRadius: 8, color: Colors.black26)] : null,
        ),
        child: Text(
          type[0].toUpperCase() + type.substring(1),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// A single day's drop target + its slot chips.
class _DayBox extends StatelessWidget {
  final String label;
  final List<String> slots;
  final Color Function(String) colorFor;
  final void Function(String type) onAccept;
  final void Function(int index) onRemove;
  final VoidCallback onGenerate;

  const _DayBox({
    required this.label,
    required this.slots,
    required this.colorFor,
    required this.onAccept,
    required this.onRemove,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovering
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: hovering
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: hovering ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (slots.isNotEmpty)
                    TextButton.icon(
                      onPressed: onGenerate,
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: const Text('Generate'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (slots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No meals — drag one here',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(slots.length, (index) {
                    final type = slots[index];
                    return InputChip(
                      label: Text(type[0].toUpperCase() + type.substring(1)),
                      backgroundColor: colorFor(type).withValues(alpha: 0.85),
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      deleteIconColor: Colors.white,
                      onDeleted: () => onRemove(index),
                    );
                  }),
                ),
            ],
          ),
        );
      },
    );
  }
}