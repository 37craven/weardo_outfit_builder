import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:weardo_outfit_builder/providers/favorite_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_item.dart';
import 'package:weardo_outfit_builder/models/favorite_outfit.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class ClothesScreen extends StatefulWidget {
  const ClothesScreen({super.key});

  @override
  State<ClothesScreen> createState() => _ClothesScreenState();
}

class _ClothesScreenState extends State<ClothesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load user's clothes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClothesProvider>(context, listen: false).fetchUserClothes();
      Provider.of<FavoriteProvider>(context, listen: false).fetchFavorites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Shirts'),
            Tab(text: 'Pants'),
            Tab(text: 'Shoes'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ClothesGrid(category: 'Shirt'),
          _ClothesGrid(category: 'Pants'),
          _ClothesGrid(category: 'Shoes'),
          _FavoritesGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-clothes'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ClothesGrid extends StatelessWidget {
  final String category;

  const _ClothesGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<ClothesProvider>(context);
    final items = category == 'Shirt'
        ? clothesProvider.getShirts()
        : category == 'Pants'
        ? clothesProvider.getPants()
        : clothesProvider.getShoes();

    if (clothesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checkroom, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No $category items yet. Tap + to add.'),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index];
        return _ClothingCard(item: item, category: category);
      },
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final String category;

  const _ClothingCard({required this.item, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${item.heightInches.toStringAsFixed(1)}" × ${item.widthInches.toStringAsFixed(1)}"'),
                    const SizedBox(height: 4),
                    Text(category, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove item'),
        content: const Text('This item will be deleted permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Provider.of<ClothesProvider>(context, listen: false).removeClothingItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FavoritesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoriteProvider>(context);
    final clothesProvider = Provider.of<ClothesProvider>(context);
    final favorites = favProvider.favorites;

    if (favProvider.isLoading || clothesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favorites.isEmpty) {
      return const Center(
        child: Text('No favorite outfits saved. Go to Generate Outfit page.'),
      );
    }

    // Helper returns null if item not found (no exception)
    ClothingItem? getItem(String id, String category) {
      final list = category == 'Shirt'
          ? clothesProvider.getShirts()
          : category == 'Pants'
          ? clothesProvider.getPants()
          : clothesProvider.getShoes();
      try {
        return list.firstWhere((e) => e.id == id);
      } catch (e) {
        return null;
      }
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: favorites.length,
      itemBuilder: (ctx, index) {
        final fav = favorites[index];
        final shirt = getItem(fav.shirtId, 'Shirt');
        final pants = getItem(fav.pantsId, 'Pants');
        final shoes = getItem(fav.shoesId, 'Shoes');

        // Show error card if any item is missing
        if (shirt == null || pants == null || shoes == null) {
          return const Card(
            child: Center(child: Text('Missing item', textAlign: TextAlign.center)),
          );
        }

        return Card(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Image.network(shirt.imageUrl, fit: BoxFit.contain)),
                    Expanded(child: Image.network(pants.imageUrl, fit: BoxFit.contain)),
                    Expanded(child: Image.network(shoes.imageUrl, fit: BoxFit.contain)),
                  ],
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