import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/saved_outfits_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/providers/builder_provider.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/widgets/picker_sheet.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/widgets/carousel_section.dart';
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
  SavedOutfitsProvider? _savedProvider;
  CatalogProvider? _catalogProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savedProvider = Provider.of<SavedOutfitsProvider>(context, listen: false);
      _savedProvider!.addListener(_onSavedChanged);
      _catalogProvider = Provider.of<CatalogProvider>(context, listen: false);
      _catalogProvider!.addListener(_onClothesChanged);
      _tryInit();
    });
  }

  @override
  void dispose() {
    _savedProvider?.removeListener(_onSavedChanged);
    _catalogProvider?.removeListener(_onClothesChanged);
    super.dispose();
  }

  void _tryInit() {
    if (!mounted) return;
    final builder = Provider.of<BuilderProvider>(context, listen: false);
    if (builder.initialized) return;
    if (_catalogProvider!.allClothes.isEmpty) return;

    final saved = Provider.of<SavedOutfitsProvider>(context, listen: false);
    final pending = saved.pendingLoad;
    if (pending != null) {
      builder.loadFromSaved(pending, _catalogProvider!);
      saved.clearPendingLoad();
    } else {
      builder.randomizeOutfit(_catalogProvider!);
    }
  }

  void _onClothesChanged() {
    if (!mounted) return;
    _tryInit();
  }

  void _onSavedChanged() {
    if (!mounted) return;
    final saved = Provider.of<SavedOutfitsProvider>(context, listen: false);
    final pending = saved.pendingLoad;
    if (pending == null) return;
    saved.clearPendingLoad();

    final builder = Provider.of<BuilderProvider>(context, listen: false);
    builder.loadFromSaved(pending, _catalogProvider!);
  }

  Future<void> _saveOutfit() async {
    final builder = Provider.of<BuilderProvider>(context, listen: false);
    final saved = Provider.of<SavedOutfitsProvider>(context, listen: false);

    final missing = <String>[];
    if (builder.selectedInner == null) missing.add('Inner');
    if (builder.selectedBottoms == null) missing.add('Bottoms');
    if (builder.selectedShoes == null) missing.add('Shoes');
    if (builder.twoLayerMode && builder.selectedOuter == null) missing.add('Outer');

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing: ${missing.join(', ')}')),
      );
      return;
    }

    final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
    if (userId == null) return;

    if (saved.isMutating) return;

    final newFavorite = FavoriteOutfit(
      id: const Uuid().v4(),
      userId: userId,
      headwearId: builder.selectedHeadwear?.id,
      outerId: builder.twoLayerMode ? builder.selectedOuter!.id : null,
      innerId: builder.selectedInner!.id,
      pantsId: builder.selectedBottoms!.id,
      shoesId: builder.selectedShoes!.id,
      savedAt: DateTime.now(),
    );

    try {
      await saved.addSavedOutfit(newFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit saved! View in Profile.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save outfit')),
        );
      }
    }
  }

  void _showItemPicker(BuildContext context) {
    final builder = Provider.of<BuilderProvider>(context, listen: false);
    final categories = ['Outer', 'Inner', 'Bottoms', 'Shoes'];
    if (!builder.twoLayerMode) categories.remove('Outer');
    if (builder.headwearEnabled) categories.insert(0, 'Headwear');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => PickerSheet(
        categories: categories,
        onPicked: (category, item) {
          Navigator.pop(ctx);
          builder.selectItem(category, item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<CatalogProvider, BuilderProvider>(
        builder: (context, clothesProvider, builder, child) {
          final saved = context.watch<SavedOutfitsProvider>();
          final hasOuter = clothesProvider.getOuter().isNotEmpty;
          final hasInner = clothesProvider.getInner().isNotEmpty;
          final hasBottoms = clothesProvider.getBottoms().isNotEmpty;
          final hasShoes = clothesProvider.getShoes().isNotEmpty;
          final canGenerate = hasInner && hasBottoms && hasShoes && (!builder.twoLayerMode || hasOuter);

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
                                      if (builder.headwearEnabled)
                                        CarouselSection(
                                          items: clothesProvider.getHeadwear(),
                                          selectedItem: builder.selectedHeadwear,
                                          onChanged: (item) => builder.selectItem('Headwear', item),
                                          locked: builder.headwearLocked,
                                          onLockToggle: () => builder.toggleLock('headwear'),
                                          height: 90,
                                          viewportFraction: 0.6,
                                        ),
                                      if (builder.twoLayerMode)
                                        CarouselSection(
                                          items: clothesProvider.getOuter(),
                                          selectedItem: builder.selectedOuter,
                                          onChanged: (item) => builder.selectItem('Outer', item),
                                          locked: builder.outerLocked,
                                          onLockToggle: () => builder.toggleLock('outer'),
                                          height: 160,
                                          viewportFraction: 1.0,
                                        ),
                                      CarouselSection(
                                        items: clothesProvider.getInner(),
                                        selectedItem: builder.selectedInner,
                                        onChanged: (item) => builder.selectItem('Inner', item),
                                        locked: builder.innerLocked,
                                        onLockToggle: () => builder.toggleLock('inner'),
                                        height: 160,
                                        viewportFraction: 0.8,
                                      ),
                                      CarouselSection(
                                        items: clothesProvider.getBottoms(),
                                        selectedItem: builder.selectedBottoms,
                                        onChanged: (item) => builder.selectItem('Bottoms', item),
                                        locked: builder.bottomsLocked,
                                        onLockToggle: () => builder.toggleLock('bottoms'),
                                        height: 160,
                                        viewportFraction: 1.0,
                                      ),
                                      CarouselSection(
                                        items: clothesProvider.getShoes(),
                                        selectedItem: builder.selectedShoes,
                                        onChanged: (item) => builder.selectItem('Shoes', item),
                                        locked: builder.shoesLocked,
                                        onLockToggle: () => builder.toggleLock('shoes'),
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
                                      if (builder.headwearEnabled && !clothesProvider.getHeadwear().isNotEmpty)
                                        const Text('\u2022 Add at least one Headwear'),
                                      if (builder.twoLayerMode && !hasOuter) const Text('\u2022 Add at least one Outer Top'),
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
                        onPressed: () => builder.randomizeOutfit(clothesProvider),
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        icon: Icons.favorite_border,
                        onPressed: saved.isMutating ? null : _saveOutfit,
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        text: builder.twoLayerMode ? '2' : '1',
                        onPressed: () {
                          builder.toggleLayers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(builder.twoLayerMode
                                  ? 'Two-layer mode on'
                                  : 'Two-layer mode off'),
                              duration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      AppFloatingActionButton(
                        text: builder.headwearEnabled ? 'H' : null,
                        icon: builder.headwearEnabled ? null : Icons.person_outline,
                        onPressed: () {
                          builder.toggleHeadwear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(builder.headwearEnabled
                                  ? 'Headwear shown'
                                  : 'Headwear hidden'),
                              duration: const Duration(milliseconds: 500),
                            ),
                          );
                        },
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
