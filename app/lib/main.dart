import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MacroForgeApp()));
}

class MacroForgeApp extends ConsumerWidget {
  const MacroForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authProvider);

    final router = GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/login';
        final registering = state.matchedLocation == '/register';

        // Not logged in and not on an auth page -> go to login
        if (!isLoggedIn && !loggingIn && !registering) return '/login';
        // Logged in but on an auth page -> go home
        if (isLoggedIn && (loggingIn || registering)) return '/';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
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