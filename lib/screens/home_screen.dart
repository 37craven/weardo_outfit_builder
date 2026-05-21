import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WEARDO Home')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(context, 'Generate Outfit', Icons.auto_awesome, '/generate'),
          _buildMenuCard(context, 'Clothes', Icons.checkroom, '/clothes'),
          _buildMenuCard(context, 'Add Clothes', Icons.add_photo_alternate, '/add-clothes'),
          _buildMenuCard(context, 'Profile', Icons.person, '/profile'),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, String route) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          // ✅ Use GoRouter's go() method instead of Navigator.pushNamed
          context.go(route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}