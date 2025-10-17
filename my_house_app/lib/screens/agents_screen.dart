import 'package:flutter/material.dart';
import 'package:my_house_app/widgets/app_drawer.dart';
import '../models/agent.dart';
import '../widgets/agent_card.dart';
import '../widgets/agent_filter.dart';
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  late Future<List<Agent>> _agentsFuture;
  List<Agent> _allAgents = [];
  List<Agent> _filteredAgents = [];
  String? _currentFilter;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _agentsFuture = _fetchAgents();
  }

  Future<List<Agent>> _fetchAgents() async {
    try {
      final resp = await ApiService.get('/api/agents');
      List items = [];
      if (resp is Map && resp['agents'] is List) items = resp['agents'];
      else if (resp is List) items = resp;
      
      final agents = items.map((a) => Agent.fromJson(a as Map<String, dynamic>)).toList();
      
      setState(() {
        _allAgents = agents;
        _filteredAgents = agents;
      });
      
      return agents;
    } on ApiException catch (e) {
      throw Exception(e.body is Map ? (e.body['message']?.toString() ?? e.body.toString()) : e.body.toString());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

 void _applyFilter(String? region) {
  setState(() {
    _currentFilter = region;
    if (region == null || region.isEmpty) {
      _filteredAgents = _allAgents;
    } else {
      _filteredAgents = _allAgents.where((agent) => 
        agent.region?.toLowerCase().trim() == region.toLowerCase().trim()
      ).toList();
    }
  });

}

  void _showFilterDialog() {
    // Get unique regions from agents, handling null values
    final regions = _allAgents
        .map((agent) => agent.region?.trim())
        .where((region) => region != null && region.isNotEmpty)
        .toSet()
        .toList()
        .cast<String>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          color: Colors.white,
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          maxChildSize: 0.6,
          minChildSize: 0.3,
          builder: (context, scrollController) => AgentFilter(
            onFilter: _applyFilter,
            regions: regions,
            currentFilter: _currentFilter,
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() { 
      _isRefreshing = true;
    });
    
    await _fetchAgents();
    
    setState(() { 
      _currentFilter = null;
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Professional Agents ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF6A11CB),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.filter, size: 24),
            onPressed: _showFilterDialog,
            tooltip: 'Filter agents',
          )
          .animate()
          .scale(delay: 200.ms, duration: 600.ms),
          
          IconButton(
            icon: const Icon(Iconsax.refresh, size: 24),
            onPressed: _refresh,
            tooltip: 'Refresh',
          )
          .animate()
          .scale(delay: 300.ms, duration: 600.ms),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FAFD),
              Colors.white,
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF6A11CB),
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // Filter indicator with animation
              if (_currentFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.all(16),
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
                    border: Border.all(
                      color: const Color(0xFF6A11CB).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Iconsax.filter, size: 18, color: Color(0xFF6A11CB)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Filter: $_currentFilter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6A11CB),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _currentFilter = null;
                            _filteredAgents = _allAgents;
                          });
                        },
                        tooltip: 'Clear filter',
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .slide(begin: const Offset(0, -0.2), duration: 400.ms),
              
              // Stats overview
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6A11CB).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Iconsax.profile_2user,
                      value: _allAgents.length.toString(),
                      label: 'Total Agents',
                      delay: 400.ms,
                    ),
                    _buildStatItem(
                      icon: Iconsax.location,
                      value: _allAgents.map((a) => a.region).toSet().length.toString(),
                      label: 'Regions',
                      delay: 500.ms,
                    ),
                    _buildStatItem(
                      icon: Iconsax.star,
                      value: '4.8',
                      label: 'Avg Rating',
                      delay: 600.ms,
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .scale(begin: const Offset(0.9, 0.9), duration: 600.ms),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: FutureBuilder<List<Agent>>(
                  future: _agentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.warning_2, size: 64, color: Colors.orange),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading agents',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Iconsax.refresh),
                              label: const Text('Try Again'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A11CB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || _filteredAgents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.profile_2user, size: 80, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _currentFilter == null 
                                ? 'No agents available' 
                                : 'No agents found in $_currentFilter',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check back later for new agents',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_currentFilter != null)
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentFilter = null;
                                    _filteredAgents = _allAgents;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A11CB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Clear Filter'),
                              ),
                          ],
                        ),
                      );
                    } else {
                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 24 : 16,
                          vertical: 16,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                       childAspectRatio: isDesktop ? 1.5 : 1.8,

 // Reduced height
                        ),
                        itemCount: _filteredAgents.length,
                        itemBuilder: (context, index) {
                          return AgentCard(
                            agent: _filteredAgents[index],
                          )
                          .animate()
                          .fadeIn(delay: (100 * index).ms, duration: 600.ms)
                          .scale(begin: const Offset(0.9, 0.9), duration: 600.ms);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, Duration delay = Duration.zero}) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        )
        .animate()
        .scale(delay: delay, duration: 600.ms),
        
        const SizedBox(height: 8),
        
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        )
        .animate()
        .fadeIn(delay: delay + 100.ms, duration: 600.ms),
        
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        )
        .animate()
        .fadeIn(delay: delay + 200.ms, duration: 600.ms),
      ],
    );
  }
}