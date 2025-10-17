// lib/utils/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<dynamic>? navigateTo(String routeName) {
    return navigatorKey.currentState?.pushNamed(routeName);
  }

  static Future<dynamic>? navigateToReplacement(String routeName) {
    return navigatorKey.currentState?.pushReplacementNamed(routeName);
  }

  static void pop([dynamic result]) {
    return navigatorKey.currentState?.pop(result);
  }

  
}

