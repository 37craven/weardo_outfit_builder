import 'package:flutter/material.dart';

class AppConstants {
  // Sizing for outfit generation
  static const double referenceInches = 30.0;
  static const double referencePixels = 200.0;

  // Category strings
  static const String categoryOuter = 'Outer';
  static const String categoryInner = 'Inner';
  static const String categoryPants = 'Pants';
  static const String categoryShoes = 'Shoes';

  static const List<String> allCategories = [categoryOuter, categoryInner, categoryPants, categoryShoes];

  // Supabase table names
  static const String collectionUsers = 'users';
  static const String collectionClothes = 'clothes';
  static const String collectionFavorites = 'favorites';

  // Shared preferences keys (for future use)
  static const String prefUserId = 'userId';
  static const String prefUserEmail = 'userEmail';

  // Default error messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoImage = 'Please select an image.';
  static const String errorNoCategory = 'Please select a category.';
  static const String errorIncompleteOutfit = 'Complete outfit required (inner, pants, shoes).';

  // Theme colors
  static const Color primaryColor = Colors.purple;
  static const Color accentColor = Colors.amber;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
}