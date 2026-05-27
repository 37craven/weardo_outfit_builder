import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/widgets/confirm_dialog.dart';

class CatalogItemCard extends StatelessWidget {
  final ClothingItem item;

  const CatalogItemCard({super.key, required this.item});

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
                                  Text(item.isFavorited ? 'Unfavorite' : 'Favorite'),
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
                            showConfirmDialog(
                              context: context,
                              title: 'Remove item?',
                              subtitle: item.name,
                              confirmLabel: 'Remove',
                              onConfirm: () async {
                                try {
                                  await Provider.of<CatalogProvider>(context, listen: false).removeClothingItem(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Item removed')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to remove item')),
                                    );
                                  }
                                }
                              },
                            );
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
