import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/models/outfit_model.dart';

class SavedOutfitsGrid extends StatelessWidget {
  final List<FavoriteOutfit> outfits;
  final Widget Function(FavoriteOutfit outfit, double cardWidth) cardBuilder;

  const SavedOutfitsGrid({
    super.key,
    required this.outfits,
    required this.cardBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final crossAxisCount = (constraints.maxWidth / 180).floor().clamp(2, 4);
        final cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        double cardHeight(FavoriteOutfit f) {
          return cardWidth + (f.headwearId != null ? cardWidth * 0.25 : 0) + 2;
        }

        final columns = List.generate(crossAxisCount, (_) => <Widget>[]);
        final heights = List.filled(crossAxisCount, 0.0);

        for (var i = 0; i < outfits.length; i++) {
          final h = cardHeight(outfits[i]);
          final colIndex = heights.indexOf(heights.reduce((a, b) => a < b ? a : b));
          final card = Padding(
            padding: EdgeInsets.only(top: columns[colIndex].isEmpty ? 0 : spacing),
            child: cardBuilder(outfits[i], cardWidth),
          );
          columns[colIndex].add(card);
          heights[colIndex] += h + spacing;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(crossAxisCount, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? spacing : 0),
                child: Column(children: columns[i]),
              ),
            );
          }),
        );
      },
    );
  }
}
