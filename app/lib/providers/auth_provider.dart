import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'profile_provider.dart';

// The secure storage instance
final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// The API client
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(storage: ref.watch(storageProvider));
});

// The auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(storageProvider),
  );
});

// Tracks whether the user is logged in. The UI watches this.
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    _checkLogin();
    return false;
  }

  Future<void> _checkLogin() async {
    final authService = ref.read(authServiceProvider);
    state = await authService.hasToken();
  }

  Future<String?> login(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    final error = await authService.login(email, password);
    if (error == null) {
      ref.invalidate(profileProvider);
      state = true;
    }
    return error;
  }

  Future<String?> register(String email, String password) async {
    final authService = ref.read(authServiceProvider);
    final error = await authService.register(email, password);
    if (error == null) {
      ref.invalidate(profileProvider);
      state = true;
    }
    return error;
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    ref.invalidate(profileProvider);
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});