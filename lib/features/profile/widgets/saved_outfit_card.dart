import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';
import 'package:weardo_outfit_builder/features/profile/widgets/outfit_preview.dart';
import 'package:weardo_outfit_builder/widgets/confirm_dialog.dart';

class SavedOutfitCard extends StatelessWidget {
  final FavoriteOutfit fav;
  final double cardWidth;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const SavedOutfitCard({
    super.key,
    required this.fav,
    required this.cardWidth,
    required this.showDelete,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  ClothingItem? _findItem(String id, String category, CatalogProvider provider) {
    final list = switch (category) {
      'Headwear' => provider.getHeadwear(),
      'Outer' => provider.getOuter(),
      'Inner' => provider.getInner(),
      'Bottoms' => provider.getBottoms(),
      'Shoes' => provider.getShoes(),
      _ => <ClothingItem>[],
    };
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<CatalogProvider>(context);

    final headwear = fav.headwearId != null ? _findItem(fav.headwearId!, 'Headwear', clothesProvider) : null;
    final hasOuter = fav.outerId != null;
    final outer = hasOuter ? _findItem(fav.outerId!, 'Outer', clothesProvider) : null;
    final inner = _findItem(fav.innerId, 'Inner', clothesProvider);
    final bottoms = _findItem(fav.pantsId, 'Bottoms', clothesProvider);
    final shoes = _findItem(fav.shoesId, 'Shoes', clothesProvider);

    final items = <ClothingItem>[];
    if (headwear != null) items.add(headwear);
    if (hasOuter && outer != null) items.add(outer);
    if (inner != null) items.add(inner);
    if (bottoms != null) items.add(bottoms);
    if (shoes != null) items.add(shoes);

    final hasHeadwear = headwear != null;
    final headwearHeight = cardWidth * 0.25;
    final cardHeight = cardWidth + (hasHeadwear ? headwearHeight : 0) + 2;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.black, width: 1),
                  bottom: BorderSide(color: Colors.black, width: 1),
                  left: BorderSide(color: Colors.black, width: 1),
                  right: BorderSide(color: Colors.black, width: 1),
                ),
              ),
              child: items.isEmpty
                  ? const Center(child: Text('Missing item'))
                  : Column(
                      children: [
                        if (hasHeadwear)
                          SizedBox(
                            height: headwearHeight,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Image.network(headwear.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                            ),
                          ),
                        SizedBox(
                          height: cardWidth,
                          child: OutfitPreview(
                            outer: outer,
                            inner: inner,
                            bottoms: bottoms,
                            shoes: shoes,
                          ),
                        ),
                      ],
                    ),
            ),
            if (showDelete)
              GestureDetector(
                onTap: () => showConfirmDialog(
                  context: context,
                  title: 'Remove saved outfit?',
                  confirmLabel: 'Remove',
                  onConfirm: onDelete,
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: const Center(child: Icon(Icons.delete, color: Colors.white, size: 40)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
