import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/widgets/app_drawer.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/navigation_service.dart';
import '../models/agent.dart';
import 'agent_details_screen.dart';

// Define theme colors for uniformity
const Color kPrimaryPurple = Color(0xFF6A11CB); // Main Purple from AppBar
const Color kPrimaryBlue = Color(0xFF2575FC); // Main Blue from AppBar
const Color kAccentColor = Color(0xFFFFC107); // A bright accent for highlights

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _me; // This will hold the user profile data
  bool _loading = true;
  String? _error;
  Agent? _agent;
  String? role;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt', // Replace with a secure salt
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Longer duration for smooth entry
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic, // Use a smoother curve
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // MODIFICATION: Fetch the user profile (me) as well
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final id = await AuthService.getUserId();
      role = await AuthService.getRole();

      if (id == null) {
         throw Exception("User ID not found. Please log in.");
      }

      // 1. Fetch User Profile Data for the top container display
      final meResp = await ApiService.get('/api/user/view_profile/$id');
      if (meResp is Map) {
        _me = Map<String, dynamic>.from(meResp as Map);
      }

      // 2. Fetch Agent Data (Existing logic)
      try {
        final encodedId = _hashIds.encode(int.parse(id));
        final agentResp = await ApiService.get('/api/agent/view/$encodedId');
        if (agentResp is Map && agentResp['id'] != null) {
          _agent = Agent.fromJson(Map<String, dynamic>.from(agentResp));
        } else {
          _agent = null;
        }
      } catch (e) {
        _agent = null; // Agent not found
      }

      setState(() {
        _loading = false;
      });
      _animationController.forward(from: 0.0); // Start animation on successful load

    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load dashboard data';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _goToMyPosts() async {
    String? userId = await AuthService.getUserId();
    if (userId != null) {
      // NOTE: The user ID passed to `view-profile` and `my-posts` should be the raw ID if the backend expects it.
      // Based on the original code, it expects the HASHED ID for navigation.
      final encodedId = _hashIds.encode(int.parse(userId));
      NavigationService.navigateTo('/my-posts?userId=$encodedId');
    }
  }

  void _goToProfile() async {
    String? userId = await AuthService.getUserId();
    if (userId != null) {
      // NOTE: Passing the raw ID for the profile screen to fetch the profile.
      // The previous screen's code was using the HASHED ID for view-profile, which may be incorrect.
      // I'll stick to the original logic here, which uses the HASHED ID for navigation.
      final encodedId = _hashIds.encode(int.parse(userId));
      NavigationService.navigateTo('/view-profile?userId=$encodedId');
    }
  }

  void _goToAgentRequest() {
    NavigationService.navigateTo('/agent-request');
  }

  void _goToAgentDetails() {
    if (_agent == null) return;
    final encodedId = _hashIds.encode(_agent!.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgentDetailsScreen(agentId: encodedId),
      ),
    );
  }

  void _goToCreatePost() {
    NavigationService.navigateTo('/post-house');
  }

  void _logout() async {
    await AuthService.clearAuth();
    NavigationService.navigateToReplacement('/login');
  }

  // MODIFICATION: Enhanced Action Button for visual appeal and animation
  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // Wrap with AnimatedBuilder for the 'tap' effect (optional, but good practice)
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Card(
              elevation: 6, // Higher elevation for prominence
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.1), color.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  title: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, // Bolder text
                      fontSize: 18,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color), // Uniform icon color
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // MODIFICATION: Extracted User Header into a dedicated animated widget
  Widget _buildUserHeader(String username, String email, String avatarText, String? role, bool isLargeScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOut,
          ),
        ),
        child: Card(
          elevation: 8, // High elevation for the top container
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              // Uniform Gradient
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryPurple, kPrimaryBlue],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryPurple.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: isLargeScreen ? 80 : 70,
                    height: isLargeScreen ? 80 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        avatarText,
                        style: TextStyle(
                          fontSize: isLargeScreen ? 36 : 32,
                          fontWeight: FontWeight.bold,
                          color: kAccentColor, // Highlight color for the initial
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $username!',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 24 : 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 16 : 14,
                              color: Colors.white70,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            role?.toUpperCase() ?? 'GUEST',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimaryPurple,
                            ),
                          ),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 28),
                    tooltip: 'Logout',
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _me?['username'] ?? _me?['name'] ?? 'User';
    final email = _me?['email'] ?? '';
    final avatarText = username.isNotEmpty ? username[0].toUpperCase() : 'U';
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Gethouse Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            // Uniform Gradient in AppBar
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [kPrimaryPurple, kPrimaryBlue],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFD), Color(0xFFE8EBF5)],
          ),
        ),
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryPurple),
                ),
              )
            : _error != null
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFE53E3E)),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: kPrimaryPurple,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Modified User Profile Header (Top Container)
                          _buildUserHeader(username, email, avatarText, role, isLargeScreen),
                          const SizedBox(height: 24),
                          // Quick Actions Section
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return GridView.count(
                                crossAxisCount: isLargeScreen ? 2 : 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16, // Increased spacing
                                crossAxisSpacing: isLargeScreen ? 16 : 0, // Increased spacing
                                childAspectRatio: isLargeScreen ? 4 : 5, // Adjusted aspect ratio
                                children: [
                                  _buildActionButton(
                                    'Create New Post',
                                    Icons.add_home_work_rounded, // Better icon
                                    _goToCreatePost,
                                    kPrimaryBlue, // Uniform Blue color
                                  ),
                                  _buildActionButton(
                                    'My Posts',
                                    Icons.article_rounded, // Better icon
                                    _goToMyPosts,
                                    Colors.green,
                                  ),
                                  _buildActionButton(
                                    'View Profile',
                                    Icons.person_pin_rounded, // Better icon
                                    _goToProfile,
                                    kPrimaryPurple, // Uniform Purple color
                                  ),
                                  _agent == null
                                      ? _buildActionButton(
                                          'Become an Agent',
                                          Icons.real_estate_agent_rounded, // Better icon
                                          _goToAgentRequest,
                                          Colors.orange,
                                        )
                                      : _buildActionButton(
                                          'View Agent Details',
                                          Icons.verified_user_rounded, // Better icon
                                          _goToAgentDetails,
                                          Colors.teal,
                                        ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreatePost,
        backgroundColor: kPrimaryPurple,
        tooltip: 'Create New Post',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}