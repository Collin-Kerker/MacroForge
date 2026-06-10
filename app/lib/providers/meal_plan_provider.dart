import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/meal_plan.dart';
import 'auth_provider.dart';

class MealPlanService {
  final dynamic api;
  MealPlanService(this.api);

  Future<MealPlan?> get() async {
    try {
      final res = await api.dio.get('/meal-plan');
      return MealPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }

  Future<MealPlan?> update(MealPlan plan) async {
    try {
      final res = await api.dio.put('/meal-plan', data: plan.toJson());
      return MealPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final mealPlanServiceProvider = Provider<MealPlanService>((ref) {
  return MealPlanService(ref.watch(apiClientProvider));
});

// Loads the user's saved plan once.
final mealPlanProvider = FutureProvider<MealPlan?>((ref) async {
  return ref.watch(mealPlanServiceProvider).get();
});