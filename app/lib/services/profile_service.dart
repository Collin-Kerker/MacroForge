import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/profile.dart';

class ProfileService {
  final ApiClient api;

  ProfileService({required this.api});

  Future<Profile?> getProfile() async {
    try {
      final response = await api.dio.get('/profile');
      return Profile.fromJson(response.data);
    } on DioException {
      return null;
    }
  }

  // All values metric. Returns the updated profile (with computed targets) or an error string.
  Future<(Profile?, String?)> updateProfile({
    required String sex,
    required DateTime birthdate,
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required String activityLevel,
    required double rateKgPerWeek,
    double? recompProteinGPerKg,
  }) async {
    try {
      final response = await api.dio.put('/profile', data: {
        'sex': sex,
        'birthdate': _formatDate(birthdate),
        'height_cm': heightCm,
        'current_weight_kg': weightKg,
        'goal_weight_kg': goalWeightKg,
        'activity_level': activityLevel,
        'rate_kg_per_week': rateKgPerWeek,
        'recomp_protein_g_per_kg': recompProteinGPerKg,
      });
      return (Profile.fromJson(response.data), null);
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      return (null, detail?.toString() ?? 'Could not save profile. Try again.');
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}