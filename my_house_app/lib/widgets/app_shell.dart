import 'package:flutter/material.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/widgets/app_bottom_nav.dart';
import 'package:my_house_app/widgets/app_drawer.dart';

class AppShell extends StatelessWidget {
  final String currentRoute;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showDrawer;
  final bool showBottomNav;
  final EdgeInsetsGeometry bodyPadding;

  const AppShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.icon,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showDrawer = true,
    this.showBottomNav = true,
    this.bodyPadding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width >= 900 ? 28.0 : 16.0;

    return Scaffold(
      extendBody: showBottomNav,
      backgroundColor: AppColors.scaffoldBg,
      drawer: showDrawer ? const AppDrawer() : null,
      appBar: AppBar(
        toolbarHeight: subtitle == null ? 78 : 86,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.82),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: actions,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.scaffoldBg, Color(0xFFEAF3FB)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: 60,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  0,
                ).add(bodyPadding),
                child: body,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar:
          showBottomNav ? AppBottomNav(currentRoute: currentRoute) : null,
    );
  }
}
