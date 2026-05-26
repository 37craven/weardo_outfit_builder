import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/widgets/floating_action_button.dart';
import 'package:weardo_outfit_builder/widgets/button.dart';
import 'package:weardo_outfit_builder/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class BuilderScreen extends StatefulWidget {
  const BuilderScreen({super.key});

  @override
  State<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends State<BuilderScreen> {
  ClothingItem? selectedHeadwear;
  ClothingItem? selectedOuter;
  ClothingItem? selectedInner;
  ClothingItem? selectedBottoms;
  ClothingItem? selectedShoes;

  bool headwearLocked = false;
  bool outerLocked = false;
  bool innerLocked = false;
  bool bottomsLocked = false;
  bool shoesLocked = false;

  bool _twoLayerMode = false;
  bool _headwearEnabled = false;

  SavedOutfitsProvider? _savedProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savedProvider = Provider.of<SavedOutfitsProvider>(context, listen: false);
      _savedProvider!.addListener(_onSavedChanged);
      _loadAndRandomize();
    });
  }

  @override
  void dispose() {
    _savedProvider?.removeListener(_onSavedChanged);
    super.dispose();
  }

  void _onSavedChanged() {
    final pending = _savedProvider?.pendingLoad;
    if (pending == null) return;
    _savedProvider?.clearPendingLoad();

    final clothesProvider = Provider.of<CatalogProvider>(context, listen: false);
    ClothingItem? find(String id) {
      try {
        return clothesProvider.allClothes.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    setState(() {
      selectedHeadwear = pending.headwearId != null ? find(pending.headwearId!) : null;
      selectedOuter = pending.outerId != null ? find(pending.outerId!) : null;
      selectedInner = find(pending.innerId);
      selectedBottoms = find(pending.pantsId);
      selectedShoes = find(pending.shoesId);
      _twoLayerMode = pending.outerId != null;
      _headwearEnabled = pending.headwearId != null;
    });
  }

  Future<void> _loadAndRandomize() async {
    final clothesProvider = Provider.of<CatalogProvider>(context, listen: false);
    await clothesProvider.fetchUserClothes();

    final saved = Provider.of<SavedOutfitsProvider>(context, listen: false);
    final pending = saved.pendingLoad;
    if (pending != null) {
      _loadFromSaved(pending, clothesProvider);
      saved.clearPendingLoad();
    } else {
      _randomizeOutfit();
    }
  }

  void _loadFromSaved(FavoriteOutfit outfit, CatalogProvider provider) {
    ClothingItem? find(String id) {
      try {
        return provider.allClothes.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    setState(() {
      selectedHeadwear = outfit.headwearId != null ? find(outfit.headwearId!) : null;
      selectedOuter = outfit.outerId != null ? find(outfit.outerId!) : null;
      selectedInner = find(outfit.innerId);
      selectedBottoms = find(outfit.pantsId);
      selectedShoes = find(outfit.shoesId);
      _twoLayerMode = outfit.outerId != null;
      _headwearEnabled = outfit.headwearId != null;
    });
  }

  void _randomizeOutfit() {
    final clothesProvider = Provider.of<CatalogProvider>(context, listen: false);
    final outer = clothesProvider.getOuter();
    final inner = clothesProvider.getInner();
    final pants = clothesProvider.getBottoms();
    final shoes = clothesProvider.getShoes();

    final headwear = clothesProvider.getHeadwear();

    setState(() {
      if (_headwearEnabled && !headwearLocked && headwear.isNotEmpty) {
        selectedHeadwear = (headwear..shuffle()).first;
      }
      if (_twoLayerMode && !outerLocked && outer.isNotEmpty) {
        selectedOuter = (outer..shuffle()).first;
      }
      if (!innerLocked && inner.isNotEmpty) {
        selectedInner = (inner..shuffle()).first;
      }
      if (!bottomsLocked && pants.isNotEmpty) {
        selectedBottoms = (pants..shuffle()).first;
      }
      if (!shoesLocked && shoes.isNotEmpty) {
        selectedShoes = (shoes..shuffle()).first;
      }
    });
  }

  Widget _buildCarouselSection({
    required List<ClothingItem> items,
    required ClothingItem? selectedItem,
    required ValueChanged<ClothingItem> onChanged,
    required bool locked,
    required VoidCallback onLockToggle,
    required double height,
    double viewportFraction = 0.55,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(locked ? Icons.lock : Icons.lock_open, size: 18, color: Colors.black),
            onPressed: onLockToggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SizedBox(
              height: height,
              child: items.isEmpty
                  ? Center(
                      child: Text('No items', style: const TextStyle(color: Colors.grey)),
                    )
                  : ClothingCarousel(
                      items: items,
                      selectedItem: selectedItem,
                      onItemChanged: onChanged,
                      locked: locked,
                      viewportFraction: viewportFraction,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOutfit() async {
    final missing = <String>[];
    if (selectedInner == null) missing.add('Inner');
    if (selectedBottoms == null) missing.add('Bottoms');
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
      headwearId: selectedHeadwear?.id,
      outerId: _twoLayerMode ? selectedOuter!.id : null,
      innerId: selectedInner!.id,
      pantsId: selectedBottoms!.id,
      shoesId: selectedShoes!.id,
      savedAt: DateTime.now(),
    );

    await Provider.of<SavedOutfitsProvider>(context, listen: false).addSavedOutfit(newFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Outfit saved! View in Profile.')),
      );
    }
  }

  void _showItemPicker(BuildContext context) {
    final categories = ['Outer', 'Inner', 'Bottoms', 'Shoes'];
    if (!_twoLayerMode) categories.remove('Outer');
    if (_headwearEnabled) categories.insert(0, 'Headwear');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => _PickerSheet(
        categories: categories,
        onPicked: (category, item) {
          Navigator.pop(ctx);
          setState(() {
            switch (category) {
              case 'Headwear': selectedHeadwear = item; break;
              case 'Outer': selectedOuter = item; break;
              case 'Inner': selectedInner = item; break;
              case 'Bottoms': selectedBottoms = item; break;
              case 'Shoes': selectedShoes = item; break;
            }
          });
        },
      ),
    );
  }

  void _toggleLayers() {
    setState(() => _twoLayerMode = !_twoLayerMode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_twoLayerMode ? '2-Layer mode enabled' : '1-Layer mode enabled'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _toggleHeadwear() {
    setState(() => _headwearEnabled = !_headwearEnabled);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_headwearEnabled ? 'Headwear shown' : 'Headwear hidden'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CatalogProvider>(
        builder: (context, clothesProvider, child) {
          final hasOuter = clothesProvider.getOuter().isNotEmpty;
          final hasInner = clothesProvider.getInner().isNotEmpty;
          final hasBottoms = clothesProvider.getBottoms().isNotEmpty;
          final hasShoes = clothesProvider.getShoes().isNotEmpty;
          final canGenerate = hasInner && hasBottoms && hasShoes && (!_twoLayerMode || hasOuter);

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Builder', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: clothesProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : canGenerate
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.only(bottom: 100),
                                  child: Column(
                                    children: [
                                      if (_headwearEnabled)
                                        _buildCarouselSection(
                                          items: clothesProvider.getHeadwear(),
                                          selectedItem: selectedHeadwear,
                                          onChanged: (item) => setState(() => selectedHeadwear = item),
                                          locked: headwearLocked,
                                          onLockToggle: () => setState(() => headwearLocked = !headwearLocked),
                                          height: 90,
                                          viewportFraction: 0.6,
                                        ),
                                      if (_twoLayerMode)
                                        _buildCarouselSection(
                                          items: clothesProvider.getOuter(),
                                          selectedItem: selectedOuter,
                                          onChanged: (item) => setState(() => selectedOuter = item),
                                          locked: outerLocked,
                                          onLockToggle: () => setState(() => outerLocked = !outerLocked),
                                          height: 160,
                                          viewportFraction: 1.0,
                                        ),
                                      _buildCarouselSection(
                                        items: clothesProvider.getInner(),
                                        selectedItem: selectedInner,
                                        onChanged: (item) => setState(() => selectedInner = item),
                                        locked: innerLocked,
                                        onLockToggle: () => setState(() => innerLocked = !innerLocked),
                                        height: 160,
                                        viewportFraction: 0.8,
                                      ),
                                      _buildCarouselSection(
                                        items: clothesProvider.getBottoms(),
                                        selectedItem: selectedBottoms,
                                        onChanged: (item) => setState(() => selectedBottoms = item),
                                        locked: bottomsLocked,
                                        onLockToggle: () => setState(() => bottomsLocked = !bottomsLocked),
                                        height: 160,
                                        viewportFraction: 1.0,
                                      ),
                                      _buildCarouselSection(
                                        items: clothesProvider.getShoes(),
                                        selectedItem: selectedShoes,
                                        onChanged: (item) => setState(() => selectedShoes = item),
                                        locked: shoesLocked,
                                        onLockToggle: () => setState(() => shoesLocked = !shoesLocked),
                                        height: 90,
                                        viewportFraction: 0.6,
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Missing clothing items.'),
                                      const SizedBox(height: 16),
                                      if (_headwearEnabled && !clothesProvider.getHeadwear().isNotEmpty)
                                        const Text('\u2022 Add at least one Headwear'),
                                      if (_twoLayerMode && !hasOuter) const Text('\u2022 Add at least one Outer Top'),
                                      if (!hasInner) const Text('\u2022 Add at least one Inner Top'),
                                      if (!hasBottoms) const Text('\u2022 Add at least one Bottom'),
                                      if (!hasShoes) const Text('\u2022 Add at least one pair of Footwear'),
                                      const SizedBox(height: 24),
                                      PrimaryButton(
                                        label: 'Add Clothes',
                                        width: 200,
                                        onPressed: () => context.go('/add-clothes'),
                                      ),
                                    ],
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
              if (canGenerate)
                Positioned(
                  right: 24,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppFloatingActionButton(
                        icon: Icons.add,
                        onPressed: () => _showItemPicker(context),
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        icon: Icons.shuffle,
                        onPressed: _randomizeOutfit,
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        icon: Icons.favorite_border,
                        onPressed: _saveOutfit,
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        text: _twoLayerMode ? '2' : '1',
                        onPressed: _toggleLayers,
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        text: "H",
                        onPressed: _toggleHeadwear,
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
  final bool locked;
  final double viewportFraction;

  const ClothingCarousel({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onItemChanged,
    this.locked = false,
    this.viewportFraction = 0.55,
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
    _pageController = PageController(viewportFraction: widget.viewportFraction);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToSelected();
      _initialized = true;
    });
  }

  @override
  void didUpdateWidget(ClothingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) return;

    final newIndex = widget.selectedItem != null
        ? widget.items.indexOf(widget.selectedItem!)
        : -1;
    if (newIndex == -1) return;

    final currentPage = _pageController.page ?? 0;
    final currentItemIndex = currentPage.round() % widget.items.length;

    if (currentItemIndex != newIndex) {
      int targetPage = newIndex + 5000;
      if (targetPage < (_pageController.page ?? 0)) {
        targetPage += widget.items.length;
      }
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
          physics: widget.locked ? const NeverScrollableScrollPhysics() : null,
          itemCount: widget.items.length * 10000,
          onPageChanged: (page) {
            if (!widget.locked) {
              widget.onItemChanged(widget.items[page % widget.items.length]);
            }
          },
          itemBuilder: (context, index) {
            final item = widget.items[index % widget.items.length];
            return Center(
              child: AnimatedBuilder(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 50),
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
