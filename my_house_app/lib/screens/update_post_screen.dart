import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hashids2/hashids2.dart';
import 'package:my_house_app/screens/my_posts_screen.dart';
import 'package:my_house_app/services/auth_service.dart';
import '../services/api_service.dart';
import '../models/post.dart';


class UpdatePostScreen extends StatefulWidget {
  final String? postId;
  const UpdatePostScreen({super.key, this.postId});

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController();
  final _type = TextEditingController();
  final _amount = TextEditingController();
  final _explanation = TextEditingController();
  final _region = TextEditingController();
  final _district = TextEditingController();
  final _street = TextEditingController();
  final _roomNo = TextEditingController();
  List<PlatformFile> _images = [];
  List<dynamic> _existingImages = [];
  List<int> _imagesToDelete = [];
  String? _postId;
  bool _loading = false;
  String? _error;
  var userid;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt',
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );

  @override
  void initState() {
    super.initState();
    getid();
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
    if (widget.postId != null) {
      _postId = widget.postId;
      _loadPost();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_postId == null) {
      _extractPostId();
    }
  }

  @override
  void dispose() {
    _category.dispose();
    _type.dispose();
    _amount.dispose();
    _explanation.dispose();
    _region.dispose();
    _district.dispose();
    _street.dispose();
    _roomNo.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _extractPostId() {
    final routeSettings = ModalRoute.of(context)?.settings;
    if (routeSettings != null && routeSettings.name != null) {
      final uri = Uri.parse(routeSettings.name!);
      final newPostId = uri.queryParameters['postId'];
      if (newPostId != null && newPostId != _postId) {
        setState(() {
          _postId = newPostId;
        });
        _loadPost();
      }
    }
  }

  Future<void> _loadPost() async {
    if (_postId == null) {
      setState(() {
        _error = 'Missing post ID';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedPostId = _hashIds.decode(_postId!)[0];
      final resp = await ApiService.get('/api/user/view_postone/$decodedPostId');
      if (resp is Map && resp['posts'] is List && resp['posts'].isNotEmpty) {
        final post = Map<String, dynamic>.from(resp['posts'][0]);
        setState(() {
          _category.text = post['category'] ?? '';
          _type.text = post['type'] ?? '';
          _amount.text = post['amount']?.toString() ?? '';
          _explanation.text = post['explanation'] ?? '';
          _region.text = post['region'] ?? '';
          _district.text = post['district'] ?? '';
          _street.text = post['street'] ?? '';
          _roomNo.text = post['room_no']?.toString() ?? '';
          _existingImages = (post['images'] ?? []).map((img) {
            return {...img, 'id': img['id'] ?? 0};
          }).toList();
        });
      } else {
        throw Exception('Invalid post data');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load post: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null) {
        final validImages = result.files.where((file) {
          const maxSize = 5 * 1024 * 1024; // 5MB
          return file.size <= maxSize && ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());
        }).toList();
        setState(() {
          _images = validImages;
          if (_images.length != result.files.length) {
            _error = 'Some images were invalid (only JPG/PNG, max 5MB)';
          } else {
            _error = null;
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick images: $e';
      });
    }
  }

  Future<void> _deleteExistingImage(int imageId) async {
    final confirm = await showDialog<bool>(
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
            'Delete Image',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to delete this image? This action cannot be undone.'),
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

    if (confirm == true) {
      setState(() {
        _existingImages = _existingImages.where((img) => img['id'] != imageId).toList();
        _imagesToDelete.add(imageId);
      });
    }
  }

  Future<void> _clearForm() async {
    final confirm = await showDialog<bool>(
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
            'Clear Form',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to clear all fields? This action cannot be undone.'),
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
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() {
        _category.clear();
        _type.clear();
        _amount.clear();
        _explanation.clear();
        _region.clear();
        _district.clear();
        _street.clear();
        _roomNo.clear();
        _images = [];
        _imagesToDelete = [];
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final decodedPostId = _hashIds.decode(_postId!)[0];
      final fields = {
        'category': _category.text.trim(),
        'type': _type.text.trim(),
        'amount': _amount.text.trim(),
        'explanation': _explanation.text.trim(),
        'region': _region.text.trim(),
        'district': _district.text.trim(),
        'street': _street.text.trim(),
        'room_no': _roomNo.text.trim(),
        'deleted_images': _imagesToDelete.join(','),
      };

      await ApiService.postMultipart(
        path: '/api/user/update_post/$decodedPostId',
        fields: fields,
        files: _images,
        fieldName: 'images[]',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post updated successfully'),
            backgroundColor: const Color(0xFF1976D2),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.body?.toString() ?? 'Update failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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

  void _previewPost() {
    final post = Post(
      id: _hashIds.decode(_postId!)[0],
      userId: userid,
      category: _category.text.trim(),
      type: _type.text.trim(),
      amount: double.tryParse(_amount.text.trim()) ?? 0,
      explanation: _explanation.text.trim(),
      region: _region.text.trim(),
      district: _district.text.trim(),
      street: _street.text.trim(),
      roomNo: _roomNo.text.trim(),
      images: [
        ..._existingImages.map((img) => {'path': img['path']}),
        ..._images.map((img) => {'path': img.name}),
      ],
      user: {},
      poster: '',
      createdAt: DateTime.now(),
      status: 'pending', updatedAt: DateTime.now(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(post: post),
      ),
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
          'Gethouse Edit Post',
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
            icon: const Icon(Icons.remove_red_eye_rounded, size: 28),
            onPressed: _formKey.currentState?.validate() == true ? _previewPost : null,
            tooltip: 'Preview Post',
          ),
          IconButton(
            icon: const Icon(Icons.clear_rounded, size: 28),
            onPressed: _clearForm,
            tooltip: 'Clear Form',
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
        child: _postId == null
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
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Color(0xFFE53E3E)),
                      SizedBox(height: 16),
                      Text(
                        'Missing post ID',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Color(0xFF1A202C)),
                      ),
                    ],
                  ),
                ),
              )
            : _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
                        vertical: 24,
                      ),
                      child: Card(
                        elevation: 6,
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
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Post Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _category,
                                    label: 'Category',
                                    icon: Icons.category_rounded,
                                    validator: (v) => v == null || v.isEmpty ? 'Category is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _type,
                                    label: 'Type',
                                    icon: Icons.apartment_rounded,
                                    validator: (v) => v == null || v.isEmpty ? 'Type is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _amount,
                                    label: 'Amount (TSH/month)',
                                    icon: Icons.money_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Amount is required';
                                      if (double.tryParse(v) == null || double.parse(v) <= 0) {
                                        return 'Enter a valid amount';
                                      }
                                      return null;
                                    },
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _explanation,
                                    label: 'Description',
                                    icon: Icons.description_rounded,
                                    maxLines: 4,
                                    validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Location Details',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _region,
                                    label: 'Region',
                                    icon: Icons.location_on_rounded,
                                    validator: (v) => v == null || v.isEmpty ? 'Region is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _district,
                                    label: 'District',
                                    icon: Icons.map_rounded,
                                    validator: (v) => v == null || v.isEmpty ? 'District is required' : null,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _street,
                                    label: 'Street',
                                    icon: Icons.streetview_rounded,
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildTextField(
                                    controller: _roomNo,
                                    label: 'Number of Rooms',
                                    icon: Icons.meeting_room_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Number of rooms is required';
                                      if (int.tryParse(v) == null || int.parse(v) <= 0) {
                                        return 'Enter a valid number of rooms';
                                      }
                                      return null;
                                    },
                                    isLargeScreen: isLargeScreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Images',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A202C),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImages,
                                    icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                                    label: const Text('Pick Images'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white, disabledForegroundColor: Colors.grey.withOpacity(0.38), disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      elevation: 0,
                                      side: const BorderSide(
                                        width: 2,
                                        color: Colors.transparent,
                                        style: BorderStyle.solid,
                                      ),
                                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ).copyWith(
                                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                        (states) => states.contains(MaterialState.hovered)
                                            ? const Color(0xFF1976D2).withOpacity(0.9)
                                            : const Color(0xFF1976D2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_images.isNotEmpty) ...[
                                  const Text(
                                    'New Images:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A202C)),
                                  ),
                                  const SizedBox(height: 8),
                                  InteractiveViewer(
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isLargeScreen ? 4 : 2,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _images.length,
                                      itemBuilder: (context, index) {
                                        final file = _images[index];
                                        return FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Stack(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  image: DecorationImage(
                                                    image: MemoryImage(file.bytes!),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _images = _images.where((f) => f != file).toList();
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFFE53E3E),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_existingImages.isNotEmpty) ...[
                                  const Text(
                                    'Current Images:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A202C)),
                                  ),
                                  const SizedBox(height: 8),
                                  InteractiveViewer(
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: isLargeScreen ? 4 : 2,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _existingImages.length,
                                      itemBuilder: (context, index) {
                                        final img = _existingImages[index];
                                        final path = img['path'];
                                        return FadeTransition(
                                          opacity: _fadeAnimation,
                                          child: Stack(
                                            children: [
                                              CachedNetworkImage(
                                                imageUrl: 'https://sever.mkori.online/api/storage/$path',
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Center(
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                                    ),
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) => Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: const Icon(Icons.error_rounded, color: Colors.grey),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: GestureDetector(
                                                  onTap: () => _deleteExistingImage(img['id']),
                                                  child: Container(
                                                    decoration: const BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Color(0xFFE53E3E),
                                                    ),
                                                    child: const Icon(
                                                      Icons.close_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_error != null)
                                  FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE53E3E).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: ElevatedButton.icon(
                                          onPressed: _loading ? null : _clearForm,
                                          icon: const Icon(Icons.clear_rounded, size: 20),
                                          label: const Text('Clear'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[300],
                                            foregroundColor: const Color(0xFF1A202C),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            elevation: 2,
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                              (states) => states.contains(MaterialState.hovered)
                                                  ? Colors.grey[400]!
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: SlideTransition(
                                        position: _slideAnimation,
                                        child: ElevatedButton.icon(
                                          onPressed: _loading ? null : _save,
                                          icon: const Icon(Icons.save_rounded, size: 20),
                                          label: const Text('Save'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            foregroundColor: Colors.white, disabledForegroundColor: Colors.grey.withOpacity(0.38), disabledBackgroundColor: Colors.grey.withOpacity(0.12),
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                            elevation: 2,
                                            side: const BorderSide(
                                              width: 2,
                                              color: Colors.transparent,
                                              style: BorderStyle.solid,
                                            ),
                                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                              (states) => states.contains(MaterialState.hovered)
                                                  ? const Color(0xFF1976D2).withOpacity(0.9)
                                                  : const Color(0xFF1976D2),
                                            ),
                                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isLargeScreen,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Color(0xFF1976D2),
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53E3E),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFE53E3E),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: isLargeScreen ? 16 : 14,
        color: const Color(0xFF1A202C),
      ),
      cursorColor: const Color(0xFF1976D2),
    );
  }
  
  Future<void> getid() async {
    userid = await AuthService.getUserId();
  }
}
