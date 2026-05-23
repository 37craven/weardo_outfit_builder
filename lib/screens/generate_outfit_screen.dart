import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_item.dart';
import 'package:weardo_outfit_builder/models/favorite_outfit.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:weardo_outfit_builder/providers/favorite_provider.dart';
import 'package:weardo_outfit_builder/providers/auth_provider.dart';


class GenerateOutfitScreen extends StatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  State<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends State<GenerateOutfitScreen> {
  // Current selected items
  ClothingItem? selectedShirt;
  ClothingItem? selectedPants;
  ClothingItem? selectedShoes;

  // Lock states
  bool shirtLocked = false;
  bool pantsLocked = false;
  bool shoesLocked = false;

  // Reference size: 30 inches -> 200 logical pixels
  static const double referenceInches = 30.0;
  static const double referencePixels = 200.0;

  @override
  void initState() {
    super.initState();
    // Load user's clothes and pick random initial outfit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
      clothesProvider.fetchUserClothes().then((_) {
        _randomizeOutfit();
      });
    });
  }

  void _randomizeOutfit() {
    final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
    final shirts = clothesProvider.getShirts();
    final pants = clothesProvider.getPants();
    final shoes = clothesProvider.getShoes();

    setState(() {
      if (!shirtLocked && shirts.isNotEmpty) {
        selectedShirt = (shirts..shuffle()).first;
      }
      if (!pantsLocked && pants.isNotEmpty) {
        selectedPants = (pants..shuffle()).first;
      }
      if (!shoesLocked && shoes.isNotEmpty) {
        selectedShoes = (shoes..shuffle()).first;
      }
    });
  }

  double _scaleWidth(double inches) {
    return (inches / referenceInches) * referencePixels;
  }

  double _scaleHeight(double inches, double aspectRatio) {
    // aspectRatio = width/height from original image? Better to use image's intrinsic size.
    // For simplicity, we'll use the input height inches to scale height proportionally.
    return (inches / referenceInches) * referencePixels;
  }

  Widget _buildClothingBox({
    required ClothingItem? item,
    required bool locked,
    required VoidCallback onLockToggle,
    required VoidCallback onArrowLeft,
    required VoidCallback onArrowRight,
    required Alignment alignment, // for shirt bottom, pants top
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock and arrow row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(locked ? Icons.lock : Icons.lock_open),
                  onPressed: onLockToggle,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onArrowLeft,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: onArrowRight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Image container with alignment
          if (item != null)
            SizedBox(
              height: _scaleHeight(item.heightInches, 1.0),
              child: Align(
                alignment: alignment,
                child: Image.network(
                  item.imageUrl,
                  width: _scaleWidth(item.widthInches),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No item available. Add clothes first.'),
            ),
        ],
      ),
    );
  }

  void _changeItem(String category, int direction) {
    final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
    List<ClothingItem> items;
    ClothingItem? current;
    bool locked;

    switch (category) {
      case 'shirt':
        items = clothesProvider.getShirts();
        current = selectedShirt;
        locked = shirtLocked;
        break;
      case 'pants':
        items = clothesProvider.getPants();
        current = selectedPants;
        locked = pantsLocked;
        break;
      case 'shoes':
        items = clothesProvider.getShoes();
        current = selectedShoes;
        locked = shoesLocked;
        break;
      default:
        return;
    }

    if (locked || items.isEmpty) return;
    if (items.length == 1) return; // only one item, cannot change

    int currentIndex = items.indexOf(current!);
    int newIndex = (currentIndex + direction) % items.length;
    if (newIndex < 0) newIndex = items.length - 1;

    setState(() {
      switch (category) {
        case 'shirt':
          selectedShirt = items[newIndex];
          break;
        case 'pants':
          selectedPants = items[newIndex];
          break;
        case 'shoes':
          selectedShoes = items[newIndex];
          break;
      }
    });
  }

  Future<void> _saveToFavorites() async {
    if (selectedShirt == null || selectedPants == null || selectedShoes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete outfit required (shirt, pants, shoes)')),
      );
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final newFavorite = FavoriteOutfit(
      id: const Uuid().v4(),
      userId: userId,
      shirtId: selectedShirt!.id,
      pantsId: selectedPants!.id,
      shoesId: selectedShoes!.id,
      savedAt: DateTime.now(),
    );

    await Provider.of<FavoriteProvider>(context, listen: false).addFavorite(newFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Outfit saved to favorites')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Outfit')),
      body: Consumer<ClothesProvider>(
        builder: (context, clothesProvider, child) {
          if (clothesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Check if user has at least one of each category
          final hasShirt = clothesProvider.getShirts().isNotEmpty;
          final hasPants = clothesProvider.getPants().isNotEmpty;
          final hasShoes = clothesProvider.getShoes().isNotEmpty;

          if (!hasShirt || !hasPants || !hasShoes) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Missing clothing items.'),
                  const SizedBox(height: 16),
                  if (!hasShirt) const Text('• Add at least one shirt'),
                  if (!hasPants) const Text('• Add at least one pair of pants'),
                  if (!hasShoes) const Text('• Add at least one pair of shoes'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/add-clothes'),
                    child: const Text('Add Clothes'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Shirt box - image aligned at bottom
                      _buildClothingBox(
                        item: selectedShirt,
                        locked: shirtLocked,
                        onLockToggle: () => setState(() => shirtLocked = !shirtLocked),
                        onArrowLeft: () => _changeItem('shirt', -1),
                        onArrowRight: () => _changeItem('shirt', 1),
                        alignment: Alignment.bottomCenter,
                      ),
                      // Pants box - image aligned at top
                      _buildClothingBox(
                        item: selectedPants,
                        locked: pantsLocked,
                        onLockToggle: () => setState(() => pantsLocked = !pantsLocked),
                        onArrowLeft: () => _changeItem('pants', -1),
                        onArrowRight: () => _changeItem('pants', 1),
                        alignment: Alignment.topCenter,
                      ),
                      // Shoes box - top view, centered
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(shoesLocked ? Icons.lock : Icons.lock_open),
                                    onPressed: () => setState(() => shoesLocked = !shoesLocked),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () => _changeItem('shoes', -1),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward),
                                        onPressed: () => _changeItem('shoes', 1),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (selectedShoes != null)
                              SizedBox(
                                height: _scaleHeight(selectedShoes!.heightInches, 1.0),
                                child: Center(
                                  child: Image.network(
                                    selectedShoes!.imageUrl,
                                    width: _scaleWidth(selectedShoes!.widthInches),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('No shoes available'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _saveToFavorites,
                      icon: const Icon(Icons.favorite_border),
                      label: const Text('Save to Favorites'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _randomizeOutfit,
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Randomize'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}