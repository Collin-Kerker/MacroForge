import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prep_plan.dart';
import 'auth_provider.dart';
import 'generated_plan_provider.dart';
import 'profile_provider.dart';

class PrepService {
  final dynamic api;
  PrepService(this.api);

  Future<PrepPlan?> get() async {
    try {
      final res = await api.dio.get('/meal-plan/prep-plan');
      return PrepPlan.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final prepServiceProvider = Provider<PrepService>((ref) {
  return PrepService(ref.watch(apiClientProvider));
});

final prepPlanProvider = FutureProvider<PrepPlan?>((ref) async {
  // Rebuild when the week changes OR the prep cadence/day changes.
  ref.watch(generatedPlanProvider);
  ref.watch(profileProvider);
  return ref.watch(prepServiceProvider).get();
});