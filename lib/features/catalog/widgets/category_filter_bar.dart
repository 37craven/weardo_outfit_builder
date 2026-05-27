import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black, width: 1),
          right: BorderSide(color: Colors.black, width: 1),
          top: BorderSide(color: Colors.black, width: 1),
          bottom: BorderSide(color: Colors.black, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(categories.length, (i) {
            final selected = selectedCategory == categories[i];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCategoryChanged(categories[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: selected ? Colors.black : Colors.white,
                  border: i < categories.length - 1
                      ? const Border(right: BorderSide(color: Colors.black, width: 1))
                      : null,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                height: 48,
                alignment: Alignment.center,
                child: Text(
                  categories[i] == 'all'
                      ? 'All'
                      : categories[i][0].toUpperCase() + categories[i].substring(1),
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
