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
import 'screens/recipe_list_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/generate_day_screen.dart';
import 'screens/meal_planner_screen.dart';
import 'screens/week_view_screen.dart';
import 'screens/grocery_list_screen.dart';
import 'screens/prep_plan_screen.dart';

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
        GoRoute(path: '/recipes', builder: (c, s) => const RecipeListScreen()),
        GoRoute(
          path: '/recipes/:id',
          builder: (c, s) => RecipeDetailScreen(recipeId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/generate', builder: (c, s) => const GenerateDayScreen()),
        GoRoute(
          path: '/planner',
          builder: (c, s) => MealPlannerScreen(focusDay: s.uri.queryParameters['day']),
        ),
        GoRoute(path: '/week', builder: (c, s) => const WeekViewScreen()),
        GoRoute(path: '/grocery', builder: (c, s) => const GroceryListScreen()),
        GoRoute(path: '/prep', builder: (c, s) => const PrepPlanScreen()),
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