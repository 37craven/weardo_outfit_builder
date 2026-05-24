import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class GenerateOutfitScreen extends StatefulWidget {
  const GenerateOutfitScreen({super.key});

  @override
  State<GenerateOutfitScreen> createState() => _GenerateOutfitScreenState();
}

class _GenerateOutfitScreenState extends State<GenerateOutfitScreen> {
  ClothingItem? selectedOuter;
  ClothingItem? selectedInner;
  ClothingItem? selectedPants;
  ClothingItem? selectedShoes;

  bool outerLocked = false;
  bool innerLocked = false;
  bool pantsLocked = false;
  bool shoesLocked = false;

  bool _twoLayerMode = false;

  static const double referenceInches = 30.0;
  static const double referencePixels = 200.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndRandomize();
    });
  }

  Future<void> _loadAndRandomize() async {
    final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
    await clothesProvider.fetchUserClothes();
    _randomizeOutfit();
  }

  void _randomizeOutfit() {
    final clothesProvider = Provider.of<ClothesProvider>(context, listen: false);
    final outer = clothesProvider.getOuter();
    final inner = clothesProvider.getInner();
    final pants = clothesProvider.getPants();
    final shoes = clothesProvider.getShoes();

    setState(() {
      if (_twoLayerMode && !outerLocked && outer.isNotEmpty) {
        selectedOuter = (outer..shuffle()).first;
      }
      if (!innerLocked && inner.isNotEmpty) {
        selectedInner = (inner..shuffle()).first;
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

  Widget _buildClothingBox({
    required ClothingItem? item,
    required bool locked,
    required VoidCallback onLockToggle,
    required VoidCallback onArrowLeft,
    required VoidCallback onArrowRight,
    required Alignment alignment,
    required String emptyLabel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(locked ? Icons.lock : Icons.lock_open, size: 20),
                  onPressed: onLockToggle,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      onPressed: onArrowLeft,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      onPressed: onArrowRight,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (item != null)
            SizedBox(
              height: _scaleWidth(item.heightInches),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(emptyLabel, style: const TextStyle(color: Colors.grey)),
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
      case 'outer':
        items = clothesProvider.getOuter();
        current = selectedOuter;
        locked = outerLocked;
        break;
      case 'inner':
        items = clothesProvider.getInner();
        current = selectedInner;
        locked = innerLocked;
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

    if (locked || items.isEmpty || items.length == 1) return;

    final currentIndex = items.indexOf(current!);
    int newIndex = (currentIndex + direction) % items.length;
    if (newIndex < 0) newIndex = items.length - 1;

    setState(() {
      switch (category) {
        case 'outer':
          selectedOuter = items[newIndex];
          break;
        case 'inner':
          selectedInner = items[newIndex];
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

  Future<void> _saveOutfit() async {
    final missing = <String>[];
    if (selectedInner == null) missing.add('Inner');
    if (selectedPants == null) missing.add('Pants');
    if (selectedShoes == null) missing.add('Shoes');
    if (_twoLayerMode && selectedOuter == null) missing.add('Outer');

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing: ${missing.join(', ')}')),
      );
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    final newFavorite = FavoriteOutfit(
      id: const Uuid().v4(),
      userId: userId,
      outerId: _twoLayerMode ? selectedOuter!.id : null,
      innerId: selectedInner!.id,
      pantsId: selectedPants!.id,
      shoesId: selectedShoes!.id,
      savedAt: DateTime.now(),
    );

    await Provider.of<FavoriteProvider>(context, listen: false).addFavorite(newFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit saved! View in Profile.')),
      );
    }
  }

  void _showItemPicker(BuildContext context) {
    final categories = ['Outer', 'Inner', 'Pants', 'Shoes'];
    if (!_twoLayerMode) categories.remove('Outer');

    showModalBottomSheet(
      context: context,
      builder: (ctx) => _PickerSheet(
        categories: categories,
        onPicked: (category, item) {
          Navigator.pop(ctx);
          setState(() {
            switch (category) {
              case 'Outer': selectedOuter = item; break;
              case 'Inner': selectedInner = item; break;
              case 'Pants': selectedPants = item; break;
              case 'Shoes': selectedShoes = item; break;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Outfit'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_twoLayerMode ? '2 Layers' : '1 Layer', style: const TextStyle(fontSize: 13)),
                Switch(
                  value: _twoLayerMode,
                  onChanged: (v) => setState(() => _twoLayerMode = v),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<ClothesProvider>(
        builder: (context, clothesProvider, child) {
          if (clothesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final hasOuter = clothesProvider.getOuter().isNotEmpty;
          final hasInner = clothesProvider.getInner().isNotEmpty;
          final hasPants = clothesProvider.getPants().isNotEmpty;
          final hasShoes = clothesProvider.getShoes().isNotEmpty;
          final canGenerate = hasInner && hasPants && hasShoes && (!_twoLayerMode || hasOuter);

          if (!canGenerate) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Missing clothing items.'),
                  const SizedBox(height: 16),
                  if (!hasOuter) const Text('• Add at least one outer'),
                  if (!hasInner) const Text('• Add at least one inner'),
                  if (!hasPants) const Text('• Add at least one pair of pants'),
                  if (!hasShoes) const Text('• Add at least one pair of shoes'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/add-clothes'),
                    child: const Text('Add Clothes'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    if (_twoLayerMode)
                      _buildClothingBox(
                        item: selectedOuter,
                        locked: outerLocked,
                        onLockToggle: () => setState(() => outerLocked = !outerLocked),
                        onArrowLeft: () => _changeItem('outer', -1),
                        onArrowRight: () => _changeItem('outer', 1),
                        alignment: Alignment.bottomCenter,
                        emptyLabel: 'No outer selected',
                      ),
                    _buildClothingBox(
                      item: selectedInner,
                      locked: innerLocked,
                      onLockToggle: () => setState(() => innerLocked = !innerLocked),
                      onArrowLeft: () => _changeItem('inner', -1),
                      onArrowRight: () => _changeItem('inner', 1),
                      alignment: _twoLayerMode ? Alignment.bottomCenter : Alignment.center,
                      emptyLabel: 'No inner selected',
                    ),
                    _buildClothingBox(
                      item: selectedPants,
                      locked: pantsLocked,
                      onLockToggle: () => setState(() => pantsLocked = !pantsLocked),
                      onArrowLeft: () => _changeItem('pants', -1),
                      onArrowRight: () => _changeItem('pants', 1),
                      alignment: Alignment.topCenter,
                      emptyLabel: 'No pants selected',
                    ),
                    _buildClothingBox(
                      item: selectedShoes,
                      locked: shoesLocked,
                      onLockToggle: () => setState(() => shoesLocked = !shoesLocked),
                      onArrowLeft: () => _changeItem('shoes', -1),
                      onArrowRight: () => _changeItem('shoes', 1),
                      alignment: Alignment.center,
                      emptyLabel: 'No shoes selected',
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'add',
                      onPressed: () => _showItemPicker(context),
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      heroTag: 'shuffle',
                      onPressed: _randomizeOutfit,
                      child: const Icon(Icons.shuffle),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'save',
                      onPressed: _saveOutfit,
                      child: const Icon(Icons.favorite_border),
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

class _PickerSheet extends StatelessWidget {
  final List<String> categories;
  final void Function(String category, ClothingItem item) onPicked;

  const _PickerSheet({required this.categories, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final clothesProvider = Provider.of<ClothesProvider>(context);

    List<ClothingItem> getItems(String category) {
      switch (category) {
        case 'Outer': return clothesProvider.getOuter();
        case 'Inner': return clothesProvider.getInner();
        case 'Pants': return clothesProvider.getPants();
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
            TabBar(
              isScrollable: true,
              tabs: categories.map((c) => Tab(text: c)).toList(),
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
                          ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, '/add-clothes'),
                            child: const Text('Add New'),
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
                        child: Card(
                          child: Column(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(item.imageUrl, fit: BoxFit.contain),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '${item.heightInches.toStringAsFixed(1)}"',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
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
