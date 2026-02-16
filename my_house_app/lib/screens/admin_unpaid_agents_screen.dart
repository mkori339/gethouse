import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/screens/unauthorized_page.dart';
import 'package:my_house_app/services/auth_service.dart';
import '../services/api_service.dart';

class AdminUnpaidAgentsScreen extends StatefulWidget {
  const AdminUnpaidAgentsScreen({super.key});

  @override
  State<AdminUnpaidAgentsScreen> createState() => _AdminUnpaidAgentsScreenState();
}

class _AdminUnpaidAgentsScreenState extends State<AdminUnpaidAgentsScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _agents = [];
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
      final resp = await ApiService.get('/api/admin/view_unpaid_agents');
      final items = resp['agents'] is List ? resp['agents'] : (resp is List ? resp : []);
      setState(() {
        _agents = List<Map<String, dynamic>>.from(items.map((e) => Map<String, dynamic>.from(e)));
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to fetch agents';
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
    if (_search.trim().isEmpty) return _agents;
    final q = _search.toLowerCase();
    return _agents.where((a) =>
        (a['agent_name']?.toString().toLowerCase().contains(q) ?? false) ||
        (a['region']?.toString().toLowerCase().contains(q) ?? false) ||
        (a['phone']?.toString().toLowerCase().contains(q) ?? false)).toList();
  }

  Future<void> _verifyAgent(int id) async {
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
            'Verify Agent',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to verify this agent?'),
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
      await ApiService.postJson('/api/admin/verify_agent/$decodedId', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Agent verified successfully'),
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
            content: Text('Error: ${e.body?.toString() ?? 'Failed to verify agent'}'),
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

  Future<void> _deleteAgent(int id) async {
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
            'Delete Agent',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to delete this agent? This action cannot be undone.'),
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
      await ApiService.delete('/api/admin/delete_agent/$decodedId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Agent deleted successfully'),
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
            content: Text('Error: ${e.body?.toString() ?? 'Failed to delete agent'}'),
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

  // Future<void> _viewAgentDetails(int id) async {
  //   try {
  //     final decodedId = _hashIds.decode(_hashIds.encode(id))[0];
  //     final resp = await ApiService.get('/api/admin/view_agent/$decodedId');
  //     final agent = Map<String, dynamic>.from(resp is Map ? resp : {});
  //     if (mounted) {
  //       showDialog(
  //         context: context,
  //         builder: (_) => ScaleTransition(
  //           scale: Tween<double>(begin: 0.8, end: 1.0).animate(
  //             CurvedAnimation(
  //               parent: AnimationController(
  //                 vsync: this,
  //                 duration: const Duration(milliseconds: 300),
  //               )..forward(),
  //               curve: Curves.easeInOut,
  //             ),
  //           ),
  //           child: AlertDialog(
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //             title: Text(
  //               'Agent: ${agent['agent_name'] ?? 'Unknown'}',
  //               style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
  //             ),
  //             content: SingleChildScrollView(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text('Region: ${agent['region'] ?? 'N/A'}'),
  //                   const SizedBox(height: 12),
  //                   Text('Phone: ${agent['phone'] ?? 'N/A'}'),
  //                   const SizedBox(height: 12),
  //                   Text('Status: ${agent['status']?.toString().capitalize() ?? 'Unpaid'}'),
  //                   const SizedBox(height: 12),
  //                   if (agent['email'] != null) ...[
  //                     Text('Email: ${agent['email']}'),
  //                     const SizedBox(height: 12),
  //                   ],
  //                   if (agent['created_at'] != null)
  //                     Text('Registered: ${agent['created_at'].toString().substring(0, 10)}'),
  //                 ],
  //               ),
  //             ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Close', style: TextStyle(color: Colors.grey)),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     }
  //   } on ApiException catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error: ${e.body?.toString() ?? 'Failed to load agent details'}'),
  //           backgroundColor: const Color(0xFFE53E3E),
  //           duration: const Duration(seconds: 3),
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error: $e'),
  //           backgroundColor: const Color(0xFFE53E3E),
  //           duration: const Duration(seconds: 3),
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //         ),
  //       );
  //     }
  //   }
  // }

  Widget _buildAgentCard(Map<String, dynamic> a, bool isLargeScreen) {
    final id = a['id'];
    final status = a['status']?.toString().toLowerCase() ?? 'unpaid';
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
                      a['agent_name'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['region'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['phone'] ?? 'N/A',
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
                  // IconButton(
                  //   icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF1976D2)),
                  //   onPressed: () => _viewAgentDetails(id),
                  //   tooltip: 'View Details',
                  // ),
                  ElevatedButton(
                    onPressed: () => _verifyAgent(id),
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
                    onPressed: () => _deleteAgent(id),
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
          'Gethouse Unpaid Agents',
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
            tooltip: 'Refresh Agents',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetch,
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        tooltip: 'Refresh Agents',
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
                        'Unpaid Agents',
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
                            hintText: 'Search agents by name, region, or phone',
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
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                      'No agents found',
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
                                            itemBuilder: (_, i) => _buildAgentCard(_filtered[i], isLargeScreen),
                                          )
                                        : ListView.builder(
                                            itemCount: _filtered.length,
                                            itemBuilder: (_, i) => _buildAgentCard(_filtered[i], isLargeScreen),
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
