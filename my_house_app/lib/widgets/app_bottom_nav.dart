import 'package:flutter/material.dart';
import 'package:my_house_app/services/auth_service.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/utils/navigation_service.dart';
import 'package:my_house_app/widgets/app_navigation.dart';

class AppBottomNav extends StatefulWidget {
  final String currentRoute;

  const AppBottomNav({super.key, required this.currentRoute});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getRole();
    if (!mounted) {
      return;
    }
    setState(() {
      _role = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = primaryNavigationForRole(_role);
    final selectedIndex = items.indexWhere(
      (item) => item.matchesRoute(widget.currentRoute),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withOpacity(0.12),
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            animationDuration: const Duration(milliseconds: 450),
            elevation: 0,
            onDestinationSelected: (index) {
              final route = items[index].route;
              if (items[index].matchesRoute(widget.currentRoute)) {
                return;
              }
              NavigationService.navigateToReplacement(route);
            },
            destinations: [
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
