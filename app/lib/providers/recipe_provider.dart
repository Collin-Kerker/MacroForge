import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recipe.dart';
import 'auth_provider.dart';

class RecipeService {
  final dynamic api;
  RecipeService(this.api);

  Future<List<RecipeSummary>> list({String? mealType}) async {
    try {
      final params = <String, dynamic>{};
      if (mealType != null) params['meal_type'] = mealType;
      final res = await api.dio.get('/recipes', queryParameters: params);
      return (res.data as List).map((e) => RecipeSummary.fromJson(e)).toList();
    } on DioException {
      return [];
    }
  }

  Future<RecipeDetail?> detail(String id) async {
    try {
      final res = await api.dio.get('/recipes/$id');
      return RecipeDetail.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService(ref.watch(apiClientProvider));
});

// Loads the full recipe list once; UI filters by meal type client-side.
final recipeListProvider = FutureProvider<List<RecipeSummary>>((ref) async {
  return ref.watch(recipeServiceProvider).list();
});