import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clothesProvider = Provider.of<ClothesProvider>(context);

    // Ensure clothes are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      clothesProvider.fetchUserClothes();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 24),
            _infoTile('Username', authProvider.username ?? 'Not set'),
            const Divider(),
            _infoTile('Email', authProvider.currentUser?.email ?? 'Not set'),
            const Divider(),
            _infoTile('Total Items in Closet', clothesProvider.getItemCount().toString()),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) context.go('/login');
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Log Out', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}