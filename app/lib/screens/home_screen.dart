import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await ref.read(authServiceProvider).getMe();
    if (mounted && data != null) {
      setState(() => _email = data['email']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MacroForge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final profile = ref.watch(profileProvider);
          if (profile == null || !profile.profileComplete) {
            return const Center(child: Text('Loading...'));
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Daily Targets', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Text('${profile.targetCalories} kcal', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('Protein: ${profile.targetProteinG} g'),
                Text('Carbs: ${profile.targetCarbsG} g'),
                Text('Fat: ${profile.targetFatG} g'),
              ],
            ),
          );
        },
      ),
    );
  }
}