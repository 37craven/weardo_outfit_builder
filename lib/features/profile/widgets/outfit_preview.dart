import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

class OutfitPreview extends StatelessWidget {
  final ClothingItem? outer;
  final ClothingItem? inner;
  final ClothingItem? bottoms;
  final ClothingItem? shoes;

  const OutfitPreview({
    super.key,
    this.outer,
    this.inner,
    this.bottoms,
    this.shoes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (outer == null && inner == null) {
                return const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey));
              }
              final offset = outer != null && inner != null ? constraints.maxWidth * 0.08 : 0.0;
              return Padding(
                padding: const EdgeInsets.all(4),
                child: Stack(
                  children: [
                    if (outer != null)
                      Positioned(
                        left: 0, top: 0, bottom: 0, right: offset,
                        child: Image.network(outer!.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                    if (inner != null)
                      Positioned(
                        left: offset, top: 0, bottom: 0, right: 0,
                        child: Image.network(inner!.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: bottoms != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(bottoms!.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                )
              : const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey)),
        ),
        Expanded(
          flex: 3,
          child: shoes != null
              ? Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(shoes!.imageUrl, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                )
              : const Center(child: Icon(Icons.checkroom, size: 30, color: Colors.grey)),
        ),
      ],
    );
  }
}
