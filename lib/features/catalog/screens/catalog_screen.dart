import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:go_router/go_router.dart';
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false).fetchUserClothes();
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
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Outer'),
            Tab(text: 'Inner'),
            Tab(text: 'Pants'),
            Tab(text: 'Shoes'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CatalogGrid(category: 'All'),
          _CatalogGrid(category: 'Outer'),
          _CatalogGrid(category: 'Inner'),
          _CatalogGrid(category: 'Pants'),
          _CatalogGrid(category: 'Shoes'),
          _FavoritedGrid(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-clothes'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  final String category;

  const _CatalogGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<CatalogProvider>(context);
    final items = category == 'All'
        ? clothesProvider.allClothes
        : category == 'Outer'
        ? clothesProvider.getOuter()
        : category == 'Inner'
        ? clothesProvider.getInner()
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
        return _CatalogItemCard(item: item);
      },
    );
  }
}

class _CatalogItemCard extends StatelessWidget {
  final ClothingItem item;

  const _CatalogItemCard({required this.item});

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
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.category, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    item.isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: item.isFavorited ? Colors.red : null,
                    size: 20,
                  ),
                  onPressed: () {
                    Provider.of<CatalogProvider>(context, listen: false).toggleFavoriteItem(item.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _confirmDelete(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
              Provider.of<CatalogProvider>(context, listen: false).removeClothingItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _FavoritedGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<CatalogProvider>(context);
    final items = clothesProvider.getFavoriteItems();

    if (clothesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No favorite items yet. Tap the heart on any item to like it.'),
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
        return _CatalogItemCard(item: items[index]);
      },
    );
  }
}
