import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:weardo_outfit_builder/features/outfit_builder/widgets/clothing_carousel.dart';

class CarouselSection extends StatelessWidget {
  final List<ClothingItem> items;
  final ClothingItem? selectedItem;
  final ValueChanged<ClothingItem> onChanged;
  final bool locked;
  final VoidCallback onLockToggle;
  final double height;
  final double viewportFraction;

  const CarouselSection({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    required this.locked,
    required this.onLockToggle,
    required this.height,
    this.viewportFraction = 0.55,
  });

  @override
  Widget build(BuildContext context) {
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
}
