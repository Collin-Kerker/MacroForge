import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import 'auth_provider.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(api: ref.watch(apiClientProvider));
});

class ProfileNotifier extends Notifier<Profile?> {
  @override
  Profile? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final service = ref.read(profileServiceProvider);
    state = await service.getProfile();
  }

  Future<String?> save({
    required String sex,
    required DateTime birthdate,
    required double heightCm,
    required double weightKg,
    required double goalWeightKg,
    required String activityLevel,
    required double rateKgPerWeek,
    double? recompProteinGPerKg,
    required String prepCadence,
    required int prepDay,
  }) async {
    final service = ref.read(profileServiceProvider);
    final (profile, error) = await service.updateProfile(
      sex: sex,
      birthdate: birthdate,
      heightCm: heightCm,
      weightKg: weightKg,
      goalWeightKg: goalWeightKg,
      activityLevel: activityLevel,
      rateKgPerWeek: rateKgPerWeek,
      recompProteinGPerKg: recompProteinGPerKg,
      prepCadence: prepCadence,
      prepDay: prepDay,
    );
    if (profile != null) state = profile;
    return error;
  }

  // Prep-only update via PATCH /profile/prep. Macros are untouched.
  Future<String?> updatePrep({
    required String prepCadence,
    required int prepDay,
  }) async {
    final service = ref.read(profileServiceProvider);
    final (profile, error) = await service.updatePrep(
      prepCadence: prepCadence,
      prepDay: prepDay,
    );
    if (profile != null) state = profile;
    return error;
  }

  Future<void> refresh() => _load();
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(() {
  return ProfileNotifier();
});