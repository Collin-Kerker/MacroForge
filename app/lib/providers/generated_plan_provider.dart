import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/generated_plan.dart';
import 'auth_provider.dart';

class GeneratedPlanService {
  final dynamic api;
  GeneratedPlanService(this.api);

  // Full-week generate (POST /meal-plan/generate).
  Future<GeneratedPlan?> generate() async {
    try {
      final res = await api.dio.post('/meal-plan/generate');
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Fetch the saved generated week (GET /meal-plan/generated).
  Future<GeneratedPlan?> get() async {
    try {
      final res = await api.dio.get('/meal-plan/generated');
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Re-solve a SINGLE day (PATCH /meal-plan/day/{day}). If [structure] is
  // given, that day's slot shape is changed too; otherwise just re-rolls
  // recipes. Only that day is rewritten server-side; neighbors are excluded
  // for variety, the other days are untouched.
  Future<GeneratedPlan?> regenerateDay(String day, {List<String>? structure}) async {
    try {
      final res = await api.dio.patch(
        '/meal-plan/day/$day',
        data: structure != null ? {'structure': structure} : {},
      );
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Lock / unlock a single slot in a day (flag only, no re-solve).
  Future<GeneratedPlan?> toggleSlotLock(String day, int slotIndex, bool locked) async {
    try {
      final res = await api.dio.patch(
        '/meal-plan/day/$day/lock',
        data: {'slot_index': slotIndex, 'locked': locked},
      );
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Mark a planned meal as cooked — writes a food log for that day's date.
  Future<GeneratedPlan?> cookSlot(String day, int slotIndex) async {
    try {
      final res = await api.dio.post(
        '/meal-plan/day/$day/cook',
        data: {'slot_index': slotIndex},
      );
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  // Un-mark a cooked meal — deletes that food log.
  Future<GeneratedPlan?> uncookSlot(String day, int slotIndex) async {
    try {
      final res = await api.dio.post(
        '/meal-plan/day/$day/uncook',
        data: {'slot_index': slotIndex},
      );
      return GeneratedPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final generatedPlanServiceProvider = Provider<GeneratedPlanService>((ref) {
  return GeneratedPlanService(ref.watch(apiClientProvider));
});

final generatedPlanProvider = FutureProvider<GeneratedPlan?>((ref) async {
  return ref.watch(generatedPlanServiceProvider).get();
});