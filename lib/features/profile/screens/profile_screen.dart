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
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: savedProvider.savedOutfits.length,
                        itemBuilder: (ctx, index) {
                          final fav = savedProvider.savedOutfits[index];
                          return _buildOutfitCard(fav, clothesProvider, savedProvider);
                        },
                      ),
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

  Widget _buildOutfitCard(FavoriteOutfit fav, CatalogProvider clothesProvider, SavedOutfitsProvider savedProvider) {
    final hasOuter = fav.outerId != null;
    final outer = hasOuter ? _findItem(fav.outerId!, 'Outer', clothesProvider) : null;
    final inner = _findItem(fav.innerId, 'Inner', clothesProvider);
    final bottoms = _findItem(fav.pantsId, 'Bottoms', clothesProvider);
    final shoes = _findItem(fav.shoesId, 'Shoes', clothesProvider);

    final items = <ClothingItem>[];
    if (hasOuter && outer != null) items.add(outer);
    if (inner != null) items.add(inner);
    if (bottoms != null) items.add(bottoms);
    if (shoes != null) items.add(shoes);

    final showDelete = _deleteTargetId == fav.id;

    return GestureDetector(
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
                : _buildClothesPile(items),
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
    );
  }

  Widget _buildClothesPile(List<ClothingItem> items) {
    final poses = [
      const Offset(0, 0),
      const Offset(6, -4),
      const Offset(-4, 6),
      const Offset(2, -2),
    ];

    final rotations = [-0.18, 0.15, -0.1, 0.12];

    return Stack(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(
              left: 8 + poses[i].dx,
              top: 8 + poses[i].dy,
              right: 8 - poses[i].dx,
              bottom: 8 - poses[i].dy,
            ),
            child: Transform.rotate(
              angle: rotations[i],
              child: ClipRect(
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  ClothingItem? _findItem(String id, String category, CatalogProvider provider) {
    final list = switch (category) {
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
