// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:my_house_app/services/auth_service.dart';
import 'package:my_house_app/utils/navigation_service.dart';

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
    return Drawer(
      child: Container(
        
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1976D2), Color(0xFF2575FC)],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: const Color(0xFF1976D2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apps,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gethouse now!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role == null
                        ? 'Explore app features'
                        : 'Logged in as $role',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Common Pages
            _buildDrawerItem(
              context: context,
              icon: Icons.home_filled,
              title: 'Home',
              route: '/home',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.person,
              title: 'Agents',
              route: '/agents',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.info_outline_rounded,
              title: 'About',
              route: '/about',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: 'My Dashboard',
              route: '/user-dashboard',
            ),

            // Show Login & Signup if not logged in
            if (role == null) ...[
              _buildDrawerItem(
                context: context,
                icon: Icons.login,
                title: 'Login',
                route: '/signin',
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.person_add_alt_1,
                title: 'Sign Up',
                route: '/signup',
              ),
            ],

            // Customer only
            if (role == "customer") ...[
              const Divider(color: Colors.white24, thickness: 1, indent: 20, endIndent: 20),
              _buildDrawerItem(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                route: '/logout',
              ),
            ],

            // Admin only
            if (role == "admin") ...[
              const Divider(color: Colors.white24, thickness: 1, indent: 20, endIndent: 20),
              _buildDrawerItem(
                context: context,
                icon: Icons.admin_panel_settings,
                title: 'Admin Dashboard',
                route: '/admin-dashboard',
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.group,
                title: 'Manage Users',
                route: '/admin/manage-users',
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.business,
                title: 'Manage Agents',
                route: '/admin/unpaid-agents',
              ),
              _buildDrawerItem(
                context: context,
                icon: Icons.logout,
                title: 'Logout',
                route: '/logout',
              ),
            ],

            // Always show Help
             const Divider(color: Colors.white24, thickness: 2, indent: 20, endIndent: 20),
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.help_center,
            //   title: 'Help & Support',
            //   route: '/about_programmer',
            // ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'App Version 1.2.0',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.white.withOpacity(0.6),
          size: 16,
        ),
        onTap: () async {
          Navigator.pop(context);

          if (route == '/logout') {
            await AuthService.clearAuth();
            NavigationService.navigateTo('/signin');
          } else {
            NavigationService.navigateTo(route);
          }
        },
      ),
    );
  }
}
