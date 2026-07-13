import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/generated_plan.dart';
import '../models/meal_plan.dart'; // for kDayOrder / kDayLabels
import '../models/profile.dart';
import '../providers/generated_plan_provider.dart';
import '../providers/profile_provider.dart';
import '../models/solved_day.dart';

class WeekViewScreen extends ConsumerStatefulWidget {
  const WeekViewScreen({super.key});

  @override
  ConsumerState<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends ConsumerState<WeekViewScreen> {
  bool _generating = false;
  final Set<String> _rerolling = {}; // day keys currently re-rolling

  Future<void> _generate() async {
    setState(() => _generating = true);
    final result = await ref.read(generatedPlanServiceProvider).generate();
    if (!mounted) return;
    setState(() => _generating = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
          'Could not generate. Make sure your profile is complete.')),
      );
      return;
    }
    ref.invalidate(generatedPlanProvider);
  }

  Future<void> _rerollDay(String dayKey) async {
    setState(() => _rerolling.add(dayKey));
    final result =
        await ref.read(generatedPlanServiceProvider).regenerateDay(dayKey);
    if (!mounted) return;
    setState(() => _rerolling.remove(dayKey));
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not re-roll that day.')),
      );
      return;
    }
    ref.invalidate(generatedPlanProvider);
  }

  Future<void> _toggleLock(String dayKey, SolvedSlot slot) async {
    final result = await ref
        .read(generatedPlanServiceProvider)
        .toggleSlotLock(dayKey, slot.slotIndex, !slot.locked);
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not change lock.')),
      );
      return;
    }
    ref.invalidate(generatedPlanProvider);
  }

  Future<void> _editDay(String dayKey) async {
    // Open the planner focused on this one day; it saves + re-solves just
    // this day via the per-day endpoint. Refresh the week when we return.
    await context.push('/planner?day=$dayKey');
    if (mounted) ref.invalidate(generatedPlanProvider);
  }

  Future<void> _editPrep(Profile profile) async {
    String cadence = profile.prepCadence;
    int day = profile.prepDay;
    const dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meal prep', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'batch', label: Text('Batch')),
                  ButtonSegment(value: 'rolling', label: Text('Day by day')),
                ],
                selected: {cadence},
                onSelectionChanged: (s) => setSheet(() => cadence = s.first),
              ),
              if (cadence == 'batch') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: const InputDecoration(
                      labelText: 'Prep day', border: OutlineInputBorder()),
                  items: [
                    for (int i = 0; i < 7; i++)
                      DropdownMenuItem(value: i, child: Text(dayNames[i])),
                  ],
                  onChanged: (v) => setSheet(() => day = v ?? 6),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final err = await ref
                      .read(profileProvider.notifier)
                      .updatePrep(prepCadence: cadence, prepDay: day);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (err != null && mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(generatedPlanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Week'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Grocery list',
            onPressed: () => context.push('/grocery'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            tooltip: 'Edit week structure',
            onPressed: () => _editWholeWeek(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_generating ? 'Generating' : 'Generate'),
            ),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load your week.\n$e')),
        data: (plan) {
          if (plan == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(
                      'No week generated yet.\n'
                      'Tap Generate to build a full week from your meal plan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Prep-status row.
              Builder(
                builder: (context) {
                  final profile = ref.watch(profileProvider);
                  if (profile == null) return const SizedBox.shrink();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(Icons.event_note),
                      title: Text(profile.prepCadence == 'batch'
                          ? 'Batch prep on ${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][profile.prepDay]}'
                          : 'Prepping day by day'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.checklist),
                            tooltip: 'View prep plan',
                            onPressed: () => context.push('/prep'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Change prep',
                            onPressed: () => _editPrep(profile),
                          ),
                        ],
                      ),
                      onTap: () => _editPrep(profile),
                    ),
                  );
                },
              ),
              for (final day in kDayOrder)
                if (plan.days.containsKey(day))
                  _DayCard(
                    dayKey: day,
                    label: kDayLabels[day]!,
                    day: plan.days[day]!,
                    rerolling: _rerolling.contains(day),
                    onReroll: () => _rerollDay(day),
                    onEdit: () => _editDay(day),
                    onToggleLock: (slot) => _toggleLock(day, slot),
                  ),
              const SizedBox(height: 8),
              _WeekTotalsCard(totals: plan.weekTotals),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editWholeWeek() async {
    await context.push('/planner');
    if (mounted) ref.invalidate(generatedPlanProvider);
  }
}

class _DayCard extends StatelessWidget {
  final String dayKey;
  final String label;
  final GeneratedDay day;
  final bool rerolling;
  final VoidCallback onReroll;
  final VoidCallback onEdit;
  final void Function(SolvedSlot slot) onToggleLock;

  const _DayCard({
    required this.dayKey,
    required this.label,
    required this.day,
    required this.rerolling,
    required this.onReroll,
    required this.onEdit,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                if (rerolling)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (v) {
                    if (v == 'reroll') onReroll();
                    if (v == 'edit') onEdit();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'reroll',
                      child: ListTile(
                        leading: Icon(Icons.casino_outlined),
                        title: Text('Re-roll recipes'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_calendar_outlined),
                        title: Text('Edit this day'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            if (day.empty || day.slots.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Rest day — no meals planned',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
              )
            else ...[
              ...day.slots.map((s) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: s.locked
                        ? BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          )
                        : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 18,
                          icon: Icon(
                            s.locked ? Icons.lock : Icons.lock_open_outlined,
                            color: s.locked ? scheme.primary : scheme.onSurfaceVariant,
                          ),
                          tooltip: s.locked ? 'Unlock (allow re-roll)' : 'Lock (keep on re-roll)',
                          onPressed: () => onToggleLock(s),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                '${s.slot[0].toUpperCase()}${s.slot.substring(1)}'
                                '  •  ${s.servings}x  •  ${s.kcal} kcal',
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text('P${s.protein} C${s.carbs} F${s.fat}',
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  )),
              const Divider(height: 18),
              _dayTotalsRow(context, day),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dayTotalsRow(BuildContext context, GeneratedDay day) {
    final t = day.totals;
    final tgt = day.targets;
    if (t == null) return const SizedBox.shrink();
    String pair(String k, String unit) =>
        '${(t[k] as num?)?.round() ?? 0}$unit/${(tgt?[k] as num?)?.round() ?? 0}$unit';
    return Text(
      'Day: ${pair('kcal', '')} kcal  •  '
      'P ${pair('protein', '')}  •  '
      'C ${pair('carbs', '')}  •  '
      'F ${pair('fat', '')}',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }
}

class _WeekTotalsCard extends StatelessWidget {
  final Map<String, dynamic>? totals;
  const _WeekTotalsCard({this.totals});

  @override
  Widget build(BuildContext context) {
    if (totals == null) return const SizedBox.shrink();
    int v(String k) => (totals![k] as num?)?.round() ?? 0;
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Week Totals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Calories: ${v('kcal')}'),
            Text('Protein: ${v('protein')}g'),
            Text('Carbs: ${v('carbs')}g'),
            Text('Fat: ${v('fat')}g'),
          ],
        ),
      ),
    );
  }
}