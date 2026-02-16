import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/screens/unauthorized_page.dart';
import 'package:my_house_app/services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/navigation_service.dart';

class AdminEditUserScreen extends StatefulWidget {
  final String? userId; // Allow nullable userId for main.dart compatibility
  const AdminEditUserScreen({super.key, this.userId});

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String? _role;
  bool _isBlocked = false;
  String? _userId;
  bool _loading = true;
  String? _error;
  String? _authRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt',
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _checkRoleAndLoadUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId == null) {
      _extractUserId();
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndLoadUser() async {
    _authRole = await AuthService.getRole();
    if (_authRole == 'admin') {
      _extractUserId();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  void _extractUserId() {
    String? newUserId = widget.userId;
    if (newUserId == null) {
      final routeSettings = ModalRoute.of(context)?.settings;
      if (routeSettings != null && routeSettings.name != null) {
        final uri = Uri.parse(routeSettings.name!);
        newUserId = uri.queryParameters['userId'];
      }
    }

    if (newUserId != null && newUserId != _userId) {
      setState(() {
        _userId = newUserId;
      });
      _loadUser();
    } else if (newUserId == null) {
      setState(() {
        _error = 'Missing user ID';
        _loading = false;
      });
    }
  }

  Future<void> _loadUser() async {
    if (_userId == null) {
      setState(() {
        _error = 'Missing user ID';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedUserId = _hashIds.decode(_userId!)[0];
      final resp = await ApiService.get('/api/user/view_profile/$decodedUserId');
      if (resp is Map) {
        setState(() {
          _username.text = resp['username']?.toString() ?? resp['name']?.toString() ?? '';
          _email.text = resp['email']?.toString() ?? '';
          _phone.text = resp['phone']?.toString() ?? '';
          _role = resp['role']?.toString() ?? 'customer';
          _isBlocked = (resp['is_blocked'] == 1 || resp['is_blocked'] == true);
        });
      } else {
        throw Exception('Invalid user data');
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load user';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
            )..forward(),
            curve: Curves.easeInOut,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Save Changes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to save changes to this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedUserId = _hashIds.decode(_userId!)[0];
      final fields = {
        'username': _username.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'role': _role,
        'is_blocked': _isBlocked ? 1 : 0,
      };

      if (_password.text.trim().isNotEmpty) {
        fields['password'] = _password.text.trim();
      }

      await ApiService.postJson('/api/user/update_profile/$decodedUserId', fields);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User updated successfully'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        NavigationService.navigateToReplacement('/admin/manage-users');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.body?.toString() ?? 'Update failed';
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

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
            )..forward(),
            curve: Curves.easeInOut,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete User',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedUserId = _hashIds.decode(_userId!)[0];
      await ApiService.delete('/api/admin/user/delete/$decodedUserId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User deleted successfully'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        NavigationService.navigateToReplacement('/admin/manage-users');
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.body?.toString() ?? 'Deletion failed';
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

  Future<void> _clearForm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 300),
            )..forward(),
            curve: Curves.easeInOut,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Clear Form',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to clear all fields?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() {
      _username.clear();
      _email.clear();
      _phone.clear();
      _password.clear();
      _role = 'customer';
      _isBlocked = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    if (_authRole != 'admin') {
      return const UnauthorizedPage();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Gethouse Edit User',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1976D2), Color(0xFF2575FC)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_rounded, size: 28),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, size: 28),
            onPressed: _deleteUser,
            tooltip: 'Delete User',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFD), Color(0xFFE8EBF5)],
          ),
        ),
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                ),
              )
            : _userId == null
                ? Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.1 : 16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFE53E3E)),
                          SizedBox(height: 16),
                          Text(
                            'Missing user ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                        vertical: 24,
                      ),
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.grey[50]!],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'User Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _username,
                                    label: 'Username',
                                    icon: Icons.person_rounded,
                                    validator: (v) => v == null || v.isEmpty ? 'Username is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _email,
                                    label: 'Email',
                                    icon: Icons.email_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Email is required';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _phone,
                                    label: 'Phone',
                                    icon: Icons.phone_rounded,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v != null && v.isNotEmpty && !RegExp(r'^\+?\d{10,15}$').hasMatch(v)
                                        ? 'Enter a valid phone number'
                                        : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _password,
                                    label: 'Password (leave blank to keep same)',
                                    icon: Icons.lock_rounded,
                                    obscureText: true,
                                    validator: (v) {
                                      if (v != null && v.isNotEmpty && v.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: DropdownButtonFormField<String>(
                                    value: _role,
                                    items: const [
                                      DropdownMenuItem(value: 'customer', child: Text('Customer')),
                                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                      DropdownMenuItem(value: 'agent', child: Text('Agent')),
                                    ],
                                    onChanged: (v) => setState(() {
                                      _role = v ?? 'customer';
                                    }),
                                    decoration: InputDecoration(
                                      labelText: 'Role',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      prefixIcon: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1976D2)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 16 : 14,
                                      color: const Color(0xFF1A202C),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: SwitchListTile(
                                    title: const Text(
                                      'Blocked',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A202C),
                                      ),
                                    ),
                                    value: _isBlocked,
                                    onChanged: (v) => setState(() {
                                      _isBlocked = v;
                                    }),
                                    activeColor: const Color(0xFF1976D2),
                                    inactiveTrackColor: Colors.grey[300],
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                                if (_error != null)
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53E3E).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: ElevatedButton.icon(
                                          onPressed: _loading ? null : _clearForm,
                                          icon: const Icon(Icons.clear_rounded, size: 20),
                                          label: const Text('Clear'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            foregroundColor: const Color(0xFF1A202C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            elevation: 2,
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                              (states) => states.contains(MaterialState.hovered)
                                                  ? Colors.grey[400]!
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: ElevatedButton.icon(
                                          onPressed: _loading ? null : _save,
                                          icon: _loading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Icons.save_rounded, size: 20),
                                          label: const Text('Save'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1976D2),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            elevation: 2,
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                              (states) => states.contains(MaterialState.hovered)
                                                  ? const Color(0xFF1976D2).withOpacity(0.9)
                                                  : const Color(0xFF1976D2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    required bool isLargeScreen,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53E3E),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53E3E),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: TextStyle(
        fontSize: isLargeScreen ? 16 : 14,
        color: const Color(0xFF1A202C),
      ),
      cursorColor: const Color(0xFF1976D2),
    );
  }
}
