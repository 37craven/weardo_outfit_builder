import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final tabCount = 3;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 71 + bottomPad,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 1),
            left: BorderSide(color: Colors.black, width: 1),
            right: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / tabCount;

              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: navigationShell.currentIndex * tabWidth,
                    top: 0,
                    width: tabWidth,
                    height: 71,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: navigationShell.currentIndex < tabCount - 1
                            ? const Border(
                                right: BorderSide(color: Colors.white, width: 1),
                              )
                            : null,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(tabCount, (i) {
                      return _NavItem(
                        icon: [Icons.book, Icons.checkroom, Icons.person][i],
                        label: ['Catalog', 'Builder', 'Profile'][i],
                        selected: navigationShell.currentIndex == i,
                        onTap: () => navigationShell.goBranch(i),
                        showRightBorder: i < tabCount - 1,
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showRightBorder;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showRightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: showRightBorder
                ? const Border(right: BorderSide(color: Colors.black, width: 1))
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.black),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
