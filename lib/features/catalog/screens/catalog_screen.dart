import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/widgets/floating_action_button.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false).fetchUserClothes();
    });
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
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 1),
                  right: BorderSide(color: Colors.black, width: 1),
                  top: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => Container(width: 1, color: Colors.black),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final selected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? Colors.black : Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        alignment: Alignment.center,
                        child: Text(
                          category == 'all' ? 'All' : category[0].toUpperCase() + category.substring(1),
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: Consumer<CatalogProvider>(
              builder: (context, clothesProvider, child) {
                final items = _filteredItems(clothesProvider);

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
                        Text('No items yet. Tap + to add.'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    return _CatalogItemCard(item: items[index]);
                  },
                );
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

class _CatalogItemCard extends StatelessWidget {
  final ClothingItem item;

  const _CatalogItemCard({required this.item});

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(child: Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Center(child: Text(item.category, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Provider.of<CatalogProvider>(ctx, listen: false).toggleFavoriteItem(item.id);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            height: 44,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1),
                                bottom: BorderSide(color: Colors.black, width: 1),
                                left: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.isFavorited ? Icons.star : Icons.star_border,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(item.isFavorited ? 'Favorited' : 'Favorite'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            Provider.of<CatalogProvider>(context, listen: false).removeClothingItem(item.id);
                          },
                          child: Container(
                            height: 44,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1),
                                bottom: BorderSide(color: Colors.black, width: 1),
                                left: BorderSide(color: Colors.black, width: 1),
                                right: BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: 20),
                                  SizedBox(width: 6),
                                  Text('Remove'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(child: Icon(Icons.close, size: 18)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                  left: BorderSide(color: Colors.black, width: 1),
                  right: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: ClipRect(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(item.category, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  item.isFavorited ? Icons.star : Icons.star_border,
                  color: item.isFavorited ? Colors.black : null,
                  size: 24,
                ),
                onPressed: () {
                  Provider.of<CatalogProvider>(context, listen: false).toggleFavoriteItem(item.id);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
