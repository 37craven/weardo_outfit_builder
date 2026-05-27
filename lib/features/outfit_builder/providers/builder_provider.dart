import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';

class BuilderProvider extends ChangeNotifier {
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

  bool twoLayerMode = false;
  bool headwearEnabled = false;
  bool initialized = false;

  void loadFromSaved(FavoriteOutfit outfit, CatalogProvider provider) {
    ClothingItem? find(String id) {
      try {
        return provider.allClothes.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    }

    selectedHeadwear = outfit.headwearId != null ? find(outfit.headwearId!) : null;
    selectedOuter = outfit.outerId != null ? find(outfit.outerId!) : null;
    selectedInner = find(outfit.innerId);
    selectedBottoms = find(outfit.pantsId);
    selectedShoes = find(outfit.shoesId);
    twoLayerMode = outfit.outerId != null;
    headwearEnabled = outfit.headwearId != null;
    initialized = true;
    notifyListeners();
  }

  void randomizeOutfit(CatalogProvider provider) {
    final outer = provider.getOuter();
    final inner = provider.getInner();
    final pants = provider.getBottoms();
    final shoes = provider.getShoes();
    final headwear = provider.getHeadwear();

    if (headwearEnabled && !headwearLocked && headwear.isNotEmpty) {
      selectedHeadwear = (headwear..shuffle()).first;
    }
    if (twoLayerMode && !outerLocked && outer.isNotEmpty) {
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
    notifyListeners();
  }

  void toggleLock(String slot) {
    switch (slot) {
      case 'headwear': headwearLocked = !headwearLocked; break;
      case 'outer': outerLocked = !outerLocked; break;
      case 'inner': innerLocked = !innerLocked; break;
      case 'bottoms': bottomsLocked = !bottomsLocked; break;
      case 'shoes': shoesLocked = !shoesLocked; break;
    }
    notifyListeners();
  }

  void toggleLayers() {
    twoLayerMode = !twoLayerMode;
    notifyListeners();
  }

  void toggleHeadwear() {
    headwearEnabled = !headwearEnabled;
    notifyListeners();
  }

  void selectItem(String slot, ClothingItem item) {
    switch (slot) {
      case 'Headwear': selectedHeadwear = item; break;
      case 'Outer': selectedOuter = item; break;
      case 'Inner': selectedInner = item; break;
      case 'Bottoms': selectedBottoms = item; break;
      case 'Shoes': selectedShoes = item; break;
    }
    notifyListeners();
  }
}
