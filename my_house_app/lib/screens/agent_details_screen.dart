import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import '../utils/navigation_service.dart';

/// =========================
/// Agent Details Screen
/// =========================
class AgentDetailsScreen extends StatefulWidget {
  final String agentId;
  const AgentDetailsScreen({super.key, required this.agentId});

  @override
  State<AgentDetailsScreen> createState() => _AgentDetailsScreenState();
}

class _AgentDetailsScreenState extends State<AgentDetailsScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? _agent;
  bool _loading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
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
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) {
      _fetchAgent();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAgent() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final decodedList = _hashIds.decode(widget.agentId);
      if (decodedList.isEmpty) {
        setState(() {
          _error = 'Invalid agent ID';
          _loading = false;
        });
        return;
      }
      
      final decodedId = decodedList[0];
      final data = await ApiService.get('/api/agent/view/$decodedId');
      
      if (data is Map && data['message'] == 'Agent not found') {
        setState(() {
          _agent = null;
          _loading = false;
        });
        return;
      }
      
      setState(() {
        _agent = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _editAgent() {
      // Pass agentId as an argument to AgentEditScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AgentEditScreen(agentId: widget.agentId),
        ),
      ).then((_) => _fetchAgent());
    }

  Future<void> _deleteAgent() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Agent',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
        ),
        content: const Text('Are you sure you want to delete this agent? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53E3E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final decodedList = _hashIds.decode(widget.agentId);
      if (decodedList.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid agent ID')),
          );
        }
        return;
      }
      
      final decodedId = decodedList[0];
      await ApiService.delete('/api/agent/delete/$decodedId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent deleted successfully'),
            backgroundColor: Color(0xFF6A11CB),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _shareAgent() {
    if (_agent == null) return;
    Share.share(
      'Contact Agent: ${_agent!['agent_name']} in ${_agent!['region']} at ${_agent!['phone'] ?? 'N/A'}',
      subject: 'Agent Contact Details',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Gethouse Agent Details',
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
            icon: const Icon(Icons.share_rounded, size: 28),
            onPressed: _shareAgent,
            tooltip: 'Share Agent Details',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 28),
            onPressed: _fetchAgent,
            tooltip: 'Refresh',
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
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
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
                            onPressed: _fetchAgent,
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
                : _agent == null
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
                              const Icon(Icons.info_outline_rounded, size: 64, color: Color(0xFF6A11CB)),
                              const SizedBox(height: 16),
                              const Text(
                                'Agent not found',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                            vertical: 24,
                          ),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
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
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: isLargeScreen ? 80 : 60,
                                          height: isLargeScreen ? 80 : 60,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _agent!['agent_name']?.isNotEmpty == true
                                                  ? _agent!['agent_name'][0].toUpperCase()
                                                  : 'A',
                                              style: TextStyle(
                                                fontSize: isLargeScreen ? 32 : 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            _agent!['agent_name'] ?? 'Unknown Agent',
                                            style: TextStyle(
                                              fontSize: isLargeScreen ? 22 : 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF1A202C),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildDetailRow('Region', _agent!['region'] ?? 'N/A', Icons.location_on_rounded),
                                    const SizedBox(height: 16),
                                    _buildDetailRow('Phone', _agent!['phone'] ?? 'N/A', Icons.phone_rounded),
                                    const SizedBox(height: 16),
                                    _buildDetailRow('Status', _agent!['status'] ?? 'N/A', Icons.verified_user_rounded),
                                    const SizedBox(height: 16),
                                    _buildDetailRow('Created At', _agent!['created_at'] ?? 'N/A', Icons.calendar_today_rounded),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _editAgent,
                                            icon: const Icon(Icons.edit_rounded, color: Color(0xFF6A11CB)),
                                            label: const Text(
                                              'Edit',
                                              style: TextStyle(color: Color(0xFF6A11CB)),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF6A11CB)),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _deleteAgent,
                                            icon: const Icon(Icons.delete_rounded),
                                            label: const Text('Delete'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFE53E3E),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: const Color(0xFF6A11CB)),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 16, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}

/// =========================
/// Agent Edit Screen
/// =========================
class AgentEditScreen extends StatefulWidget {
  final String agentId;
  const AgentEditScreen({super.key, required this.agentId});

  @override
  State<AgentEditScreen> createState() => _AgentEditScreenState();
}

class _AgentEditScreenState extends State<AgentEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _regionCtrl;
  late TextEditingController _phoneCtrl;
  bool _loading = true;
  Map<String, dynamic>? _agentData;
  bool _initialFetchDone = false;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt',
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _regionCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialFetchDone) {
      _initialFetchDone = true;
      _fetchAgentData();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAgentData() async {
    setState(() {
      _loading = true;
    });
    
    try {
      final decodedList = _hashIds.decode(widget.agentId);
      print(widget.agentId);
      // if (decodedList.isEmpty) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Invalid agent ID')),
      //     );
      //   }
      //   return;
      // }

      final decodedId = decodedList[0];
      final data = await ApiService.get('/api/agent/view/$decodedId');
      
      if (data is Map<String, dynamic>) {
        setState(() {
          _agentData = data;
          // Set the controller values with the fetched data
          _nameCtrl.text = data['agent_name']?.toString() ?? '';
          _regionCtrl.text = data['region']?.toString() ?? '';
          _phoneCtrl.text = data['phone']?.toString() ?? '';
        });
      }
    } catch (e) {
      // Show error in build method instead of here
      if (mounted) {
        setState(() {
          _loading = false;
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

  Future<void> _save() async {
    // Only validate phone if it's not empty
    if (_phoneCtrl.text.trim().isNotEmpty && !_phoneCtrl.text.trim().startsWith('255')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone must start with 255 if provided')),
      );
      return;
    }

    try {
      final decodedList = _hashIds.decode(widget.agentId);
      if (decodedList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid agent ID')),
        );
        return;
      }

      final decodedId = decodedList[0];
      final updateData = <String, dynamic>{};
      
      // Only include fields that have been changed or are not empty
      if (_nameCtrl.text.trim().isNotEmpty) {
        updateData['agent_name'] = _nameCtrl.text.trim();
      }
      if (_regionCtrl.text.trim().isNotEmpty) {
        updateData['region'] = _regionCtrl.text.trim();
      }
      if (_phoneCtrl.text.trim().isNotEmpty) {
        updateData['phone'] = _phoneCtrl.text.trim();
      }

      // If no fields to update, show message and return
      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save')),
        );
        return;
      }

      await ApiService.putJson('/api/agent/update/$decodedId', updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agent updated successfully'),
          backgroundColor: Color(0xFF6A11CB),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text( 
          'Gethouse Edit Agent',
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
              ),
            )
          : Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                vertical: 24,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          // Agent Name Field
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Agent Name',
                              hintText: _agentData?['agent_name']?.toString() ?? 'Enter agent name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF6A11CB)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            // No validator - field is optional
                          ),
                          const SizedBox(height: 16),
                          // Region Field
                          TextFormField(
                            controller: _regionCtrl,
                            decoration: InputDecoration(
                              labelText: 'Region',
                              hintText: _agentData?['region']?.toString() ?? 'Enter region',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF6A11CB)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            // No validator - field is optional
                          ),
                          const SizedBox(height: 16),
                          // Phone Field
                          TextFormField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone (Optional)',
                              hintText: _agentData?['phone']?.toString() ?? '2557xxxxxxxx',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF6A11CB)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            // No validator - field is optional
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A11CB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
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