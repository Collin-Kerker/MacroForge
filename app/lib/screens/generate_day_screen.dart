import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/solved_day.dart';
import '../providers/solve_provider.dart';

class GenerateDayScreen extends ConsumerStatefulWidget {
  const GenerateDayScreen({super.key});

  @override
  ConsumerState<GenerateDayScreen> createState() => _GenerateDayScreenState();
}

class _GenerateDayScreenState extends ConsumerState<GenerateDayScreen> {
  bool _includeSnack = true;
  bool _loading = false;
  SolvedDay? _day;
  String? _error;

  Future<void> _generate({bool regenerate = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // On regenerate, exclude the current day's recipes to force variety.
    final exclude = (regenerate && _day != null)
        ? _day!.slots.map((s) => s.recipeId).toList()
        : <String>[];

    final result = await ref.read(solveServiceProvider).solve(
          includeSnack: _includeSnack,
          excludeRecipeIds: exclude,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null) {
        _error = 'Could not generate a day. Try again.';
      } else if (!result.feasible) {
        _error = result.reason ?? 'No valid day could be generated.';
      } else {
        _day = result;
      }
    });
  }

  String _devText(String key) {
    final d = _day?.deviation?[key];
    if (d == null) return '';
    final n = (d as num).round();
    if (n == 0) return 'on target';
    return n > 0 ? '+$n over' : '${n.abs()} under';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Generate a Day')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // snack toggle
            SwitchListTile(
              title: const Text('Include a snack'),
              value: _includeSnack,
              onChanged: _loading ? null : (v) => setState(() => _includeSnack = v),
            ),
            const SizedBox(height: 8),

            if (_day == null && !_loading && _error == null)
              Expanded(
                child: Center(
                  child: Text(
                    'Tap Generate to build a day that hits your macros.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            if (_loading) const Expanded(child: Center(child: CircularProgressIndicator())),

            if (_error != null)
              Expanded(
                child: Center(
                  child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
              ),

            if (_day != null && !_loading) ...[
              Expanded(
                child: ListView(
                  children: [
                    ..._day!.slots.map((s) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(s.name),
                            subtitle: Text(
                              '${s.slot[0].toUpperCase()}${s.slot.substring(1)}'
                              '  •  ${s.servings}x serving'
                              '\n${s.kcal} kcal  •  P ${s.protein} / C ${s.carbs} / F ${s.fat}',
                            ),
                            isThreeLine: true,
                          ),
                        )),
                    const SizedBox(height: 12),
                    // totals vs targets card
                    Card(
                      color: scheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Day Totals', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            _totalRow('Calories', 'kcal', ''),
                            _totalRow('Protein', 'protein', 'g'),
                            _totalRow('Carbs', 'carbs', 'g'),
                            _totalRow('Fat', 'fat', 'g'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : () => _generate(),
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_day == null ? 'Generate' : 'Start Over'),
                  ),
                ),
                if (_day != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : () => _generate(regenerate: true),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String key, String unit) {
    final total = _day?.totals?[key];
    final target = _day?.targets?[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${(total as num?)?.round() ?? 0}$unit / ${(target as num?)?.round() ?? 0}$unit  '
              '(${_devText(key)})'),
        ],
      ),
    );
  }
}