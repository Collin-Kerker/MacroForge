import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/generated_plan.dart';
import 'auth_provider.dart';

class GeneratedPlanService {
  final dynamic api;
  GeneratedPlanService(this.api);

  // Fetch the saved week. Returns null if none exists yet (404).
  Future<GeneratedPlan?> get() async {
    try {
      final res = await api.dio.get('/meal-plan/generated');
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Solve + persist a fresh week, returns it.
  Future<GeneratedPlan?> generate() async {
    try {
      final res = await api.dio.post('/meal-plan/generate');
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final generatedPlanServiceProvider = Provider<GeneratedPlanService>((ref) {
  return GeneratedPlanService(ref.watch(apiClientProvider));
});

// Loads the saved week (null if never generated).
final generatedPlanProvider = FutureProvider<GeneratedPlan?>((ref) async {
  return ref.watch(generatedPlanServiceProvider).get();
});