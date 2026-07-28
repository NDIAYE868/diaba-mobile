import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/cart/providers/cart_provider.dart';
import '../../core/constants/app_colors.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Boutique', path: '/'),
    _TabItem(icon: Icons.favorite_outline, activeIcon: Icons.favorite, label: 'Favoris', path: '/favorites'),
    _TabItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag, label: 'Panier', path: '/cart'),
    _TabItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Commandes', path: '/orders'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (i == 0) {
        if (location == '/') return 0;
      } else {
        if (location.startsWith(_tabs[i].path)) return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).totalItems;
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final tab = entry.value;
          final isActive = i == currentIndex;

          // Badge sur le panier
          if (i == 2 && cartCount > 0) {
            return BottomNavigationBarItem(
              icon: Badge(
                label: Text(
                  cartCount > 99 ? '99+' : '$cartCount',
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: AppColors.secondary,
                child: Icon(isActive ? tab.activeIcon : tab.icon),
              ),
              label: tab.label,
            );
          }

          return BottomNavigationBarItem(
            icon: Icon(isActive ? tab.activeIcon : tab.icon),
            label: tab.label,
          );
        }).toList(),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
