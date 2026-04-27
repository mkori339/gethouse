import 'package:flutter/material.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/widgets/app_shell.dart';
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

  @override
  void initState() {
    super.initState();
    _agentsFuture = _fetchAgents();
  }

  Future<List<Agent>> _fetchAgents() async {
    try {
      final resp = await ApiService.get('/api/agents');
      List items = [];
      if (resp is Map && resp['agents'] is List) {
        items = resp['agents'];
      } else if (resp is List) {
        items = resp;
      }

      final agents =
          items.map((a) => Agent.fromJson(a as Map<String, dynamic>)).toList();

      setState(() {
        _allAgents = agents;
        _filteredAgents = agents;
      });

      return agents;
    } on ApiException catch (e) {
      throw Exception(e.body is Map
          ? (e.body['message']?.toString() ?? e.body.toString())
          : e.body.toString());
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
        _filteredAgents = _allAgents
            .where((agent) =>
                agent.region.toLowerCase().trim() ==
                region.toLowerCase().trim())
            .toList();
      }
    });
  }

  void _showFilterDialog() {
    // Get unique regions from agents, handling null values
    final regions = _allAgents
        .map((agent) => agent.region.trim())
        .where((region) => region.isNotEmpty)
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
    await _fetchAgents();

    setState(() {
      _currentFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return AppShell(
      currentRoute: '/agents',
      title: 'Verified Agents',
      subtitle: 'Find local experts and contact them fast',
      icon: Iconsax.profile_2user,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.filter),
          onPressed: _showFilterDialog,
          tooltip: 'Filter agents',
        ).animate().scale(delay: 200.ms, duration: 600.ms),
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: _refresh,
          tooltip: 'Refresh',
        ).animate().scale(delay: 300.ms, duration: 600.ms),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        icon: const Icon(Iconsax.filter),
        label: const Text('Region'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SizedBox.expand(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reach an agent in a few taps',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Search by region, scan compact cards, and open WhatsApp directly from each listing.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: -0.04, duration: 400.ms),
              if (_currentFilter != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.location,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Region: $_currentFilter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
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
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: -0.04, duration: 350.ms),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Iconsax.profile_2user,
                      value: _allAgents.length.toString(),
                      label: 'Verified',
                      delay: 400.ms,
                    ),
                    _buildStatItem(
                      icon: Iconsax.location,
                      value: _allAgents
                          .map((a) => a.region)
                          .toSet()
                          .length
                          .toString(),
                      label: 'Regions',
                      delay: 500.ms,
                    ),
                    _buildStatItem(
                      icon: Iconsax.status,
                      value: _currentFilter?.toUpperCase() ?? 'LIVE',
                      label: 'Focus',
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.warning_2,
                              size: 64,
                              color: AppColors.accent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading agents',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                '${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Iconsax.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || _filteredAgents.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.profile_2user,
                              size: 80,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentFilter == null
                                  ? 'No agents available'
                                  : 'No agents found in $_currentFilter',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check back later for new agents.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedText,
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
                                child: const Text('Clear Filter'),
                              ),
                          ],
                        ),
                      );
                    } else {
                      return GridView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 12 : 2,
                          vertical: 8,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 2,
                          crossAxisSpacing: isDesktop ? 18 : 12,
                          mainAxisSpacing: 18,
                          childAspectRatio: isDesktop ? 1.5 : 1.12,
                        ),
                        itemCount: _filteredAgents.length,
                        itemBuilder: (context, index) {
                          return AgentCard(agent: _filteredAgents[index])
                              .animate()
                              .fadeIn(
                                delay: (100 * index).ms,
                                duration: 600.ms,
                              )
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                duration: 600.ms,
                              );
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

  Widget _buildStatItem(
      {required IconData icon,
      required String value,
      required String label,
      Duration delay = Duration.zero}) {
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
        ).animate().scale(delay: delay, duration: 600.ms),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ).animate().fadeIn(delay: delay + 100.ms, duration: 600.ms),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ).animate().fadeIn(delay: delay + 200.ms, duration: 600.ms),
      ],
    );
  }
}
