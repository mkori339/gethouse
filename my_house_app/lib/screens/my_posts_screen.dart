import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hashids2/hashids2.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/navigation_service.dart';
import '../models/post.dart';

class MyPostsScreen2 extends StatefulWidget {
  const MyPostsScreen2({super.key});

  @override
  State<MyPostsScreen2> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen2> with SingleTickerProviderStateMixin {
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;
  String? _userId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt', // Must match across the app
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
    _extractUserId();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _extractUserId() {
    final routeSettings = ModalRoute.of(context)?.settings;
    if (routeSettings != null) {
      final uri = Uri.parse(routeSettings.name!);
      final newUserId = uri.queryParameters['userId'];
      if (newUserId != _userId && newUserId != null) {
        setState(() {
          _userId = newUserId;
        });
        _fetchPosts();
      }
    }
  }

  Future<void> _fetchPosts() async {
    if (_userId == null) {
      setState(() {
        _error = 'User ID missing';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedUserId = _hashIds.decode(_userId!)[0];
      final resp = await ApiService.get('/api/user/view_post/$decodedUserId');
      List items = [];
      if (resp is Map && resp['posts'] is List) {
        items = resp['posts'];
      }

      setState(() {
        _posts = items;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.body?.toString() ?? 'Failed to load posts';
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

  void _goToUpdatePost(int id) {
    final encodedId = _hashIds.encode(id);
    NavigationService.navigateTo('/update-post?postId=$encodedId');
  }

  void _previewPost(dynamic postData) {
    final post = Post.fromJson(postData);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(post: post),
      ),
    );
  }

  Future<void> _deletePost(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => ScaleTransition(
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
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
    });

    try {
      final decodedId = id; // ID is already an int from post data
      await ApiService.delete('/api/user/delete_post/$decodedId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Color(0xFF6A11CB),
            duration: Duration(seconds: 3),
          ),
        );
        await _fetchPosts();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.body ?? "Failed to delete post"}'),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFE53E3E),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Gethouse My Posts',
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
            onPressed: _fetchPosts,
            icon: const Icon(Icons.refresh_rounded, size: 28),
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
                      margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.2 : 16),
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
                            onPressed: _fetchPosts,
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
                : _posts.isEmpty
                    ? Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.2 : 16),
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
                              const Icon(Icons.description_rounded, size: 64, color: Color(0xFF6A11CB)),
                              const SizedBox(height: 16),
                              const Text(
                                'No Posts Yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You haven\'t created any posts yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => NavigationService.navigateTo('/post-house'),
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: const Text('Create Your First Post'),
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
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        color: const Color(0xFF6A11CB),
                        backgroundColor: Colors.white,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isLargeScreen = constraints.maxWidth > 1200;
                            final isMediumScreen = constraints.maxWidth > 800;
                            
                            int crossAxisCount;
                            if (isLargeScreen) {
                              crossAxisCount = 3;
                            } else if (isMediumScreen) {
                              crossAxisCount = 2;
                            } else {
                              crossAxisCount = 1;
                            }
                            
                            return GridView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? constraints.maxWidth * 0.05 : 12,
                
                                vertical: 16,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: isLargeScreen ? 0.85 : (isMediumScreen ? 0.8 : 0.75),
                              ),
                              itemCount: _posts.length,
                              itemBuilder: (context, index) {
                                final post = Map<String, dynamic>.from(_posts[index]);
                                final id = post['id'];
                                final firstImage = post['images'] != null && (post['images'] as List).isNotEmpty ? post['images'][0] : null;
                                final imageUrl = firstImage != null ? 'https://sever.mikangaula.store/api/storage/${firstImage['path']}' : '';
                                final title = post['title'] ?? post['category'] ?? 'Untitled';
                                final description = post['description'] ?? post['explanation'] ?? '';
                                final amount = double.tryParse(post['amount']?.toString() ?? '0') ?? 0;
                                final formattedAmount = NumberFormat('#,##0').format(amount);
                                final category = post['category']?.toString().toUpperCase();
                                final createdAt = post['created_at'];

                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: ManageablePostCard(
                                    post: post,
                                    imageUrl: imageUrl,
                                    title: title,
                                    description: description,
                                    formattedAmount: formattedAmount,
                                    category: category,
                                    createdAt: createdAt,
                                    onPreview: () => _previewPost(post),
                                    onEdit: () => _goToUpdatePost(id),
                                    onDelete: () => _deletePost(id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => NavigationService.navigateTo('/post-house'),
        backgroundColor: const Color(0xFF6A11CB),
        tooltip: 'Create New Post',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

class ManageablePostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final String imageUrl;
  final String title;
  final String description;
  final String formattedAmount;
  final String? category;
  final dynamic createdAt;
  final VoidCallback onPreview;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ManageablePostCard({
    super.key,
    required this.post,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.formattedAmount,
    this.category,
    this.createdAt,
    required this.onPreview,
    required this.onEdit,
    required this.onDelete,
  });

  void _sharePost(BuildContext context) {
    Share.share(
      'Check out my property: $title in ${post['region']}, ${post['district']} for $formattedAmount TSH/month. ${post['explanation']}',
      subject: 'Property Listing',
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'paid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;
    
    final maxExplanationLength = isLargeScreen ? 120 : (isMediumScreen ? 100 : 80);
    final truncatedExplanation = description.length > maxExplanationLength
        ? '${description.substring(0, maxExplanationLength)}...'
        : description;

    String formattedDate = '';
    try {
      if (createdAt != null) {
        final date = DateTime.parse(createdAt);
        formattedDate = DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      formattedDate = 'Unknown date';
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: isLargeScreen ? 420 : (isMediumScreen ? 420 : 420),
      
      ),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Stack(
            children: [
              Container(
                height: isLargeScreen ? 250: (isMediumScreen ? 220 : 200),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  color: Colors.grey[200],
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.home_rounded,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.home_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
              ),
              if (post['images'] != null && (post['images'] as List).length > 1)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${(post['images'] as List).length - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$formattedAmount TSH/month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A11CB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category ?? 'PROPERTY',
                          style: const TextStyle(
                            color: Color(0xFF6A11CB),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (post['type'] ?? 'RENT').toUpperCase(),
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 20 : (isMediumScreen ? 18 : 16),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A202C),
                      height: 1.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      truncatedExplanation,
                      style: TextStyle(
                        fontSize: isLargeScreen ? 16 : 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF6A11CB)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${post['region'] ?? ''}, ${post['district'] ?? ''}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.home_rounded, size: 16, color: Color(0xFF6A11CB)),
                      const SizedBox(width: 4),
                      Text(
                        '${post['street'] ?? ''} • ${post['room_no'] ?? ''} rooms',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Posted on: $formattedDate',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(post['status'] ?? 'pending').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          (post['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(post['status'] ?? 'pending'),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.remove_red_eye_rounded,
                        label: 'Preview',
                        onPressed: onPreview,
                      ),
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        onPressed: onEdit,
                      ),
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share',
                        onPressed: () => _sharePost(context),
                      ),
                      _buildActionButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        onPressed: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 22),
          color: isDestructive ? const Color(0xFFE53E3E) : const Color(0xFF6A11CB),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDestructive ? const Color(0xFFE53E3E) : const Color(0xFF6A11CB),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Updated PreviewScreen to be responsive
class PreviewScreen extends StatelessWidget {
  final Post post;
  const PreviewScreen({super.key, required this.post});

  void _launchWhatsApp(BuildContext context, String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch WhatsApp')),
      );
    }
  }

  void _shareProperty(BuildContext context) {
    Share.share(
      'Check out this property: ${post.category} in ${post.region}, ${post.district} for ${NumberFormat('#,##0').format(post.amount)} TSH/month. Contact: ${post.user['phone'] ?? 'N/A'}',
      subject: 'Property Listing',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text(
          'Gethouse Property Details',
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
            onPressed: () => _shareProperty(context),
            tooltip: 'Share Property',
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: isLargeScreen ? 500 : (isMediumScreen ? 400 : 300),
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: post.images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = 'https://sever.mikangaula.store/api/storage/${post.images[index]['path']}';
                          return CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A11CB)),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error_rounded, size: 50, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                      if (post.images.length > 1)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${post.images.length} images',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 48 : (isMediumScreen ? 32 : 16),
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${post.category} • ${post.type}',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 28 : (isMediumScreen ? 24 : 22),
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${NumberFormat('#,##0').format(post.amount)} TSH/month',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 18 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF6A11CB)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${post.region}, ${post.district}, ${post.street}',
                              style: TextStyle(fontSize: isLargeScreen ? 18 : 16, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.meeting_room_rounded, size: 20, color: Color(0xFF6A11CB)),
                          const SizedBox(width: 8),
                          Text(
                            '${post.roomNo} rooms',
                            style: TextStyle(fontSize: isLargeScreen ? 18 : 16, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: isLargeScreen ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        post.explanation,
                        style: TextStyle(
                          fontSize: isLargeScreen ? 18 : 16, 
                          height: 1.5, 
                          color: Colors.grey[800]
                        ),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                                ),
                              ),
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Posted by: ${post.poster}',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 18 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A202C),
                                    ),
                                  ),
                                  if (post.user['phone'] != null)
                                    Text(
                                      post.user['phone'],
                                      style: TextStyle(fontSize: isLargeScreen ? 16 : 14, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            if (post.user['phone'] != null)
                              IconButton(
                                icon: const Icon(Icons.message_rounded, color: Color(0xFF6A11CB), size: 32),
                                onPressed: () => _launchWhatsApp(context, post.user['phone']),
                                tooltip: 'Contact via WhatsApp',
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}