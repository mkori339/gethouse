import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Added for modern icons
import '../services/api_service.dart';
import '../utils/navigation_service.dart';

// Define the primary blue color for local use and consistency
const Color kPrimaryBlue = Color(0xFF1976D2);

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  // Assuming a separate controller for bio/description would be here in a real app
  // final _bioController = TextEditingController(); 

  String? _userId;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extractUserId();
  }

  void _extractUserId() {
    final routeSettings = ModalRoute.of(context)?.settings;
    if (routeSettings != null && routeSettings.name != null) {
      final uri = Uri.parse(routeSettings.name!);
      final newUserId = uri.queryParameters['userId'];
      
      if (newUserId != _userId) {
        setState(() {
          _userId = newUserId;
        });
        _loadProfile();
      }
    }
  }

  Future<void> _loadProfile() async {
    if (_userId == null) {
      setState(() {
        _initialLoading = false;
        _error = 'Missing user ID in URL.';
      });
      return;
    }

    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final resp = await ApiService.get('/api/user/view_profile/$_userId');
      if (resp is Map) {
        setState(() {
          _usernameController.text = resp['username']?.toString() ?? '';
          _emailController.text = resp['email']?.toString() ?? '';
          // If you had a bio field, you'd load it here:
          // _bioController.text = resp['bio']?.toString() ?? '';
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load profile';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _initialLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fields = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        // 'bio': _bioController.text.trim(), // Include if you add a bio field
      };
      
      await ApiService.postJson('/api/user/update_profile/$_userId', fields);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      NavigationService.navigateToReplacement('/view-profile?userId=$_userId');
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.body?.toString() ?? 'Update failed. Please try again.';
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
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    // _bioController.dispose(); // Dispose if used
    super.dispose();
  }

  // --- ATTRACTIVE UI HELPERS ---

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: kPrimaryBlue),
          prefixIcon: Icon(icon, color: kPrimaryBlue),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.danger, size: 80, color: kPrimaryBlue),
            const SizedBox(height: 24),
            Text(
              'Error: $_error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Iconsax.refresh_square_2, color: Colors.white),
              label: const Text('Reload Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gethouse Edit Profile',
        ),
        backgroundColor: kPrimaryBlue, 
        foregroundColor: Colors.white,
        elevation: 4, 
        centerTitle: true,
        actions: [
          if (!_initialLoading && _userId != null)
            IconButton(
              onPressed: _loadProfile,
              icon: const Icon(Iconsax.refresh_square_2),
              color: Colors.white, // Assuming AppBar is blue from main theme
              tooltip: 'Reload Profile Data',
            ),
        ],
         
      ),
      body: Container(
        color: Colors.grey[50],
        child: _initialLoading
            ? Center(child: CircularProgressIndicator(color: kPrimaryBlue))
            : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Update Your Information',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Review and modify your personal details below.',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 30),

                          // Username Field
                          _buildTextInput(
                            controller: _usernameController,
                            label: 'Username',
                            icon: Iconsax.user,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.length < 3) {
                                return 'Username must be at least 3 characters';
                              }
                              return null;
                            },
                          ),

                          // Email Field
                          _buildTextInput(
                            controller: _emailController,
                            label: 'Email',
                            icon: Iconsax.send_square,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email address';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          
                          // Bio/Description Field (Optional but good practice)
                          // _buildTextInput(
                          //   controller: _bioController,
                          //   label: 'Bio / Description',
                          //   icon: Iconsax.note,
                          //   maxLines: 3,
                          //   validator: (value) => null, // Optional field
                          // ),

                          // Error Message (Styled)
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Iconsax.warning_2, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(color: Colors.red[800], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _save,
                            icon: const Icon(Iconsax.save_2, color: Colors.white),
                            label: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3, 
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: kPrimaryBlue, // Blue button
                              foregroundColor: Colors.white, // White text
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              elevation: 4,
                            ),
                          ),
                          
                          const SizedBox(height: 12),

                          // Cancel Button
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => NavigationService.navigateToReplacement(
                                      '/view-profile?userId=$_userId',
                                    ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: kPrimaryBlue, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}