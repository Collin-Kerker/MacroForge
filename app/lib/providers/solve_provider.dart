import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/solved_day.dart';
import 'auth_provider.dart';

class SolveService {
  final dynamic api;
  SolveService(this.api);

  Future<SolvedDay?> solve({
    required bool includeSnack,
    List<String> excludeRecipeIds = const [],
  }) async {
    try {
      final res = await api.dio.post('/solve', data: {
        'include_snack': includeSnack,
        'exclude_recipe_ids': excludeRecipeIds,
      });
      return SolvedDay.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final solveServiceProvider = Provider<SolveService>((ref) {
  return SolveService(ref.watch(apiClientProvider));
});