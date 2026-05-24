import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClothesProvider>(context, listen: false).fetchUserClothes();
      Provider.of<FavoriteProvider>(context, listen: false).fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clothesProvider = Provider.of<ClothesProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserCard(authProvider, clothesProvider),
            const SizedBox(height: 24),
            const Text('Saved Outfits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildSavedOutfits(context),
            const SizedBox(height: 24),
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

  Widget _buildUserCard(AuthProvider authProvider, ClothesProvider clothesProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authProvider.username ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(authProvider.currentUser?.email ?? '', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('${clothesProvider.getItemCount()} items in closet', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedOutfits(BuildContext context) {
    final favProvider = Provider.of<FavoriteProvider>(context);
    final clothesProvider = Provider.of<ClothesProvider>(context);
    final favorites = favProvider.favorites;

    if (favProvider.isLoading || clothesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No saved outfits yet.', style: TextStyle(color: Colors.grey[600])),
            Text('Go to Generate to create and save outfits.', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    ClothingItem? getItem(String id, String category) {
      final list = category == 'Outer'
          ? clothesProvider.getOuter()
          : category == 'Inner'
          ? clothesProvider.getInner()
          : category == 'Pants'
          ? clothesProvider.getPants()
          : clothesProvider.getShoes();
      try {
        return list.firstWhere((e) => e.id == id);
      } catch (_) {
        return null;
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: favorites.length,
      itemBuilder: (ctx, index) {
        final fav = favorites[index];
        final inner = getItem(fav.innerId, 'Inner');
        final pants = getItem(fav.pantsId, 'Pants');
        final shoes = getItem(fav.shoesId, 'Shoes');
        final outer = fav.outerId != null ? getItem(fav.outerId!, 'Outer') : null;

        if (inner == null || pants == null || shoes == null) {
          return Card(
            child: const Center(child: Text('Missing item', textAlign: TextAlign.center)),
          );
        }

        final images = [inner, pants, shoes];
        if (outer != null) images.insert(0, outer);

        return Card(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: images.map((item) {
                    return Expanded(child: Image.network(item.imageUrl, fit: BoxFit.contain));
                  }).toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => favProvider.removeFavorite(fav.id),
              ),
            ],
          ),
        );
      },
    );
  }
}
