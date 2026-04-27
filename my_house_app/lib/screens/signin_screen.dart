// lib/screens/signin_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/navigation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/widgets/app_shell.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// Try to extract redirect param from current route or browser URL
  String? _getRedirectFromContext(BuildContext context) {
    // 1) try ModalRoute name (may include query)
    final routeName = ModalRoute.of(context)?.settings.name;
    if (routeName != null && routeName.contains('?')) {
      try {
        final uri = Uri.parse(routeName);
        final r = uri.queryParameters['redirect'];
        if (r != null && r.isNotEmpty) return r;
      } catch (_) {}
    }

    // 2) try browser URL (works on web)
    try {
      final webRedirect = Uri.base.queryParameters['redirect'];
      if (webRedirect != null && webRedirect.isNotEmpty) return webRedirect;
    } catch (_) {}

    return null;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await ApiService.postJson('/api/login', {
        'email': _emailCtrl.text.trim(),
        'password': _passCtrl.text,
      });

      // resp is dynamic (Map or List). Try many common token locations:
      String? token;
      String? role;
      String? userId;
      if (resp is Map) {
        token = resp['token']?.toString() ?? null;
        role = (resp['user'] is Map)
            ? (resp['user']['role']?.toString() ?? 'null')
            : 'null';
        userId = (resp['user'] is Map)
            ? (resp['user']['id']?.toString() ?? null)
            : null;
      }

      if (token != null &&
          token.isNotEmpty &&
          role != null &&
          role.isNotEmpty) {
        // Save token using AuthService (SharedPreferences)
        await AuthService.saveToken(token);
        await AuthService.saveRole(role);
        if (userId != null && userId.isNotEmpty) {
          await AuthService.saveUserId(userId);
        }
      }

      // On success: go to redirect route if provided, otherwise home
      if (mounted) {
        final redirect = _getRedirectFromContext(context);
        if (redirect != null && redirect.isNotEmpty) {
          final decoded = Uri.decodeComponent(redirect);
          // print(decoded);
          if ((decoded == ('/user-dashboard') ||
              decoded == ('/admin-dashboard'))) {
            // print(decoded);
            // print(resp['role']?.toString());
            var userRole = role;
            if (userRole == "admin") {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NavigationService.navigateToReplacement('/admin-dashboard');
              });
            } else {
              // Check user role and navigate accordingly
              WidgetsBinding.instance.addPostFrameCallback((_) {
                NavigationService.navigateToReplacement(decoded);
              });
            }
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateToReplacement('/home');
          });
        }
      }
    } on ApiException catch (e) {
      String message = 'Login failed';
      if (e.body is Map) {
        if (e.body['message'] != null) {
          message = e.body['message'].toString();
        } else if (e.body['errors'] is Map) {
          final errors = e.body['errors'] as Map;
          final first =
              errors.entries.isNotEmpty ? errors.entries.first.value : null;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          } else {
            message = errors.toString();
          }
        } else {
          message = e.body.toString();
        }
      } else {
        message = e.body?.toString() ?? e.toString();
      }

      setState(() {
        _error = message;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return AppShell(
      currentRoute: '/signin',
      title: 'Sign In',
      subtitle: 'Continue with your saved account',
      icon: Iconsax.login,
      body: SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 40.0 : 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your home search starts where you left it.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use your account to save searches, manage posts, and move through the app with mobile-first navigation.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.84),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04),
                  Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header with animation
                            const Text(
                              'Welcome Back 👋',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D3748),
                              ),
                              textAlign: TextAlign.center,
                            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                            const SizedBox(height: 8),

                            Text(
                              'Sign in to your account to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                            const SizedBox(height: 32),

                            // Error message with animation
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.red[200]!, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Iconsax.warning_2,
                                        color: Colors.red[700], size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.close,
                                          color: Colors.red[700], size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _error = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(delay: 500.ms, duration: 600.ms)
                                  .shake(duration: 400.ms),

                            // Login Form
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    labelText: 'Email Address',
                                    icon: Iconsax.sms,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Email is required';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  )
                                      .animate()
                                      .fadeIn(delay: 600.ms, duration: 600.ms)
                                      .slide(begin: const Offset(0.2, 0)),

                                  const SizedBox(height: 20),

                                  _buildTextField(
                                    controller: _passCtrl,
                                    labelText: 'Password',
                                    icon: Iconsax.lock_1,
                                    isPassword: true,
                                    obscureText: _obscurePassword,
                                    onSuffixPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Password is required'
                                        : null,
                                  )
                                      .animate()
                                      .fadeIn(delay: 700.ms, duration: 600.ms)
                                      .slide(begin: const Offset(0.2, 0)),

                                  const SizedBox(height: 20),

                                  // Submit button with loading state
                                  _loading
                                      ? SizedBox(
                                          height: 56,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      const Color(0xFF1976D2)),
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _login,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1976D2),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 18, horizontal: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 5,
                                            shadowColor: const Color(0xFF1976D2)
                                                .withOpacity(0.4),
                                          ),
                                          child: SizedBox(
                                            child: const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                          .animate()
                                          .fadeIn(
                                              delay: 900.ms, duration: 600.ms)
                                          .scale(begin: const Offset(0.9, 0.9)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey[300],
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            )
                                .animate()
                                .fadeIn(delay: 1000.ms, duration: 600.ms),

                            const SizedBox(height: 20),

                            // Sign up link
                            _buildFooterLink(
                              'Don\'t have an account?',
                              'Sign up',
                              () => NavigationService.navigateToReplacement(
                                  '/signup'),
                            )
                                .animate()
                                .fadeIn(delay: 1100.ms, duration: 600.ms),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(delay: 500.ms, duration: 600.ms)
                      .then(delay: 100.ms)
                      .shake(duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build a consistent text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onSuffixPressed,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Iconsax.eye_slash : Iconsax.eye,
                  color: Colors.grey[500],
                ),
                onPressed: onSuffixPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }

  /// Helper method for a footer link
  Widget _buildFooterLink(String prefix, String linkText, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prefix, style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: onTap,
          child: Text(
            linkText,
            style: const TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
