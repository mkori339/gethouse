import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/navigation_service.dart';

class AuthGate extends StatefulWidget {
  final Widget child;
  /// route to redirect after successful login (optional)
  final String? redirectRoute;
  const AuthGate({super.key, required this.child, this.redirectRoute});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _check;

  @override
  void initState() {
    super.initState();
    // prefer cookie-on-web if you configured it; set false if you only use token-based
    _check = AuthService.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _check,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // while checking show a loader
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final ok = snap.data ?? false;
        if (!ok) {
          // user not authenticated -> redirect to /signin with a redirect query parameter
          // we use addPostFrameCallback to avoid calling navigator during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final redirect = widget.redirectRoute ?? ModalRoute.of(context)?.settings.name ?? '/';
            // pass as query param so SigninScreen can read it
            NavigationService.navigateToReplacement('/signin?redirect=${Uri.encodeComponent(redirect)}');
          });
          // return empty widget while navigation happens
          return const SizedBox.shrink();
        }

        // user is authenticated -> show protected child
        return widget.child;
      },
    );
  }
}
