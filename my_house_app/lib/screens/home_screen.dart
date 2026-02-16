import 'package:flutter/material.dart';
import 'package:my_house_app/widgets/app_drawer.dart';
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
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
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
      if (resp is Map && resp['posts'] is List) items = resp['posts'];
      else if (resp is List) items = resp;

      final posts = items.map((p) => Post.fromJson(p as Map<String, dynamic>)).toList();

      setState(() {
        _allPosts = posts;
        _filteredPosts = posts;
      });

      return posts;
    } on ApiException catch (e) {
      throw Exception(e.body is Map ? (e.body['message']?.toString() ?? e.body.toString()) : e.body.toString());
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
      if (resp is Map && resp['posts'] is List) items = resp['posts'];
      else if (resp is List) items = resp;

      if (items.isEmpty) {
        setState(() {
          _hasMorePages = false;
        });
      } else {
        final newPosts = items.map((p) => Post.fromJson(p as Map<String, dynamic>)).toList();

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

  List<Post> _applyFiltersToPosts(List<Post> posts, Map<String, dynamic> filters) {
    if (filters.isEmpty) return posts;

    return posts.where((post) {
      if (filters['category'] != null &&
          post.category.toLowerCase() != filters['category'].toString().toLowerCase()) {
        return false;
      }
      if (filters['type'] != null &&
          post.type.toLowerCase() != filters['type'].toString().toLowerCase()) {
        return false;
      }
      if (filters['region'] != null &&
          post.region.toLowerCase() != filters['region'].toString().toLowerCase()) {
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: isDesktop
            ? Center(
              child: Text(
                  'Discover Properties and get your dream home very fast in just few clicks and easy steps',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
            )
            : Center(
              child: const Text(
                  'Discover Properties',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1976D2), Color(0xFF2575FC)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 28),
            onPressed: _showFilterDialog,
            tooltip: 'Filter properties',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFF1976D2),
        backgroundColor: Colors.white,
        displacement: 40,
        edgeOffset: 20,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sticky Featured Properties Header
            SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: _FeaturedPropertiesPersistentHeaderDelegate(),
            ),
            if (_currentFilters.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_alt_rounded, size: 20, color: const Color(0xFF1976D2)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Filters: ${_currentFilters.entries.map((e) => '${e.key}: ${e.value}').join(', ')}',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF2D3748)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentFilters = {};
                                _filteredPosts = _allPosts;
                              });
                            },
                            icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                            label: const Text('Clear', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slide(begin: const Offset(0, -0.2), duration: 400.ms),
                  ],
                ),
              ),

            // Houses Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Container(
                        //   padding: const EdgeInsets.all(10),
                        //   decoration: BoxDecoration(
                        //     gradient: const LinearGradient(
                        //       colors: [const Color(0xFF1976D2), Color(0xFF2575FC)],
                        //     ),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                        // ),

                 
                        
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Houses List
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600 ? 16 : 8,
              ),
              sliver: FutureBuilder<List<Post>>(
                future: _postsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildStateMessage(
                      icon: const CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2)),
                      ),
                      message: 'Loading properties...',
                      color: const Color(0xFF1976D2),
                    );
                  } else if (snapshot.hasError) {
              
                    return _buildStateMessage(
                      icon: const Icon(Icons.error_outline_rounded, size: 70, color: Color.fromARGB(255, 7, 11, 212)),
                      message: 'Error loading properties something went wrong so plaese try again letter ',
                      // subMessage: '${snapshot.error}',
                      subMessage: 'sever is now down for temporary',
                      color: const Color.fromARGB(255, 9, 6, 231),
                    );
                  } else if (!snapshot.hasData || _filteredPosts.isEmpty) {
                    return _buildStateMessage(
                      icon: const Icon(Icons.home_outlined, size: 48, color: Color(0xFF1976D2)),
                      message: 'No properties found',
                      subMessage: _currentFilters.isEmpty
                          ? 'Check back later for new listings'
                          : 'Try adjusting your filters',
                      color: const Color(0xFF1976D2),
                    );
                  } else {
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.85 : 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return HouseCard(post: _filteredPosts[index]);
                        },
                        childCount: _filteredPosts.length,
                      ),
                    );
                  }
                },
              ),
            ),

            // Loading indicator for pagination
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2)),
                    ),
                  ),
                ),
              ),

            // End of list message
            if (!_hasMorePages && _filteredPosts.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'No more properties to load',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                ),
              ),

            // Agents Section
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 16 : 16,
                  vertical: 24,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1976D2), Color(0xFF2575FC)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1976D2).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.group_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'Connect With Experts',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Our professional agents are ready to help you find your perfect home',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: MediaQuery.of(context).size.width > 600 ? 200 : 150,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/agents'),
                        icon: const Icon(Icons.arrow_forward_rounded, color: const Color(0xFF1976D2)),
                        label: const Text(
                          'Browse Agents',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1976D2),
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.search_rounded, color: Colors.white),
        tooltip: 'Quick Search',
      ),
    );
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
          horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 16,
          vertical:MediaQuery.of(context).size.height *0.17,
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

class _FeaturedPropertiesPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
            'Featured Properties Available',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 5, 130, 219),
            fontStyle: FontStyle.italic
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_FeaturedPropertiesPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}