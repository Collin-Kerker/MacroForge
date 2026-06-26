import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/food_provider.dart';
import '../widgets/macro_ring.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Grocery list',
            onPressed: () => context.push('/grocery'),
          ),
          IconButton(
            icon: const Icon(Icons.view_week),
            tooltip: 'My generated week',
            onPressed: () => context.push('/week'),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'My week',
            onPressed: () => context.push('/planner'),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Recipes',
            onPressed: () => context.push('/recipes'),
          ),
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
            const SizedBox(height: 8),
            MacroRing(
              consumedKcal: consumedKcal,
              targetKcal: profile.targetCalories ?? 0,
              consumedProtein: consumedP,
              targetProtein: profile.targetProteinG ?? 0,
              consumedCarbs: consumedC,
              targetCarbs: profile.targetCarbsG ?? 0,
              consumedFat: consumedF,
              targetFat: profile.targetFatG ?? 0,
            ),
            const Divider(height: 40),
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