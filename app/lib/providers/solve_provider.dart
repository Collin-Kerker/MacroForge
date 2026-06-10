import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/solved_day.dart';
import 'auth_provider.dart';

class SolveService {
  final dynamic api;
  SolveService(this.api);

  Future<SolvedDay?> solve({
    bool includeSnack = true,
    List<String> excludeRecipeIds = const [],
    List<String>? mealStructure,
  }) async {
    try {
      final data = {
        'include_snack': includeSnack,
        'exclude_recipe_ids': excludeRecipeIds,
      };
      if (mealStructure != null) {
        data['meal_structure'] = mealStructure;
      }
      final res = await api.dio.post('/solve', data: data);
      return SolvedDay.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final solveServiceProvider = Provider<SolveService>((ref) {
  return SolveService(ref.watch(apiClientProvider));
});