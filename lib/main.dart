import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo/providers/auth_provider.dart';
import 'package:weardo/providers/clothes_provider.dart';
import 'package:weardo/providers/favorite_provider.dart';
import 'package:weardo/screens/login_screen.dart';
import 'package:weardo/screens/home_screen.dart';
import 'package:go_router/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WeardoApp());
}

class WeardoApp extends StatelessWidget {
  const WeardoApp({super.key});

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

      if (isLoggedIn && isLoginRoute) return '/home';
      if (!isLoggedIn && !isLoginRoute) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/generate', builder: (context, state) => const GenerateOutfitScreen()),
      GoRoute(path: '/clothes', builder: (context, state) => const ClothesScreen()),
      GoRoute(path: '/add-clothes', builder: (context, state) => const AddClothesScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    ],
  );
}