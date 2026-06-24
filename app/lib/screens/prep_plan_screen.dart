import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prep_plan.dart';
import '../providers/prep_provider.dart';

class PrepPlanScreen extends ConsumerStatefulWidget {
  const PrepPlanScreen({super.key});

  @override
  ConsumerState<PrepPlanScreen> createState() => _PrepPlanScreenState();
}

class _PrepPlanScreenState extends ConsumerState<PrepPlanScreen> {
  final Set<String> _done = {};
  static const _dayLabels = {
    'mon': 'Monday', 'tue': 'Tuesday', 'wed': 'Wednesday', 'thu': 'Thursday',
    'fri': 'Friday', 'sat': 'Saturday', 'sun': 'Sunday',
  };

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(prepPlanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Prep Plan')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load prep plan.\n$e')),
        data: (plan) {
          if (plan == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No prep plan yet.\nGenerate a week first, then come back here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return plan.cadence == 'batch'
              ? _buildBatch(context, plan)
              : _buildRolling(context, plan);
        },
      ),
    );
  }

  Widget _buildBatch(BuildContext context, PrepPlan plan) {
    if (plan.groups.isEmpty) {
      return const Center(child: Text('Nothing to prep this week.'));
    }
    final dayName = plan.prepDay != null ? _dayLabels.values.elementAt(plan.prepDay!) : null;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (dayName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text('Batch prep for the week — $dayName',
                style: Theme.of(context).textTheme.titleMedium),
          ),
        for (final group in plan.groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(group.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          Card(
            child: Column(
              children: [
                for (final item in group.items)
                  CheckboxListTile(
                    value: _done.contains(item.recipeId),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _done.add(item.recipeId);
                      } else {
                        _done.remove(item.recipeId);
                      }
                    }),
                    title: Text(item.name,
                        style: TextStyle(
                          decoration: _done.contains(item.recipeId)
                              ? TextDecoration.lineThrough
                              : null,
                        )),
                    subtitle: Text('Prep ${_fmt(item.totalServings)} servings'),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRolling(BuildContext context, PrepPlan plan) {
    if (plan.days.isEmpty) {
      return const Center(child: Text('Nothing to cook this week.'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final day in plan.days)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dayLabels[day.day] ?? day.day,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  if (day.meals.isEmpty)
                    Text('Rest day',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant))
                  else
                    for (final meal in day.meals)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text('• ${meal.name}  (${_fmt(meal.servings)}x)'),
                      ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}