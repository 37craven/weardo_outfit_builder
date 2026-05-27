import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/widgets/floating_action_button.dart';
import 'package:weardo_outfit_builder/features/catalog/widgets/catalog_item_card.dart';
import 'package:weardo_outfit_builder/features/catalog/widgets/category_filter_bar.dart';
import 'package:go_router/go_router.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';

  static const _categories = ['all', 'Headwear', 'Outer Tops', 'Inner Tops', 'Bottoms', 'Footwear'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Catalog', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: Colors.black, width: 1),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            CategoryFilterBar(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 8),
            Expanded(child: Consumer<CatalogProvider>(
              builder: (context, clothesProvider, child) {
                final items = _filteredItems(clothesProvider);

                if (clothesProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (items.isEmpty) {
                  if (clothesProvider.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off, size: 60, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text('Could not load items'),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: clothesProvider.retry,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checkroom, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No items yet. Tap + to add.'),
                      ],
                    ),
                  );
                }

                if (clothesProvider.hasError) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: const BoxDecoration(color: Colors.redAccent),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Connection lost', style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: clothesProvider.retry,
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _buildGrid(items),
                      ),
                    ],
                  );
                }

                return _buildGrid(items);
              },
            )),
          ],
        ),
      ),
          Positioned(
            right: 24,
            bottom: 24,
            child: AppFloatingActionButton(
              icon: Icons.add,
              onPressed: () => context.go('/add-clothes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ClothingItem> items) {
    final availableWidth = MediaQuery.of(context).size.width - 48;
    final crossAxisCount = (availableWidth / 180).floor().clamp(2, 4);

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        return CatalogItemCard(item: items[index]);
      },
    );
  }

  List<ClothingItem> _filteredItems(CatalogProvider provider) {
    List<ClothingItem> items;
    switch (_selectedCategory) {
      case 'Headwear': items = provider.getHeadwear(); break;
      case 'Outer Tops': items = provider.getOuterTops(); break;
      case 'Inner Tops': items = provider.getInnerTops(); break;
      case 'Bottoms': items = provider.getBottoms(); break;
      case 'Footwear': items = provider.getFootwear(); break;
      default: items = provider.allClothes; break;
    }

    if (_searchQuery.isNotEmpty) {
      items = items.where((i) =>
        i.name.toLowerCase().contains(_searchQuery) ||
        i.category.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    return items;
  }
}
