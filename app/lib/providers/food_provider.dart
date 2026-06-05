import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/food_service.dart';
import '../models/food.dart';
import 'auth_provider.dart';

final foodServiceProvider = Provider<FoodService>((ref) {
  return FoodService(api: ref.watch(apiClientProvider));
});

// Holds today's log; the UI watches this and it refreshes after logging.
class DayLogNotifier extends Notifier<DayLog?> {
  @override
  DayLog? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final service = ref.read(foodServiceProvider);
    state = await service.getDayLog();
  }

  Future<String?> logFood({required int foodItemId, required double grams}) async {
    final service = ref.read(foodServiceProvider);
    final error = await service.logFood(foodItemId: foodItemId, grams: grams);
    if (error == null) await _load(); // refresh totals
    return error;
  }

  Future<void> deleteEntry(String logId) async {
    final service = ref.read(foodServiceProvider);
    final ok = await service.deleteLog(logId);
    if (ok) await _load();
  }

  Future<void> refresh() => _load();
}

final dayLogProvider = NotifierProvider<DayLogNotifier, DayLog?>(() {
  return DayLogNotifier();
});