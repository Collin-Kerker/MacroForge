import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'providers/profile_provider.dart';
import 'screens/food_search_screen.dart';

void main() {
  runApp(const ProviderScope(child: MacroForgeApp()));
}

class MacroForgeApp extends ConsumerWidget {
  const MacroForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);
    final profile = ref.watch(profileProvider);

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final onAuthPage = loc == '/login' || loc == '/register';

        // not logged in -> must be on an auth page
        if (!isLoggedIn) {
          return onAuthPage ? null : '/login';
        }

        // logged in but profile not loaded yet -> let it resolve
        if (profile == null) return null;

        // logged in, profile incomplete -> force setup
        if (!profile.profileComplete && loc != '/profile-setup') {
          return '/profile-setup';
        }

        // logged in with complete profile but sitting on auth/setup -> home
        if (profile.profileComplete && (onAuthPage || loc == '/profile-setup')) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(path: '/profile-setup', builder: (c, s) => const ProfileSetupScreen()),
        GoRoute(path: '/add-food', builder: (c, s) => const FoodSearchScreen()),
      ],
    );

    return MaterialApp.router(
      title: 'MacroForge',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A6B3C)),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}