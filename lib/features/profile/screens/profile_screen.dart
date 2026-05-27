import 'package:flutter/material.dart';
import 'package:flutter_boring_avatars/flutter_boring_avatars.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/features/profile/widgets/saved_outfits_grid.dart';
import 'package:weardo_outfit_builder/features/profile/widgets/saved_outfit_card.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final clothesProvider = Provider.of<CatalogProvider>(context);
    final savedProvider = Provider.of<SavedOutfitsProvider>(context);

    final name = authProvider.username ?? 'User';
    final email = authProvider.currentUser?.email ?? '';


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
                          SizedBox(
                            width: 128,
                            height: 128,
                            child: BoringAvatar(
                              name: email,
                              type: BoringAvatarType.beam,
                              palette: const BoringAvatarPalette([
                                Color(0xFFFFFFFF),
                                Color(0xFF000000),
                                Color(0xFF424242),
                                Color(0xFFBDBDBD),
                              ]),
                              shape: const OvalBorder(),
                            ),
                          ),
                          Column(
                            children: [
                              Text('@$name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(email, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            ],
                          ),
                          Text(
                            '${clothesProvider.getItemCount()} items in catalog',
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
                    _buildSavedOutfits(savedProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedOutfits(SavedOutfitsProvider savedProvider) {
    if (savedProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedProvider.savedOutfits.isEmpty) {
      return savedProvider.hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 60, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Could not load saved outfits'),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: savedProvider.retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _buildEmptyState();
    }

    return Column(
      children: [
        if (savedProvider.hasError)
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
                  onPressed: savedProvider.retry,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        SavedOutfitsGrid(
          outfits: savedProvider.savedOutfits,
          cardBuilder: (outfit, cardWidth) => SavedOutfitCard(
            fav: outfit,
            cardWidth: cardWidth,
            showDelete: _deleteTargetId == outfit.id,
            onTap: () {
              savedProvider.requestLoad(outfit);
              context.go('/builder');
            },
            onLongPress: () => setState(() => _deleteTargetId = _deleteTargetId == outfit.id ? null : outfit.id),
            onDelete: () async {
              try {
                await savedProvider.removeSavedOutfit(outfit.id);
                setState(() => _deleteTargetId = null);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Outfit removed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to remove outfit')),
                  );
                }
              }
            },
          ),
        ),
      ],
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
          const Text(
            'No saved outfits yet. Go to Builder to create and save outfits.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
