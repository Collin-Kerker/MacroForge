import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/food_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _macroRow(String label, double consumed, int? target, String unit) {
    final t = target ?? 0;
    final remaining = (t - consumed);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('${consumed.round()} / $t $unit'
              '${remaining >= 0 ? '  (${remaining.round()} left)' : '  (${(-remaining).round()} over)'}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final dayLog = ref.watch(dayLogProvider);

    if (profile == null || !profile.profileComplete) {
      return const Scaffold(body: Center(child: Text('Loading...')));
    }

    final consumedKcal = dayLog?.totalKcal ?? 0;
    final consumedP = dayLog?.totalProteinG ?? 0;
    final consumedC = dayLog?.totalCarbsG ?? 0;
    final consumedF = dayLog?.totalFatG ?? 0;
    final entries = dayLog?.entries ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-food'),
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dayLogProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Calories headline
            Center(
              child: Column(
                children: [
                  Text('${consumedKcal.round()}',
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                  Text('of ${profile.targetCalories} kcal',
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _macroRow('Protein', consumedP, profile.targetProteinG, 'g'),
            _macroRow('Carbs', consumedC, profile.targetCarbsG, 'g'),
            _macroRow('Fat', consumedF, profile.targetFatG, 'g'),
            const Divider(height: 32),
            Text("Today's Log", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No food logged yet today.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...entries.map((e) => Dismissible(
                    key: ValueKey(e.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) => ref.read(dayLogProvider.notifier).deleteEntry(e.id),
                    child: ListTile(
                      title: Text(e.description),
                      subtitle: Text('${e.grams.round()}g  •  ${e.kcal.round()} kcal  •  '
                          'P ${e.proteinG.round()} / C ${e.carbsG.round()} / F ${e.fatG.round()}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}