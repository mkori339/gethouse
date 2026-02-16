import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:my_house_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../services/auth_service.dart';

/// PREVIEW SCREEN
class PreviewScreen extends StatelessWidget {
  final Post post;
  const PreviewScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width > 600 ? 450.0 : 350.0;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg, // <-- use theme scaffold background
      appBar: AppBar(
        title: const Text(
          'Property Details 🏠',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, secondary], // <-- use theme colors
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Iconsax.share, size: 24, color: Colors.white),
            onPressed: () => _shareProperty(context),
            tooltip: 'Share Property',
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image carousel with enhanced design
            SizedBox(
              height: imageHeight,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: post.images.length,
                    itemBuilder: (context, index) {
                      final img = post.images[index];
                      final imagePath = img['path']?.toString() ?? '';
                      // NOTE: Change 127.0.0.1 to your server IP for testing on a real device/emulator.
                      final imageUrl = 'https://sever.mkori.online/api/storage/$imagePath';
                      return Hero(
                        tag: 'property-image-${post.id}-$imagePath',
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[200]!],
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primary),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[300]!, Colors.grey[200]!],
                              ),
                            ),
                            child: const Icon(Iconsax.gallery_slash, size: 50, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),

                  // Image counter badge
                  if (post.images.length > 1)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          '${post.images.length} images',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 600.ms),
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Property details with enhanced animation
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
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A202C),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 400.ms, duration: 600.ms),

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1976D2), Color(0xFF2575FC)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${NumberFormat('#,##0').format(post.amount)} TSH/month',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            )
                                .animate()
                                .scale(delay: 500.ms, duration: 600.ms),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Property details grid
                 isDesktop 
  ? GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 4,
      children: [
        _buildDetailItem(
          icon: Iconsax.location,
          title: 'Location',
          value: '${post.region}, ${post.district}',
          delay: 600.ms,
        ),
        _buildDetailItem(
          icon: Iconsax.home,
          title: 'Street',
          value: post.street,
          delay: 700.ms,
        ),
        _buildDetailItem(
          icon: Iconsax.category,
          title: 'Rooms',
          value: '${post.roomNo} rooms',
          delay: 800.ms,
        ),
      ],
    )
  : Column(
      children: [
        _buildDetailItem(
          icon: Iconsax.location,
          title: 'Location',
          value: '${post.region}, ${post.district}',
          delay: 600.ms,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          icon: Iconsax.home,
          title: 'Street',
          value: post.street,
          delay: 700.ms,
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          icon: Iconsax.category,
          title: 'Rooms',
          value: '${post.roomNo} rooms',
          delay: 800.ms,
        ),
      ],
    ),

      const SizedBox(height: 32),

                  // Description section
                  const Text(
                    'Description 📝',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 600.ms),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      post.explanation,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey[800],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 600.ms),

                  const SizedBox(height: 32),

                  // Poster info with enhanced design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF2575FC)],
                            ),
                          ),
                          child: const Icon(Iconsax.user, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Posted by: ${post.poster}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A202C),
                                ),
                              ),
                              if (post.user['phone'] != null)
                                Text(
                                  post.user['phone'],
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        if (post.user['phone'] != null)
                          IconButton(
                            icon: const Icon(Iconsax.message, color: Color(0xFF1976D2), size: 28),
                            onPressed: () => _launchWhatsApp(context, post.user['phone']),
                            tooltip: 'Contact via WhatsApp',
                          )
                              .animate()
                              .scale(delay: 1100.ms, duration: 600.ms),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1100.ms, duration: 600.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String title, required String value, Duration delay = Duration.zero}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1976D2), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A202C),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: delay, duration: 600.ms)
        .slide(begin: const Offset(0.2, 0), duration: 400.ms);
  }

  void _launchWhatsApp(BuildContext context, String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not launch WhatsApp'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _shareProperty(BuildContext context) {
    Share.share(
      '🏠 Check out this amazing property on Gethouse!\n\n'
          '${post.category} in ${post.region}, ${post.district}\n'
          'Price: ${NumberFormat('#,##0').format(post.amount)} TSH/month\n'
          'Contact: ${post.user['phone'] ?? 'N/A'}\n\n'
          'Download Gethouse App to discover more properties!',
      subject: 'Amazing Property Listing on Gethouse',
    );
  }
}

//---

