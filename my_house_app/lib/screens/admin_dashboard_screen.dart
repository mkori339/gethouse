import 'package:flutter/material.dart';
import 'package:my_house_app/screens/unauthorized_page.dart';
import 'package:my_house_app/services/auth_service.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/widgets/app_shell.dart';
import '../services/api_service.dart';
import '../utils/navigation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  int users = 0, agents = 0, posts = 0;
  int pendingPosts = 0, pendingAgents = 0, openReports = 0, blockedUsers = 0;
  bool _registrationOpen = true;
  bool _togglingRegistration = false;
  String? _role;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _checkRoleAndLoadStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndLoadStats() async {
    _role = await AuthService.getRole();
    if (_role == 'admin') {
      await _loadStats();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.get('/api/admin/view');
      setState(() {
        users = resp['users_count'] ?? 0;
        agents = resp['agents_count'] ?? 0;
        posts = resp['posts_count'] ?? 0;
        _registrationOpen = resp['registration_open'] ?? true;
        pendingPosts = resp['pending_posts_count'] ?? 0;
        pendingAgents = resp['pending_agents_count'] ?? 0;
        openReports = resp['open_reports_count'] ?? 0;
        blockedUsers = resp['blocked_users_count'] ?? 0;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load stats';
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

  Future<void> _toggleRegistration() async {
    final newStatus = !_registrationOpen;
    final actionText = newStatus ? 'open' : 'close';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '${newStatus ? 'Open' : 'Close'} Registration',
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
        ),
        content: Text(
            'Are you sure you want to $actionText new user registrations?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  newStatus ? const Color(0xFF1976D2) : const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(newStatus ? 'Open' : 'Close'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _togglingRegistration = true;
    });

    try {
      await ApiService.postJson(
          '/api/admin/close_registration', {'open': newStatus});
      setState(() {
        _registrationOpen = newStatus;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registrations ${newStatus ? 'opened' : 'closed'} successfully! 🎉'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error: ${e.body?.toString() ?? 'Failed to update registration status'}'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _togglingRegistration = false;
        });
      }
    }
  }

  void _openUnpaidPosts() =>
      NavigationService.navigateTo('/admin/unpaid-posts');
  void _openUnpaidAgents() =>
      NavigationService.navigateTo('/admin/unpaid-agents');
  void _openManageUsers() =>
      NavigationService.navigateTo('/admin/manage-users');
  void _viewReport() => NavigationService.navigateTo('/admin/reports');

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1000;
    final isTablet = screenWidth > 600;

    if (_role != 'admin') {
      return const UnauthorizedPage();
    }

    late final Widget content;
    if (_loading) {
      content = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else if (_error != null) {
      content = Center(
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: isDesktop ? screenWidth * 0.2 : 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.warning_2, size: 64, color: Color(0xFFE53E3E)),
              const SizedBox(height: 20),
              Text(
                'Error Loading Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadStats,
                icon: const Icon(Iconsax.refresh, size: 20),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    } else {
      content = FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40 : 24,
            vertical: 32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                      'Control the platform from one mobile workspace.',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Watch pending approvals, moderation pressure, and registration state without leaving the dashboard.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.84),
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 250.ms, duration: 500.ms)
                  .slideY(begin: -0.05),
              const SizedBox(height: 28),
              const Text(
                'Welcome, Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'Manage your platform with ease',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              const SizedBox(height: 32),
              const Text(
                'Platform Overview 📊',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 1.2 : 1.5,
                children: [
                  _buildStatCard(
                    title: 'Total Users',
                    count: users,
                    icon: Iconsax.profile_2user,
                    color: const Color(0xFF3B82F6),
                    delay: 600.ms,
                  ),
                  _buildStatCard(
                    title: 'Verified Agents',
                    count: agents,
                    icon: Iconsax.profile_tick,
                    color: const Color(0xFF14B8A6),
                    delay: 700.ms,
                  ),
                  _buildStatCard(
                    title: 'Active Posts',
                    count: posts,
                    icon: Iconsax.home,
                    color: const Color(0xFFF59E0B),
                    delay: 800.ms,
                  ),
                  _buildStatCard(
                    title: 'Pending Posts',
                    count: pendingPosts,
                    icon: Iconsax.receipt_item,
                    color: AppColors.accent,
                    delay: 900.ms,
                  ),
                  _buildStatCard(
                    title: 'Open Reports',
                    count: openReports,
                    icon: Iconsax.warning_2,
                    color: AppColors.danger,
                    delay: 1000.ms,
                  ),
                  _buildStatCard(
                    title: 'Blocked Users',
                    count: blockedUsers,
                    icon: Iconsax.user_remove,
                    color: const Color(0xFF7C3AED),
                    delay: 1100.ms,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Quick Actions ⚡',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A202C),
                ),
              ).animate().fadeIn(delay: 900.ms, duration: 600.ms),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildActionButton(
                    label: 'Unpaid Posts',
                    icon: Iconsax.receipt,
                    color: const Color(0xFF1976D2),
                    onPressed: _openUnpaidPosts,
                    tooltip: 'View unpaid posts',
                    delay: 1000.ms,
                  ),
                  _buildActionButton(
                    label: 'Unpaid Agents',
                    icon: Iconsax.profile_2user,
                    color: const Color(0xFF1976D2),
                    onPressed: _openUnpaidAgents,
                    tooltip: 'View unpaid agents',
                    delay: 1100.ms,
                  ),
                  _buildActionButton(
                    label: 'Manage Users',
                    icon: Iconsax.people,
                    color: const Color(0xFF1976D2),
                    onPressed: _openManageUsers,
                    tooltip: 'Manage user accounts',
                    delay: 1200.ms,
                  ),
                  _buildActionButton(
                    label: 'View Reports',
                    icon: Iconsax.chart,
                    color: const Color(0xFF1976D2),
                    onPressed: _viewReport,
                    tooltip: 'View system reports',
                    delay: 1300.ms,
                  ),
                  _buildActionButton(
                    label: _registrationOpen
                        ? 'Close Registration'
                        : 'Open Registration',
                    icon: _registrationOpen ? Iconsax.lock : Iconsax.unlock,
                    color: _registrationOpen
                        ? const Color(0xFFE53E3E)
                        : const Color(0xFF10B981),
                    onPressed:
                        _togglingRegistration ? null : _toggleRegistration,
                    tooltip: _registrationOpen
                        ? 'Close new user registrations'
                        : 'Open new user registrations',
                    delay: 1400.ms,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _registrationOpen
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE53E3E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _registrationOpen
                            ? 'User registration is currently OPEN'
                            : 'User registration is currently CLOSED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    if (_togglingRegistration)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: 1500.ms, duration: 600.ms),
              const SizedBox(height: 20),
              Text(
                'Use the quick actions above to manage your platform efficiently. '
                'Monitor statistics and make informed decisions.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ).animate().fadeIn(delay: 1600.ms, duration: 600.ms),
            ],
          ),
        ),
      );
    }

    return AppShell(
      currentRoute: '/admin-dashboard',
      title: 'Admin Dashboard',
      subtitle: 'Platform controls, queues, and status',
      icon: Iconsax.status_up,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _loadStats,
          tooltip: 'Refresh Stats',
        ).animate().scale(delay: 200.ms, duration: 600.ms),
      ],
      body: content,
    );
  }

  Widget _buildStatCard(
      {required String title,
      required int count,
      required IconData icon,
      required Color color,
      Duration delay = Duration.zero}) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ).animate().scale(delay: delay, duration: 600.ms),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: delay + 100.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A202C),
              ),
            ).animate().fadeIn(delay: delay + 200.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
    Duration delay = Duration.zero,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            elevation: 3,
            shadowColor: color.withOpacity(0.3),
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
              (states) => states.contains(MaterialState.hovered)
                  ? color.withOpacity(0.9)
                  : color,
            ),
            overlayColor:
                MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: delay, duration: 600.ms)
          .slide(begin: const Offset(0, 0.2), duration: 400.ms),
    );
  }
}
