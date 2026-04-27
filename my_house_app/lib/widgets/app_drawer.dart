// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:my_house_app/services/auth_service.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/utils/navigation_service.dart';
import 'package:my_house_app/widgets/app_navigation.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final value = await AuthService.getRole();
    setState(() {
      role = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryItems = primaryNavigationForRole(role);
    final secondaryItems = drawerSecondaryNavigationForRole(role);

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Iconsax.house,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Gethouse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role == null
                          ? 'Mobile-first property browsing'
                          : 'Signed in as $role',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  children: [
                    const _DrawerSectionLabel('Navigate'),
                    for (final item in primaryItems)
                      _buildDrawerItem(
                        context: context,
                        icon: item.icon,
                        title: item.label,
                        route: item.route,
                      ),
                    if (secondaryItems.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const _DrawerSectionLabel('More'),
                      for (final item in secondaryItems)
                        _buildDrawerItem(
                          context: context,
                          icon: item.icon,
                          title: item.label,
                          route: item.route,
                        ),
                    ],
                    if (role != null) ...[
                      const SizedBox(height: 14),
                      const _DrawerSectionLabel('Account'),
                      _buildDrawerItem(
                        context: context,
                        icon: Iconsax.logout,
                        title: 'Logout',
                        route: '/logout',
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.mobile,
                      size: 16,
                      color: Colors.white.withOpacity(0.72),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Version 2.0 mobile shell',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          color: Colors.white.withOpacity(0.62),
          size: 18,
        ),
        onTap: () async {
          Navigator.pop(context);

          if (route == '/logout') {
            await AuthService.clearAuth();
            NavigationService.navigateToReplacement('/signin');
          } else {
            NavigationService.navigateTo(route);
          }
        },
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String title;

  const _DrawerSectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withOpacity(0.62),
          letterSpacing: 1.1,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