/// COMMENTS SCREEN
class CommentsScreen extends StatefulWidget {
  final Post post;
  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<Comment> _comments = [];
  bool _loading = false;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _loading = true);
    try {
      final response = await ApiService.get('/api/posts/${widget.post.id}/comments');
      final List<Comment> loaded = (response['comments'] as List).map((json) => Comment.fromJson(json)).toList();
      setState(() {
        _comments.clear();
        _comments.addAll(loaded);
      });
    } catch (e) {
      debugPrint("Error fetching comments: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to load comments'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _posting = true);
    try {
      final response = await ApiService.postJson('/api/posts/${widget.post.id}/comments', {'content': content});
      final newCommentJson = response['comment'] ?? response;
      final newComment = Comment.fromJson(newCommentJson);
      setState(() {
        _comments.insert(0, newComment);
        _commentController.clear();
      });
    } catch (e) {
      debugPrint("Error posting comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to comment'),
          backgroundColor: const Color(0xFFF97316),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _posting = false);
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Try common endpoints; adjust if your API differs.
      await ApiService.delete('/api/comments/$commentId');
      setState(() {
        _comments.removeWhere((c) => c.id == commentId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Comment deleted'), backgroundColor: Colors.green[600]),
      );
    } catch (e) {
      debugPrint('Delete failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to delete comment'), backgroundColor: Colors.red[400]),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final primary = Theme.of(context).colorScheme.primary;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final currentUserId = AuthService.getUserId();

    return Scaffold(
      backgroundColor: scaffoldBg, // <-- theme background
      appBar: AppBar(
        title: const Text('Comments 💬', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, Theme.of(context).colorScheme.secondary],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            )
                : _comments.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.messages, size: 64, color: primary),
                  const SizedBox(height: 16),
                  Text(
                    'No comments yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to comment!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 16,
                vertical: 16,
              ),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final commenterName = (comment.userName != null && comment.userName!.isNotEmpty) ? comment.userName! : 'User';
                final commenterInitial = commenterName.isNotEmpty ? commenterName[0].toUpperCase() : 'U';
                final isOwner = (comment.userId != null && comment.userId == currentUserId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primary,
                        child: Text(
                          commenterInitial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    commenterName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A202C),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('MMM dd, yyyy').format(comment.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: 'Delete comment',
                                        icon: Icon(Iconsax.trash, color: Colors.red[400], size: 20),
                                        onPressed: () => _deleteComment(comment.id),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.content,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      prefixIcon: Icon(Iconsax.message, color: primary),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _posting ? null : _addComment,
                  backgroundColor: primary,
                  child: _posting
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Icon(Iconsax.send_2, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//---

/// HOUSE CARD (Stateful to handle likes & counts & width constraints)
class HouseCard extends StatefulWidget {
  final Post post;
  const HouseCard({super.key, required this.post});

  @override
  State<HouseCard> createState() => _HouseCardState();
}

class _HouseCardState extends State<HouseCard> {
  int _likesCount = 0;
  int _commentsCount = 0; // NEW: Comment count state
  bool _likedByMe = false;
  bool _loadingCounts = true; // Renamed for clarity

  @override
  void initState() {
    super.initState();
    _loadPostStats(); // Renamed function
  }

  // Renamed and updated to load both likes and comments count
  Future<void> _loadPostStats() async {
    setState(() => _loadingCounts = true);
    try {
      final likesResp = await ApiService.get('/api/posts/${widget.post.id}/likes');
      // NEW: Fetch comments to get the accurate count. This will count the comments already posted.
      final commentsResp = await ApiService.get('/api/posts/${widget.post.id}/comments');
      final List<dynamic> loadedComments = commentsResp['comments'] ?? commentsResp;

      setState(() {
        _likesCount = likesResp['count'] ?? 0;
        final usersData = likesResp['users'] ?? likesResp;
        final List users = usersData is List ? usersData : [];

        _likedByMe = users.any((u) {
          try {
            if (u is Map) {
              if (u['is_current'] == true) return true;
              final uid = u['user_id'] ?? u['userId'];
              return uid != null && uid == AuthService.getUserId();
            } else {
              final dyn = u as dynamic;
              final uid = dyn.userId ?? dyn.user_id;
              return uid != null && uid == AuthService.getUserId();
            }
          } catch (_) {
            return false;
          }
        });
        _likedByMe = users.any((u) {
          if (u is Map && (u['is_current'] == true || u['user_id'] == AuthService.getUserId())) return true;
          return false;
        });
        _commentsCount = loadedComments.length; // Set the new comment count
      });
    } catch (e) {
      debugPrint('Failed to load post stats: $e');
    } finally {
      setState(() => _loadingCounts = false);
    }
  }

  Future<void> _toggleLike() async {
    try {
      await ApiService.postJson('/api/posts/${widget.post.id}/like', {});
      await _loadPostStats(); // Use the new function
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
    content: Row(
      children: [
        const Icon(
          Iconsax.warning_2,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Please login to like',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: const Color(0xFFF97316),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    duration: const Duration(seconds: 3),
  ),
);
    }
  }

  Future<void> _reportPost(int postId, String reason, String phone) async {
    try {
      await ApiService.postJson('/api/report/post', {'post_id': postId, 'reason': reason, 'details': phone});
      
        ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
    content: Row(
      children: [
        const Icon(
          Iconsax.warning_2,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Report submitted successfully',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
    backgroundColor: const Color(0xFFF97316),
    behavior: SnackBarBehavior.floating,
    margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    duration: const Duration(seconds: 3),
  ),
);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Report failed: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final img = post.images.isNotEmpty ? post.images[0]['path']?.toString() : null;
    final imgUrl = img != null ? 'https://sever.mkori.online/api/storage/$img' : null;
    final formattedAmount = NumberFormat('#,##0').format(post.amount);
    final formattedDate = DateFormat('MMM dd, yyyy').format(post.createdAt);
    final maxExplanationLength = 120;
    final truncatedExplanation = post.street.length > maxExplanationLength
        ? '${post.street.substring(0, maxExplanationLength)}...'
        : post.street;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final double cardMaxWidth = screenWidth > 1000 ? 900 : (screenWidth > 800 ? 700 : double.infinity);

    // Theme colors used in this widget
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Center(
      child: SizedBox(
        width: cardMaxWidth,
        child: Card(
          elevation: 6,
          color: const Color(0xFF1976D2), // <-- card uses theme primary tint now
          margin: EdgeInsets.symmetric(vertical: isMobile ? 6 : 12, horizontal: isMobile ? 4 : 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PreviewScreen(post: post),
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section with AspectRatio for dynamic height (FIXED OVERFLOW)
                Stack(
                  children: [
                    // --- NEW AspectRatio for responsive image sizing ---
                    AspectRatio(
                      aspectRatio: 4 / 3, // Adjust ratio as needed (e.g., 4 / 3) 16/9
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          color: Colors.grey[200],
                        ),
                        child: imgUrl != null
                            ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Hero(
                                tag: 'property-image-${post.id}-$img',
                                child: CachedNetworkImage(
                                  imageUrl: imgUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Center(
                                    child: Icon(Iconsax.gallery_slash, size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                        )
                            : const Center(
                          child: Icon(Iconsax.house, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                    // --- END AspectRatio ---

                    // Price/Type Badge
                    Positioned(
                      top: isMobile ? 8 : 12,
                      left: isMobile ? 8 : 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12,
                          vertical: isMobile ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          color: secondary.withOpacity(0.9), // <-- theme
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.type,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 11 : 13,
                          ),
                        ),
                      ),
                    ),

                    // Amount Badge
                    Positioned(
                      bottom: isMobile ? 8 : 12,
                      right: isMobile ? 8 : 12,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 14,
                          vertical: isMobile ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primary, secondary], // <-- theme gradient
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          '$formattedAmount TSH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Details Section
                Padding(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Location
                      Text(
                        '${post.category} - ${post.region}',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Description
                      Text(
                        truncatedExplanation,
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 13,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Footer Actions & Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Likes count
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleLike,
                                child: Icon(
                                  _likedByMe ? Iconsax.heart5 : Iconsax.heart,
                                  size: isMobile ? 14 : 18,
                                  color: _likedByMe ? Colors.white: const Color(0xFFDBD5D5), // <-- theme primary
                                ),
                              ),
                              const SizedBox(width: 3),
                              _loadingCounts
                                  ? SizedBox(
                                height: 8,
                                width: 8,
                                child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                              )
                                  : Text(
                                '${_likesCount}',
                                style: TextStyle(
                                  fontSize: isMobile ? 10 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),

                          // NEW: Comments count
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentsScreen(post: post),
                                    ),
                                  ).then((_) => _loadPostStats()); // Refresh stats on return
                                },
                                child: Row(
                                  children: [
                                    Icon(Iconsax.message_square, size: isMobile ? 14 : 18, color: Colors.white),
                                    const SizedBox(width: 3),
                                    _loadingCounts
                                        ? SizedBox(
                                      height: 8,
                                      width: 8,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                    )
                                        : Text(
                                      '${_commentsCount}',
                                      style: TextStyle(
                                        fontSize: isMobile ? 10 : 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Post Date
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: isMobile ? 9 : 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ),);
  }
}