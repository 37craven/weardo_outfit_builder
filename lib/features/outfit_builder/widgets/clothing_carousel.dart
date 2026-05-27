import 'package:flutter/material.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';

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
