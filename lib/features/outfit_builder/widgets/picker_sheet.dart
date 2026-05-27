import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

class PickerSheet extends StatelessWidget {
  final List<String> categories;
  final void Function(String category, ClothingItem item) onPicked;

  const PickerSheet({super.key, required this.categories, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<CatalogProvider>(context);

    List<ClothingItem> getItems(String category) {
      switch (category) {
        case 'Headwear': return clothesProvider.getHeadwear();
        case 'Outer': return clothesProvider.getOuter();
        case 'Inner': return clothesProvider.getInner();
        case 'Bottoms': return clothesProvider.getBottoms();
        case 'Shoes': return clothesProvider.getShoes();
        default: return [];
      }
    }

    return SizedBox(
      height: 400,
      child: DefaultTabController(
        length: categories.length,
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: TabBar(
                isScrollable: true,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                indicator: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                tabs: categories.map((c) => Tab(text: c)).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: categories.map((category) {
                  final items = getItems(category);
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No items in this category.'),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/add-clothes'),
                            child: Container(
                              width: 120,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                border: Border(
                                  top: BorderSide(color: Colors.black, width: 1),
                                  bottom: BorderSide(color: Colors.black, width: 1),
                                  left: BorderSide(color: Colors.black, width: 1),
                                  right: BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: const Center(
                                child: Text('Add New',
                                    style: TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => onPicked(category, item),
                        child: Column(
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
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.category,
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
