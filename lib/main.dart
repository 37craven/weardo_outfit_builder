import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/features/auth/screens/login_screen.dart';
import 'package:weardo_outfit_builder/features/auth/screens/register_screen.dart';
import 'package:weardo_outfit_builder/features/catalog/screens/catalog_screen.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/screens/builder_screen.dart';
import 'package:weardo_outfit_builder/features/catalog/screens/add_clothing_screen.dart';
import 'package:weardo_outfit_builder/features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dhmtnjwtqqcrecqmxpfc.supabase.co',
    anonKey: 'sb_publishable_a2rTSMLcLOTnfb6opH-azQ_dTkrmq2Y',
  );
  runApp(WeardoApp());
}

class WeardoApp extends StatelessWidget {
  WeardoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClothesProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: MaterialApp.router(
        title: 'WEARDO',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple)),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.currentUser != null;
      final isLoginRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoggedIn && isLoginRoute) return '/clothes';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/clothes', builder: (context, state) => const ClothesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/generate', builder: (context, state) => const GenerateOutfitScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(path: '/add-clothes', builder: (context, state) => const AddClothesScreen()),
    ],
  );
}

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final hideNav = navigationShell.currentIndex == 1;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: hideNav
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.checkroom), label: 'Clothes'),
                NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Generate'),
                NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
    );
  }
}
