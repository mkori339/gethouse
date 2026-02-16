import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/screens/unauthorized_page.dart';
import 'package:my_house_app/services/auth_service.dart';
import '../services/api_service.dart';

class AdminUnpaidPostsScreen extends StatefulWidget {
  const AdminUnpaidPostsScreen({super.key});

  @override
  State<AdminUnpaidPostsScreen> createState() => _AdminUnpaidPostsScreenState();
}

class _AdminUnpaidPostsScreenState extends State<AdminUnpaidPostsScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  String _search = '';
  String? _authRole;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt',
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );
  final TextEditingController _searchController = TextEditingController();

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
    _checkRoleAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkRoleAndFetch() async {
    _authRole = await AuthService.getRole();
    if (_authRole == 'admin') {
      await _fetch();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.get('/api/posts/unpaid');
      final items = resp['posts'] is List ? resp['posts'] : (resp is List ? resp : []);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(items.map((e) => Map<String, dynamic>.from(e)));
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to fetch posts';
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

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _posts;
    final q = _search.toLowerCase();
    return _posts.where((p) =>
        (p['category']?.toString().toLowerCase().contains(q) ?? false) ||
        (p['poster']?.toString().toLowerCase().contains(q) ?? false) ||
        (p['region']?.toString().toLowerCase().contains(q) ?? false)).toList();
  }

  Future<void> _verifyPost(int id) async {
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
            'Verify Post',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to verify this post?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final decodedId = _hashIds.decode(_hashIds.encode(id))[0];
      await ApiService.postJson('/api/admin/verify_post/$decodedId', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post verified successfully'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _fetch();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body?.toString() ?? 'Failed to verify post'}'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deletePost(int id) async {
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
            'Delete Post',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
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

    try {
      final decodedId = _hashIds.decode(_hashIds.encode(id))[0];
      await ApiService.delete('/api/admin/delete_post/$decodedId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted successfully'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _fetch();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body?.toString() ?? 'Failed to delete post'}'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _viewPostDetails(int id) async {
    try {
      final decodedId = _hashIds.decode(_hashIds.encode(id))[0];
      final resp = await ApiService.get('/api/user/view_postone/$decodedId');
      final post = Map<String, dynamic>.from(resp is Map ? resp : {});
      if (mounted) {
        showDialog(
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
              title: Text(
                'Post: ${post['category'] ?? post['type'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount: ${post['amount']?.toString() ?? 'N/A'}'),
                    const SizedBox(height: 12),
                    Text('Poster: ${post['poster'] ?? 'N/A'}'),
                    const SizedBox(height: 12),
                    Text('Region: ${post['region'] ?? 'N/A'}'),
                    const SizedBox(height: 12),
                    Text('Status: ${post['status']?.toString().capitalize() ?? 'Unpaid'}'),
                    const SizedBox(height: 12),
                    if (post['description'] != null) ...[
                      Text('Description: ${post['description']}'),
                      const SizedBox(height: 12),
                    ],
                    if (post['created_at'] != null)
                      Text('Created: ${post['created_at'].toString().substring(0, 10)}'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body?.toString() ?? 'Failed to load post details'}'),
            backgroundColor: const Color(0xFFE53E3E),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Widget _buildPostCard(Map<String, dynamic> p, bool isLargeScreen) {
    final id = p['id'];
    final title = p['category'] ?? p['type'] ?? 'Post';
    final poster = p['poster'] ?? 'Unknown';
    final amount = p['amount']?.toString() ?? 'N/A';
    final region = p['region'] ?? 'N/A';
    final status = p['status']?.toString().toLowerCase() ?? 'unpaid';

    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
      ),
      child: Card(
        elevation: 4,
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title — $amount',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By $poster • $region',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(
                        status.capitalize(),
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      backgroundColor: status == 'verified' ? const Color(0xFF14B8A6) : const Color(0xFFF59E0B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF1976D2)),
                    onPressed: () => _viewPostDetails(id),
                    tooltip: 'View Details',
                  ),
                  ElevatedButton(
                    onPressed: () => _verifyPost(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B8A6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => states.contains(MaterialState.hovered)
                            ? const Color(0xFF14B8A6).withOpacity(0.9)
                            : const Color(0xFF14B8A6),
                      ),
                    ),
                    child: const Text('Verify', style: TextStyle(fontSize: 12)),
                  ),
                  OutlinedButton(
                    onPressed: () => _deletePost(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE53E3E),
                      side: const BorderSide(color: Color(0xFFE53E3E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ).copyWith(
                      side: MaterialStateProperty.resolveWith<BorderSide>(
                        (states) => states.contains(MaterialState.hovered)
                            ? const BorderSide(color: Color(0xFFE53E3E), width: 2)
                            : const BorderSide(color: Color(0xFFE53E3E)),
                      ),
                    ),
                    child: const Text('Delete', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
          'Unpaid Posts (Pending)',
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
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _fetch,
            tooltip: 'Refresh Posts',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetch,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        tooltip: 'Refresh Posts',
        child: const Icon(Icons.refresh_rounded),
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
            : FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unpaid Posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SlideTransition(
                        position: _slideAnimation,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search posts by category, poster, or region',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1976D2)),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF1976D2)),
                                    onPressed: () {
                                      setState(() {
                                        _search = '';
                                        _searchController.clear();
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (v) => setState(() {
                            _search = v;
                          }),
                          style: TextStyle(
                            fontSize: isLargeScreen ? 16 : 14,
                            color: const Color(0xFF1A202C),
                          ),
                          cursorColor: const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _error != null
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
                                        'Error: $_error',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _fetch,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        label: const Text('Try Again'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _filtered.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No unpaid posts found',
                                      style: TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetch,
                                    color: const Color(0xFF1976D2),
                                    child: isLargeScreen
                                        ? GridView.builder(
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: 2,
                                            ),
                                            itemCount: _filtered.length,
                                            itemBuilder: (_, i) => _buildPostCard(_filtered[i], isLargeScreen),
                                          )
                                        : ListView.builder(
                                            itemCount: _filtered.length,
                                            itemBuilder: (_, i) => _buildPostCard(_filtered[i], isLargeScreen),
                                          ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
