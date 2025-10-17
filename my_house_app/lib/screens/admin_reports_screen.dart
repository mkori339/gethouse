import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/screens/unauthorized_page.dart';
import 'package:my_house_app/services/auth_service.dart';
import '../services/api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with TickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _reports = [];
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
      await _fetchReports();
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _fetchReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ApiService.get('/api/admin/view_reports');
      final items = resp['reports'] is List ? resp['reports'] : [];
      setState(() {
        _reports = List<Map<String, dynamic>>.from(items.map((e) => Map<String, dynamic>.from(e)));
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to fetch reports';
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
    if (_search.trim().isEmpty) return _reports;
    final q = _search.toLowerCase();
    return _reports.where((r) {
      final report = r['report'] ?? {};
      final reporter = r['reporter'] ?? {};
      final reported = r['reported'] ?? {};
      return (report['reason']?.toString().toLowerCase().contains(q) ?? false) ||
          (report['details']?.toString().toLowerCase().contains(q) ?? false) ||
          (reporter['username']?.toString().toLowerCase().contains(q) ?? false) ||
          (reported['poster']?.toString().toLowerCase().contains(q) ?? false) ||
          (report['report_type']?.toString().toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _dismissReport(int id) async {
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
            'Delete Report',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to dismiss this report?'),
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
              child: const Text('delete'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final decodedId = _hashIds.decode(_hashIds.encode(id))[0];
      await ApiService.postJson('/api/admin/report/delete/$decodedId', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report deleted successfully'),
            backgroundColor: const Color(0xFF6A11CB),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        await _fetchReports();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body?.toString() ?? 'Failed to dismiss report'}'),
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

  void _openDetailDialog(Map<String, dynamic> report, Map<String, dynamic> reporter, Map<String, dynamic>? reported) {
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
            'Report #${report['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${report['report_type']?.toString().capitalize() ?? 'Unknown'}'),
                const SizedBox(height: 12),
                Text('Reason: ${report['reason'] ?? 'N/A'}'),
                const SizedBox(height: 12),
                Text('Details: ${report['details'] ?? 'N/A'}'),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    report['status']?.toString().capitalize() ?? 'Open',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(report['status']?.toString().toLowerCase() ?? 'open'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Text('Reporter: ${reporter['username'] ?? 'Unknown'}'),
                Text('Reporter Email: ${reporter['email'] ?? 'N/A'}'),
                const SizedBox(height: 12),
                if (reported != null) ...[
                  const Divider(),
                  Text('Reported Entity: ${reported['poster'] ?? 'N/A'}'),
                  Text('Reported Email: ${reported['email'] ?? 'N/A'}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
           
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _dismissReport(report['id']);
                },
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
  }

  Widget _buildReportCard(Map<String, dynamic> item, bool isLargeScreen) {
    final report = Map<String, dynamic>.from(item['report'] ?? {});
    final reporter = Map<String, dynamic>.from(item['reporter'] ?? {});
    final reported = item['reported'] != null ? Map<String, dynamic>.from(item['reported']) : null;

    final id = report['id'];
    final reason = report['reason'] ?? 'N/A';
    final details = report['details'] ?? 'N/A';
    final status = report['status']?.toString().toLowerCase() ?? 'open';
    final reporterName = reporter['username'] ?? 'Unknown';
    final reportedName = reported != null ? reported['poster'] ?? 'N/A' : 'N/A';

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
                      'Report #$id — ${report['report_type']?.toString().capitalize() ?? 'Unknown'}',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reason: $reason',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Details: $details',
                      style: TextStyle(
                        fontSize: isLargeScreen ? 14 : 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            'Reporter: $reporterName',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF6A11CB),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Chip(
                          label: Text(
                            status.capitalize(),
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                          ),
                          backgroundColor: _getStatusColor(status),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF6A11CB)),
                onPressed: () => _openDetailDialog(report, reporter, reported),
                tooltip: 'View Report Details',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF14B8A6);
      case 'dismissed':
        return const Color(0xFFE53E3E);
      case 'open':
      default:
        return const Color(0xFFF59E0B);
    }
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
          'Gethouse Reports View',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _fetchReports,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchReports,
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        tooltip: 'Refresh Reports',
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
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
                        'Reports',
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
                            hintText: 'Search reports by reason, reporter, or type',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6A11CB)),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF6A11CB)),
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
                              borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6A11CB), width: 2),
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
                          cursorColor: const Color(0xFF6A11CB),
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
                                        onPressed: _fetchReports,
                                        icon: const Icon(Icons.refresh_rounded, size: 20),
                                        label: const Text('Try Again'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF6A11CB),
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
                                      'No reports found',
                                      style: TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchReports,
                                    color: const Color(0xFF6A11CB),
                                    child: isLargeScreen
                                        ? GridView.builder(
                                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 2,
                                              crossAxisSpacing: 16,
                                              mainAxisSpacing: 16,
                                              childAspectRatio: 2,
                                            ),
                                            itemCount: _filtered.length,
                                            itemBuilder: (_, i) => _buildReportCard(_filtered[i], isLargeScreen),
                                          )
                                        : ListView.builder(
                                            itemCount: _filtered.length,
                                            itemBuilder: (_, i) => _buildReportCard(_filtered[i], isLargeScreen),
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