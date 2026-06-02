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
    required String activityLevel,
    required String goal,
  }) async {
    final service = ref.read(profileServiceProvider);
    final (profile, error) = await service.updateProfile(
      sex: sex,
      birthdate: birthdate,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      goal: goal,
    );
    if (profile != null) state = profile;
    return error;
  }

  Future<void> refresh() => _load();
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(() {
  return ProfileNotifier();
});