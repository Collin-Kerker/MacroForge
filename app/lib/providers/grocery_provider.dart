import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grocery_list.dart';
import 'auth_provider.dart';
import 'generated_plan_provider.dart';

class GroceryService {
  final dynamic api;
  GroceryService(this.api);

  Future<GroceryList?> get() async {
    try {
      final res = await api.dio.get('/meal-plan/grocery-list');
      return GroceryList.fromJson(res.data);
    } on DioException {
      return null;
    }
  }
}

final groceryServiceProvider = Provider<GroceryService>((ref) {
  return GroceryService(ref.watch(apiClientProvider));
});

final groceryListProvider = FutureProvider<GroceryList?>((ref) async {
  // Depend on the generated week so this rebuilds whenever the week changes.
  ref.watch(generatedPlanProvider);
  return ref.watch(groceryServiceProvider).get();
});