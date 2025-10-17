// lib/screens/view_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart'; // Using iconsax for better icons
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/navigation_service.dart';

// Define the primary blue color for local use and consistency
const Color kPrimaryBlue = Color(0xFF1976D2); 

// Secondary color for a richer look
const Color kSecondaryBlue = Color(0xFF42A5F5);

class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  String? _userId;

  // Animation Controller for the header
  late AnimationController _headerAnimationController;
  late Animation<double> _headerOpacityAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Fade-in animation
    _headerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeIn,
      ),
    );

    // Slight slide-down animation
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1), // Start slightly above
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Initial data fetch
    _loadInitialData();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  // MODIFICATION: Use AuthService.getUserId() to fetch the current user's ID
  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = await AuthService.getUserId();
      
      if (currentUserId == null) {
        // If the user is not authenticated/logged in
        setState(() {
          _error = 'User not logged in. Cannot fetch profile.';
          _loading = false;
        });
        return;
      }
      
      setState(() {
        _userId = currentUserId; // Set the current user ID
      });

      // Now load the profile using the fetched ID
      await _loadProfile(currentUserId);

    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load user ID via Auth service.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // MODIFICATION: The _loadProfile now takes an optional userId
  Future<void> _loadProfile([String? userIdToLoad]) async {
    final targetUserId = userIdToLoad ?? _userId;

    if (targetUserId == null) {
      setState(() {
        _error = 'Missing user id for API call.';
        _loading = false;
      });
      return;
    }
    
    // Only show loader and clear error if it's not the initial load that already set loading=true
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      // API call using the fetched ID
      final resp = await ApiService.get('/api/user/view_profile/$targetUserId');
      
      if (resp is Map) {
        setState(() {
          _profile = Map<String, dynamic>.from(resp as Map);
        });
        
        // Start animation after data is loaded
        _headerAnimationController.forward(from: 0.0);
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
        _loading = false;
      });
    }
  }
  
  // NOTE: Original _extractUserId logic is removed as we now fetch the ID directly 
  // and assume this screen is primarily for the logged-in user's dashboard view.
  // If the screen needed to view *other* users, the original logic would be kept, 
  // but the prompt implies a current user dashboard top container.

  void _goEdit() => NavigationService.navigateTo('/edit-profile?userId=$_userId');

  Future<void> _deleteAccount() async {
    // ... (Deletion logic remains unchanged)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Account', style: TextStyle(color: kPrimaryBlue)),
        content: const Text('This will permanently delete your account. This action cannot be undone. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (ok != true) return;

    try {
      await ApiService.delete('/api/user/delete/$_userId');
      // If successful, show snackbar, clear auth, and navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account deleted successfully!'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      await AuthService.clearAuth();
      NavigationService.navigateToReplacement('/signin');
      
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body ?? "Failed to delete account"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper widget for clean detail rows (Enhanced with uniform blue icons)
  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uniform Icon Color
          Icon(icon, size: 24, color: kPrimaryBlue), 
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget to display main content
  Widget _buildProfileContent(BuildContext context) {
    // Determine if there is a profile image (mocking a field 'profileImageUrl')
    final String? profileImageUrl = _profile?['profileImageUrl']?.toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 1. Animated Profile Header Card (Top Container)
          FadeTransition(
            opacity: _headerOpacityAnimation,
            child: SlideTransition(
              position: _headerSlideAnimation,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                margin: EdgeInsets.zero,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  // Animated Gradient Background for attractiveness
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kPrimaryBlue.withOpacity(0.9), kSecondaryBlue.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryBlue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with Image/Initial
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white70, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white, 
                          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl) : null,
                          child: profileImageUrl == null ? Text(
                            (_profile?['username'] ?? 'U').toString()[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryBlue, 
                            ),
                          ) : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Username
                      Text(
                        _profile?['username']?.toString() ?? 'No username',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white, // White text for contrast on blue gradient
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Role Chip
                      if (_profile?['role'] != null)
                        Chip(
                          label: Text(
                            _profile!['role']!.toString().toUpperCase(),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                          ),
                          backgroundColor: Colors.white, // White chip for prominence
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 2. Profile Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bio/About Section
                  if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Me',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                        const Divider(height: 20, color: kPrimaryBlue), // Blue Divider
                        Text(
                          _profile!['bio']!.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // Contact Info Section
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryBlue,
                    ),
                  ),
                  const Divider(height: 20, color: kPrimaryBlue), // Blue Divider
                  
                  if (_profile?['email'] != null)
                    _buildProfileDetailRow(
                      icon: Iconsax.send_square,
                      label: 'Email Address',
                      value: _profile!['email'].toString(),
                    ),
                  
                  if (_profile?['phone'] != null)
                    _buildProfileDetailRow(
                      icon: Iconsax.call,
                      label: 'Phone Number',
                      value: _profile!['phone'].toString(),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // 3. Action Buttons
          Column(
            children: [
              // Edit Button (Uniform Blue)
              ElevatedButton.icon(
                onPressed: _goEdit,
                icon: const Icon(Iconsax.edit_2, size: 24, color: Colors.white),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: kPrimaryBlue, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  elevation: 4,
                ),
              ),
              const SizedBox(height: 16),
              // Delete Button (Remains Red for safety)
              ElevatedButton.icon(
                onPressed: _deleteAccount,
                icon: const Icon(Iconsax.trash, size: 24, color: Colors.white),
                label: const Text('Delete Account'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: Colors.red[700], 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  elevation: 4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget to display the error state (Uniform Blue)
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.danger, size: 80, color: kPrimaryBlue), // Uniform blue icon
            const SizedBox(height: 24),
            Text(
              'Could not load profile. $_error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadProfile(), // Reload profile for the current user ID
              icon: const Icon(Iconsax.refresh_square_2, color: Colors.white),
              label: const Text('Refresh'),
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
        title: const Text('Gethouse Profile'),
        backgroundColor: kPrimaryBlue, 
        foregroundColor: Colors.white,
        elevation: 4, 
        centerTitle: true,
        actions: [
            IconButton(
              onPressed: () => _loadProfile(), // Reload current user profile
              icon: const Icon(Iconsax.refresh),
              color: Colors.white,
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: _loading
          ? Center(child: CircularProgressIndicator(color: kPrimaryBlue))
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(context),
      ),
    );
  }
}