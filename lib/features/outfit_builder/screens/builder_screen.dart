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

  Widget _buildCarouselSection({
    required String title,
    required List<ClothingItem> items,
    required ClothingItem? selectedItem,
    required ValueChanged<ClothingItem> onChanged,
    required bool locked,
    required VoidCallback onLockToggle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(locked ? Icons.lock : Icons.lock_open, size: 18),
                  onPressed: onLockToggle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: items.isEmpty
              ? Center(
                  child: Text('No $title yet', style: const TextStyle(color: Colors.grey)),
                )
              : ClothingCarousel(
                  items: items,
                  selectedItem: selectedItem,
                  onItemChanged: onChanged,
                ),
        ),
      ],
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/clothes'),
        ),
        title: const Text('Outfit'),
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
                      _buildCarouselSection(
                        title: 'Outer',
                        items: clothesProvider.getOuter(),
                        selectedItem: selectedOuter,
                        onChanged: (item) => setState(() => selectedOuter = item),
                        locked: outerLocked,
                        onLockToggle: () => setState(() => outerLocked = !outerLocked),
                      ),
                    _buildCarouselSection(
                      title: 'Inner',
                      items: clothesProvider.getInner(),
                      selectedItem: selectedInner,
                      onChanged: (item) => setState(() => selectedInner = item),
                      locked: innerLocked,
                      onLockToggle: () => setState(() => innerLocked = !innerLocked),
                    ),
                    _buildCarouselSection(
                      title: 'Pants',
                      items: clothesProvider.getPants(),
                      selectedItem: selectedPants,
                      onChanged: (item) => setState(() => selectedPants = item),
                      locked: pantsLocked,
                      onLockToggle: () => setState(() => pantsLocked = !pantsLocked),
                    ),
                    _buildCarouselSection(
                      title: 'Shoes',
                      items: clothesProvider.getShoes(),
                      selectedItem: selectedShoes,
                      onChanged: (item) => setState(() => selectedShoes = item),
                      locked: shoesLocked,
                      onLockToggle: () => setState(() => shoesLocked = !shoesLocked),
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

class ClothingCarousel extends StatefulWidget {
  final List<ClothingItem> items;
  final ClothingItem? selectedItem;
  final ValueChanged<ClothingItem> onItemChanged;

  const ClothingCarousel({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemChanged,
  });

  @override
  State<ClothingCarousel> createState() => _ClothingCarouselState();
}

class _ClothingCarouselState extends State<ClothingCarousel> {
  late PageController _pageController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.55);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToSelected();
      _initialized = true;
    });
  }

  @override
  void didUpdateWidget(ClothingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialized && widget.items.length == oldWidget.items.length) {
      final newIndex = widget.selectedItem != null
          ? widget.items.indexOf(widget.selectedItem!)
          : -1;
      final oldIndex = oldWidget.selectedItem != null
          ? oldWidget.items.indexOf(oldWidget.selectedItem!)
          : -1;
      if (newIndex != -1 && newIndex != oldIndex) {
        _pageController.animateToPage(
          newIndex + 5000,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _syncToSelected() {
    if (widget.selectedItem != null && widget.items.isNotEmpty) {
      final index = widget.items.indexOf(widget.selectedItem!);
      if (index != -1) {
        _pageController.jumpToPage(index + 5000);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length * 10000,
          onPageChanged: (page) {
            widget.onItemChanged(widget.items[page % widget.items.length]);
          },
          itemBuilder: (context, index) {
            final item = widget.items[index % widget.items.length];
            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double scale = 1.0;
                if (_pageController.position.hasContentDimensions) {
                  final pos = _pageController.page ?? index.toDouble();
                  final diff = (pos - index).abs();
                  scale = 1.0 - (diff * 0.2);
                  scale = scale.clamp(0.8, 1.0);
                }
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            );
          },
        ),
        IgnorePointer(
          child: Row(
            children: [
              Container(
                width: 30,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [bgColor, bgColor.withValues(alpha: 0)],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 30,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [bgColor, bgColor.withValues(alpha: 0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
