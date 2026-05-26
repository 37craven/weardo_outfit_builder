import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _deleteTargetId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CatalogProvider>(context, listen: false).fetchUserClothes();
      Provider.of<SavedOutfitsProvider>(context, listen: false).fetchSavedOutfits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clothesProvider = Provider.of<CatalogProvider>(context);
    final savedProvider = Provider.of<SavedOutfitsProvider>(context);

    final name = authProvider.username ?? 'User';
    final email = authProvider.currentUser?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Profile', style: TextStyle(fontSize: 32)),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.black,
                            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          ),
                          Column(
                            children: [
                              Text('@$name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            ],
                          ),
                          Text(
                            '${clothesProvider.getItemCount()} items in closet',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Saved Outfits', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    if (savedProvider.isLoading || clothesProvider.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (savedProvider.savedOutfits.isEmpty)
                      _buildEmptyState()
                    else
                      _buildOutfitsGrid(savedProvider, clothesProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(Icons.favorite_border, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('No saved outfits yet.', style: TextStyle(color: Colors.grey[600])),
          Text('Go to Builder to create and save outfits.', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOutfitsGrid(SavedOutfitsProvider savedProvider, CatalogProvider clothesProvider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 24.0 * 2;
    final spacing = 8.0;
    final cardWidth = (screenWidth - padding - spacing) / 2;
    final outfits = savedProvider.savedOutfits;

    double cardHeight(FavoriteOutfit f) {
      return cardWidth + (f.headwearId != null ? cardWidth * 0.25 : 0) + 2;
    }

    final col1 = <Widget>[];
    final col2 = <Widget>[];
    double h1 = 0, h2 = 0;

    for (var i = 0; i < outfits.length; i++) {
      final h = cardHeight(outfits[i]);
      final card = Padding(
        padding: EdgeInsets.only(top: (h1 <= h2 ? col1 : col2).isEmpty ? 0 : spacing),
        child: _buildOutfitCard(outfits[i], cardWidth, clothesProvider, savedProvider),
      );
      if (h1 <= h2) {
        col1.add(card);
        h1 += h + spacing;
      } else {
        col2.add(card);
        h2 += h + spacing;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: col1)),
        const SizedBox(width: 8),
        Expanded(child: Column(children: col2)),
      ],
    );
  }

  Widget _buildOutfitCard(FavoriteOutfit fav, double cardWidth, CatalogProvider clothesProvider, SavedOutfitsProvider savedProvider) {
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

    final showDelete = _deleteTargetId == fav.id;

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: GestureDetector(
        onTap: () {
          savedProvider.requestLoad(fav);
          context.go('/builder');
        },
        onLongPress: () => setState(() => _deleteTargetId = showDelete ? null : fav.id),
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
                          child: _buildOrganizedOutfit(outer, inner, bottoms, shoes),
                        ),
                      ],
                    ),
            ),
            if (showDelete)
              GestureDetector(
                onTap: () => savedProvider.removeSavedOutfit(fav.id),
                child: Container(
                  color: Colors.red.withValues(alpha: 0.8),
                  child: const Center(child: Icon(Icons.delete, color: Colors.white, size: 40)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizedOutfit(ClothingItem? outer, ClothingItem? inner, ClothingItem? bottoms, ClothingItem? shoes) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (outer == null && inner == null) {
                return const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey));
              }
              final offset = outer != null && inner != null ? constraints.maxWidth * 0.08 : 0.0;
              return Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    if (outer != null)
                      Positioned(
                        left: 0, top: 0, bottom: 0, right: offset,
                        child: Image.network(outer.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    if (inner != null)
                      Positioned(
                        left: offset, top: 0, bottom: 0, right: 0,
                        child: Image.network(inner.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: bottoms != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(bottoms.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                )
              : const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey)),
        ),
        Expanded(
          flex: 3,
          child: shoes != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(shoes.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                )
              : const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey)),
        ),
      ],
    );
  }

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

}
