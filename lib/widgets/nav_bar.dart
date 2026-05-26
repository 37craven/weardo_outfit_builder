import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        height: 71,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black, width: 1),
            left: BorderSide(color: Colors.black, width: 1),
            right: BorderSide(color: Colors.black, width: 1),
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.book,
                label: 'Catalog',
                selected: navigationShell.currentIndex == 0,
                onTap: () => navigationShell.goBranch(0),
                showRightBorder: true,
              ),
              _NavItem(
                icon: Icons.checkroom,
                label: 'Builder',
                selected: navigationShell.currentIndex == 1,
                onTap: () => navigationShell.goBranch(1),
                showRightBorder: true,
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                selected: navigationShell.currentIndex == 2,
                onTap: () => navigationShell.goBranch(2),
              ),
            ],
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
            color: selected ? Colors.black : Colors.white,
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
