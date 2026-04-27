import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AppNavItem {
  final String label;
  final String route;
  final IconData icon;
  final List<String> aliases;

  const AppNavItem({
    required this.label,
    required this.route,
    required this.icon,
    this.aliases = const [],
  });

  bool matchesRoute(String currentRoute) {
    if (currentRoute == route) {
      return true;
    }
    return aliases.any(currentRoute.startsWith);
  }
}

List<AppNavItem> primaryNavigationForRole(String? role) {
  if (role == 'admin') {
    return const [
      AppNavItem(
        label: 'Home',
        route: '/home',
        icon: Iconsax.home_2,
      ),
      AppNavItem(
        label: 'Admin',
        route: '/admin-dashboard',
        icon: Iconsax.status_up,
        aliases: ['/admin-dashboard'],
      ),
      AppNavItem(
        label: 'Users',
        route: '/admin/manage-users',
        icon: Iconsax.people,
        aliases: ['/admin/manage-users', '/admin/edit-user'],
      ),
      AppNavItem(
        label: 'Reports',
        route: '/admin/reports',
        icon: Iconsax.warning_2,
        aliases: [
          '/admin/reports',
          '/admin/unpaid-posts',
          '/admin/unpaid-agents'
        ],
      ),
    ];
  }

  if (role == 'customer') {
    return const [
      AppNavItem(
        label: 'Home',
        route: '/home',
        icon: Iconsax.home_2,
      ),
      AppNavItem(
        label: 'Agents',
        route: '/agents',
        icon: Iconsax.profile_2user,
      ),
      AppNavItem(
        label: 'Dashboard',
        route: '/user-dashboard',
        icon: Iconsax.element_4,
      ),
      AppNavItem(
        label: 'Profile',
        route: '/view-profile',
        icon: Iconsax.user_square,
        aliases: ['/view-profile', '/edit-profile', '/my-posts'],
      ),
    ];
  }

  return const [
    AppNavItem(
      label: 'Home',
      route: '/home',
      icon: Iconsax.home_2,
    ),
    AppNavItem(
      label: 'Agents',
      route: '/agents',
      icon: Iconsax.profile_2user,
    ),
    AppNavItem(
      label: 'Sign In',
      route: '/signin',
      icon: Iconsax.login,
    ),
    AppNavItem(
      label: 'Join',
      route: '/signup',
      icon: Iconsax.user_add,
    ),
  ];
}

List<AppNavItem> drawerSecondaryNavigationForRole(String? role) {
  if (role == 'admin') {
    return const [
      AppNavItem(
        label: 'Pending Posts',
        route: '/admin/unpaid-posts',
        icon: Iconsax.receipt_item,
      ),
      AppNavItem(
        label: 'Pending Agents',
        route: '/admin/unpaid-agents',
        icon: Iconsax.profile_tick,
      ),
      AppNavItem(
        label: 'About',
        route: '/about',
        icon: Iconsax.info_circle,
      ),
    ];
  }

  if (role == 'customer') {
    return const [
      AppNavItem(
        label: 'Post House',
        route: '/post-house',
        icon: Iconsax.add_square,
      ),
      AppNavItem(
        label: 'Become Agent',
        route: '/agent-request',
        icon: Iconsax.user_octagon,
      ),
      AppNavItem(
        label: 'About',
        route: '/about',
        icon: Iconsax.info_circle,
      ),
    ];
  }

  return const [
    AppNavItem(
      label: 'About',
      route: '/about',
      icon: Iconsax.info_circle,
    ),
  ];
}
