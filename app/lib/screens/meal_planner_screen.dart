import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_plan.dart';
import '../providers/meal_plan_provider.dart';
import '../providers/generated_plan_provider.dart';

class MealPlannerScreen extends ConsumerStatefulWidget {
  /// When non-null, the planner shows ONLY this day and saves via the
  /// per-day endpoint (re-solving just this day). When null, it's the
  /// full seven-day structure editor saving the whole template.
  final String? focusDay;
  const MealPlannerScreen({super.key, this.focusDay});

  @override
  ConsumerState<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends ConsumerState<MealPlannerScreen> {
  MealPlan? _working; // editable working copy
  bool _saving = false;
  bool _dirty = false;

  static const _typeColors = {
    'breakfast': Color(0xFFFFB74D),
    'lunch': Color(0xFF4FC3F7),
    'dinner': Color(0xFFE57373),
    'snack': Color(0xFF81C784),
    'dessert': Color(0xFFBA68C8),
  };

  Color _colorFor(String type) => _typeColors[type] ?? Colors.grey;

  bool get _single => widget.focusDay != null;

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

    if (_single) {
      // Save + re-solve just this one day via the per-day endpoint.
      final day = widget.focusDay!;
      final slots = List<String>.from(_working!.structure[day]!);
      final result = await ref
          .read(generatedPlanServiceProvider)
          .regenerateDay(day, structure: slots);
      if (!mounted) return;
      setState(() => _saving = false);
      if (result != null) {
        // also refresh the generated week + the master plan provider
        ref.invalidate(generatedPlanProvider);
        ref.invalidate(mealPlanProvider);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update that day. Try again.')),
        );
      }
      return;
    }

    // Full-week: save the whole template.
    final result = await ref.read(mealPlanServiceProvider).update(_working!);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result != null) {
        _dirty = false;
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

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(mealPlanProvider);
    final days = _single ? [widget.focusDay!] : kDayOrder;
    final title = _single
        ? 'Edit ${kDayLabels[widget.focusDay!]!}'
        : 'Edit Week';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_dirty || _single)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_single ? 'Save & re-solve' : 'Save'),
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Text(
                      _single
                          ? 'Drag meals into this day, then Save & re-solve'
                          : 'Drag a meal into a day',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: days.length,
                  itemBuilder: (ctx, i) {
                    final day = days[i];
                    final slots = _working!.structure[day]!;
                    return _DayBox(
                      label: kDayLabels[day]!,
                      slots: slots,
                      colorFor: _colorFor,
                      onAccept: (type) => _addSlot(day, type),
                      onRemove: (index) => _removeSlot(day, index),
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

class _DayBox extends StatelessWidget {
  final String label;
  final List<String> slots;
  final Color Function(String) colorFor;
  final void Function(String type) onAccept;
  final void Function(int index) onRemove;

  const _DayBox({
    required this.label,
    required this.slots,
    required this.colorFor,
    required this.onAccept,
    required this.onRemove,
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
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (slots.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Drop meals here (rest day if empty)',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < slots.length; i++)
                      InputChip(
                        label: Text(
                          slots[i][0].toUpperCase() + slots[i].substring(1),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: colorFor(slots[i]),
                        deleteIconColor: Colors.white,
                        onDeleted: () => onRemove(i),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}