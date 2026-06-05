import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/food.dart';

class FoodService {
  final ApiClient api;
  FoodService({required this.api});

  Future<List<FoodItem>> search(String query) async {
    try {
      final response = await api.dio.get('/foods/search', queryParameters: {'q': query});
      return (response.data as List).map((e) => FoodItem.fromJson(e)).toList();
    } on DioException {
      return [];
    }
  }

  Future<DayLog?> getDayLog({DateTime? date}) async {
    try {
      final params = <String, dynamic>{};
      if (date != null) {
        params['log_date'] =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      final response = await api.dio.get('/logs', queryParameters: params);
      return DayLog.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  Future<String?> logFood({required int foodItemId, required double grams}) async {
    try {
      await api.dio.post('/logs', data: {'food_item_id': foodItemId, 'grams': grams});
      return null;
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return detail?.toString() ?? 'Could not log food. Try again.';
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      await api.dio.delete('/logs/$logId');
      return true;
    } on DioException {
      return false;
    }
  }
}