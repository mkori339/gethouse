import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../utils/navigation_service.dart';
import '../widgets/app_shell.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // NOTE: Password confirmation check removed as requested.

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp = await ApiService.postJson('/api/register', {
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'phone': _phoneCtrl.text.trim(),
      });

      String? token;
      String? role;
      String? userId;
      if (resp is Map) {
        token = resp['token']?.toString() ??
            (resp['data'] is Map ? resp['data']['token']?.toString() : null) ??
            (resp['api_token']?.toString()) ??
            (resp['user'] is Map
                ? resp['user']['api_token']?.toString()
                : null);
        role = (resp['user'] is Map) ? resp['user']['role']?.toString() : null;
        userId = (resp['user'] is Map) ? resp['user']['id']?.toString() : null;
      }
      if (token != null && token.isNotEmpty) {
        await AuthService.saveToken(token);
      }
      if (role != null && role.isNotEmpty) {
        await AuthService.saveRole(role);
      }
      if (userId != null && userId.isNotEmpty) {
        await AuthService.saveUserId(userId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 1. Attractive Styling
            content: Row(
              children: [
                const Icon(
                  Iconsax
                      .copy_success2, // Using Iconsax for a modern, clear icon
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Registration successful!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600, // Make the text stand out
                    ),
                  ),
                ),
              ],
            ),

            // 2. Color and Elevation
            backgroundColor: const Color(
                0xFFF97316), // A slightly deeper, modern Orange/Amber
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16), // Creates a narrow, non-wide 'dive'
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

            // 3. Rounded Shape
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16), // Increased border radius
            ),

            // 4. Subtle, Non-Wide Animation
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            NavigationService.navigateToReplacement('/user-dashboard');
          }
        });
      }
    } on ApiException catch (e) {
      String message = 'Registration failed';
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
      if (mounted) {
        setState(() {
          _error = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
    return AppShell(
      currentRoute: '/signup',
      title: 'Create Account',
      subtitle: 'Join the mobile-first property app',
      icon: Iconsax.user_add,
      body: SizedBox.expand(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                          color: AppColors.primary.withOpacity(0.16),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create your account and start listing fast.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register once, then manage homes, profiles, and agent requests from a phone-friendly layout.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.84),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header (simplified)
                          const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Error message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.red[200]!, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[700], size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Registration Form
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _usernameCtrl,
                                  labelText: 'Username',
                                  icon: Icons.person_outline,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Username is required'
                                      : null,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _emailCtrl,
                                  labelText: 'Email Address',
                                  icon: Icons.email_outlined,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Email is required';
                                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v))
                                      return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _phoneCtrl,
                                  labelText: 'Phone Number',
                                  icon: Icons.phone_outlined,
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Phone number is required';
                                    if (!v.startsWith('255') ||
                                        v.length != 12 ||
                                        int.tryParse(v.substring(3)) == null)
                                      return 'Phone must start with 255 and be 12 digits (e.g., 255712345678)';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _passwordCtrl,
                                  labelText: 'Password',
                                  icon: Icons.lock_outline,
                                  isPassword: true,
                                  obscureText: _obscurePassword,
                                  onSuffixPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  validator: (v) => (v == null || v.length < 8)
                                      ? 'Password must be at least 8 characters'
                                      : null,
                                ),
                                const SizedBox(height: 24),

                                // Submit button
                                _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF1976D2)),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 3,
                                        ),
                                        child: const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign in link
                          _buildFooterLink(
                            'Already have an account?',
                            'Sign in',
                            () => NavigationService.navigateToReplacement(
                                '/signin'),
                          ),
                        ],
                      ),
                    ),
                  ),
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
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey[500],
                ),
                onPressed: onSuffixPressed,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.transparent,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        floatingLabelStyle: const TextStyle(color: Color(0xFF1976D2)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 2.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[700]!, width: 2.0),
        ),
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
