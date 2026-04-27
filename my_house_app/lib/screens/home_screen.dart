import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:my_house_app/theme.dart';
import 'package:my_house_app/widgets/app_shell.dart';
import '../widgets/house_search_filter.dart';
import '../services/api_service.dart';
import '../models/post.dart';
import '../widgets/house_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Post>> _postsFuture;
  List<Post> _allPosts = [];
  List<Post> _filteredPosts = [];
  Map<String, dynamic> _currentFilters = {};
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMorePosts();
    }
  }

  Future<List<Post>> _fetchPosts() async {
    try {
      final resp = await ApiService.get('/api/posts/public');
      List items = [];
      if (resp is Map && resp['posts'] is List)
        items = resp['posts'];
      else if (resp is List) items = resp;

      final posts =
          items.map((p) => Post.fromJson(p as Map<String, dynamic>)).toList();

      setState(() {
        _allPosts = posts;
        _filteredPosts = posts;
      });

      return posts;
    } on ApiException catch (e) {
      throw Exception(e.body is Map
          ? (e.body['message']?.toString() ?? e.body.toString())
          : e.body.toString());
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final resp = await ApiService.get('/api/posts/public', params: {
        'page': nextPage,
        ..._currentFilters,
      });

      List items = [];
      if (resp is Map && resp['posts'] is List)
        items = resp['posts'];
      else if (resp is List) items = resp;

      if (items.isEmpty) {
        setState(() {
          _hasMorePages = false;
        });
      } else {
        final newPosts =
            items.map((p) => Post.fromJson(p as Map<String, dynamic>)).toList();

        setState(() {
          _allPosts.addAll(newPosts);
          _filteredPosts = _applyFiltersToPosts(_allPosts, _currentFilters);
          _currentPage = nextPage;
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
      _filteredPosts = _applyFiltersToPosts(_allPosts, filters);
      _currentPage = 1;
      _hasMorePages = true;
    });
  }

  List<Post> _applyFiltersToPosts(
      List<Post> posts, Map<String, dynamic> filters) {
    if (filters.isEmpty) return posts;

    return posts.where((post) {
      if (filters['category'] != null &&
          post.category.toLowerCase() !=
              filters['category'].toString().toLowerCase()) {
        return false;
      }
      if (filters['type'] != null &&
          post.type.toLowerCase() != filters['type'].toString().toLowerCase()) {
        return false;
      }
      if (filters['region'] != null &&
          post.region.toLowerCase() !=
              filters['region'].toString().toLowerCase()) {
        return false;
      }
      if (filters['cost_below'] != null &&
          post.amount > double.parse(filters['cost_below'].toString())) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFD), Color(0xFFE8EBF5)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) => HouseSearchFilter(
            initialFilters: _currentFilters,
            onFilter: _applyFilters,
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = _fetchPosts();
      _currentFilters = {};
      _currentPage = 1;
      _hasMorePages = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final gridMaxExtent = width < 420 ? width : (width < 760 ? 260.0 : 320.0);
    final gridAspectRatio = width < 420 ? 0.76 : (width < 760 ? 0.8 : 0.96);

    return AppShell(
      currentRoute: '/home',
      title: 'Discover Homes',
      subtitle: 'Mobile-first browsing with fast filters',
      icon: Iconsax.house_2,
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Refresh listings',
          icon: const Icon(Iconsax.refresh),
        ),
        IconButton(
          onPressed: _showFilterDialog,
          tooltip: 'Filter properties',
          icon: const Icon(Iconsax.filter),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFilterDialog,
        icon: const Icon(Iconsax.filter),
        label: const Text('Filter'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        displacement: 40,
        edgeOffset: 20,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroSection(width),
            ),
            if (_currentFilters.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildActiveFilters(),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Latest listings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Text(
                      '${_filteredPosts.length} results',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 12),
              sliver: FutureBuilder<List<Post>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      _filteredPosts.isEmpty) {
                    return _buildStateMessage(
                      icon: const CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      message: 'Loading fresh listings...',
                      color: AppColors.primary,
                    );
                  } else if (snapshot.hasError) {
                    return _buildStateMessage(
                      icon: const Icon(
                        Iconsax.warning_2,
                        size: 64,
                        color: AppColors.primary,
                      ),
                      message: 'Listings are temporarily unavailable',
                      subMessage: 'Pull to refresh or try again shortly.',
                      color: AppColors.primary,
                    );
                  } else if (!snapshot.hasData || _filteredPosts.isEmpty) {
                    return _buildStateMessage(
                      icon: const Icon(
                        Iconsax.home_1,
                        size: 52,
                        color: AppColors.primary,
                      ),
                      message: 'No properties found',
                      subMessage: _currentFilters.isEmpty
                          ? 'New homes will appear here as they are verified.'
                          : 'Adjust your filters to widen the search.',
                      color: AppColors.primary,
                    );
                  } else {
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: gridMaxExtent,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: gridAspectRatio,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            HouseCard(post: _filteredPosts[index]),
                        childCount: _filteredPosts.length,
                      ),
                    );
                  }
                },
              ),
            ),
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
              ),
            if (!_hasMorePages && _filteredPosts.isNotEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'You have reached the end of the current listings.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _buildAgentsPanel(context),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(double width) {
    final isCompact = width < 420;

    return Container(
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.flash_1,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Text(
                'Find a verified home faster',
                style: TextStyle(
                  fontSize: 24,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Browse mobile-ready cards, filter by region instantly, and jump from discovery to agent contact in a few taps.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeroMetric(
                icon: Iconsax.home_2,
                label: 'Available',
                value: _allPosts.length.toString(),
              ),
              _buildHeroMetric(
                icon: Iconsax.filter,
                label: 'Filtered',
                value: _filteredPosts.length.toString(),
              ),
              _buildHeroMetric(
                icon: Iconsax.refresh,
                label: 'Page',
                value: _currentPage.toString(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: _showFilterDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Iconsax.filter),
                label: const Text('Quick filters'),
              ),
              OutlinedButton.icon(
                onPressed: _refresh,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                ),
                icon: const Icon(Iconsax.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.06, duration: 500.ms);
  }

  Widget _buildHeroMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.filter, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Active filters',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentFilters = {};
                    _filteredPosts = _allPosts;
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _currentFilters.entries
                .map(
                  (entry) => Chip(
                    avatar: const Icon(
                      Iconsax.tag,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    label: Text('${entry.key}: ${entry.value}'),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04, duration: 350.ms);
  }

  Widget _buildAgentsPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 28),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7CA6), Color(0xFF2AA6C9)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Iconsax.profile_2user, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Need help choosing?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Open the agent directory to contact verified experts and move faster from browsing to booking.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.84),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/agents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Iconsax.arrow_right_3),
            label: const Text('Browse agents'),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 450.ms).slideY(begin: 0.05);
  }

  Widget _buildStateMessage({
    required Widget icon,
    required String message,
    String? subMessage,
    required Color color,
  }) {
    return SliverToBoxAdapter(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 0,
          vertical: MediaQuery.of(context).size.height * 0.1,
        ),
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
          children: [
            icon,
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
