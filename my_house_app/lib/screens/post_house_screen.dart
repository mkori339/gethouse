import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iconsax/iconsax.dart';
// import 'package:cached_network_image/cached_network_image.dart'; // Not used in this version, kept for context
import '../services/api_service.dart';

// Define the primary blue color for consistency
const Color kPrimaryBlue = Color(0xFF1976D2); 

class PostHouseScreen extends StatefulWidget {
  const PostHouseScreen({super.key});

  @override
  State<PostHouseScreen> createState() => _PostHouseScreenState();
}

class _PostHouseScreenState extends State<PostHouseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _explanationCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _roomNoCtrl = TextEditingController();

  List<PlatformFile> _newImages = [];
  bool _loading = false;
  String? _error;

  // Dropdown values
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedRegion;

  // Options for dropdowns
  final List<String> _categories = [
    'Apartment',
    'House',
    'Studio',
    'Villa',
    'Townhouse',
    'Commercial',
    'Land',
    'Other'
  ];

  final List<String> _types = [
    'Rent',
    'Sale',
    'Lease'
  ];

  final List<String> _tanzaniaRegions = [
    'Arusha',
    'Dar es Salaam',
    'Dodoma',
    'Geita',
    'Iringa',
    'Kagera',
    'Katavi',
    'Kigoma',
    'Kilimanjaro',
    'Lindi',
    'Manyara',
    'Mara',
    'Mbeya',
    'Mjini Magharibi',
    'Morogoro',
    'Mtwara',
    'Mwanza',
    'Njombe',
    'Pemba North',
    'Pemba South',
    'Pwani',
    'Rukwa',
    'Ruvuma',
    'Shinyanga',
    'Simiyu',
    'Singida',
    'Songwe',
    'Tabora',
    'Tanga',
    'Unguja North',
    'Unguja South'
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _explanationCtrl.dispose();
    _districtCtrl.dispose();
    _streetCtrl.dispose();
    _roomNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;
    final files = result.files;

    // compute remaining slots: max 3 total
    final remaining = (3 - _newImages.length).clamp(0, 3);

    if (remaining <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('You have reached the maximum of 3 images.'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final accepted = files.take(remaining).toList();
    if (files.length > accepted.length && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only select $remaining more image(s).'),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    setState(() {
      _newImages.addAll(accepted);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _openImagePreview(PlatformFile imageFile) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Using a simple image memory widget as cached_network_image is for network URLs
            Image.memory(
              imageFile.bytes!,
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 0.9,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure dropdowns are selected
    if (_selectedCategory == null) {
      setState(() {
        _error = 'Please select a category';
      });
      return;
    }
    if (_selectedType == null) {
      setState(() {
        _error = 'Please select a type';
      });
      return;
    }
    if (_selectedRegion == null) {
      setState(() {
        _error = 'Please select a region';
      });
      return;
    }

    // Ensure at least one image
    if (_newImages.isEmpty) {
      setState(() {
        _error = 'Please upload at least one image.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create mode: include all required fields
      final Map<String, String> fields = {};
      fields['category'] = _selectedCategory!;
      fields['type'] = _selectedType!;
      fields['amount'] = _amountCtrl.text.trim();
      fields['explanation'] = _explanationCtrl.text.trim();
      fields['region'] = _selectedRegion!;
      fields['district'] = _districtCtrl.text.trim();
      fields['street'] = _streetCtrl.text.trim();
      fields['room_no'] = _roomNoCtrl.text.trim();

      await ApiService.postMultipart(
        path: '/api/user/post',
        fields: fields,
        files: _newImages,
        fieldName: 'images[]',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post created successfully!'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        // Clear form after successful submission
        _formKey.currentState!.reset();
        setState(() {
          _newImages.clear();
          _selectedCategory = null;
          _selectedType = null;
          _selectedRegion = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.body is Map) {
            _error = (e.body['message']?.toString() ?? e.body.toString());
          } else {
            _error = e.body.toString();
          }
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.home_2, color: kPrimaryBlue, size: 28),
            const SizedBox(width: 12),
            Text(
              'Create House Post',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: kPrimaryBlue, 
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Fill in the details to list your property for rent or sale.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Row(
        children: [
          Icon(Iconsax.warning_2, color: Colors.red[400]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: kPrimaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2.0), // Blue focus border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[700]!, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownInput({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        validator: validator,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: kPrimaryBlue),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryBlue, width: 2.0), // Blue focus border
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[700]!, width: 2.0),
          ),
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.gallery_add, color: kPrimaryBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Property Images (Max 3)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kPrimaryBlue, 
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ..._newImages.asMap().entries.map((entry) {
              final index = entry.key;
              final pf = entry.value;
              return GestureDetector(
                onTap: () => _openImagePreview(pf),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        pf.bytes!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeNewImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[500],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            if (_newImages.length < 3) _buildAddImageBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildAddImageBox() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: kPrimaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kPrimaryBlue.withOpacity(0.3), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add, size: 20, color: kPrimaryBlue),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: TextStyle(fontSize: 10, color: kPrimaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryBlue, // Blue button
          foregroundColor: Colors.white, // Ensures white text on blue button
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4, // Slightly raised button
        ),
        child: _loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Creating post...'),
                ],
              )
            : const Text(
                'Publish Listing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gethouse Post a House',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        // Applied Blue theme to AppBar
        backgroundColor: kPrimaryBlue, 
        foregroundColor: Colors.white,
        elevation: 4, 
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[50],
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 800 : 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 6, // Increased elevation for better depth
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        
                        if (_error != null) ...[
                          _buildErrorMessage(_error!),
                          const SizedBox(height: 20),
                        ],
                        
                        // Responsive layout
                        if (isDesktop) _buildDesktopLayout() else _buildMobileLayout(),
                        
                        const SizedBox(height: 20),
                        _buildImageUploadSection(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper function for Desktop layout (already structured well)
  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // ROW 1: Category & Type
        Row(
          children: [
            Expanded(
              child: _buildDropdownInput(
                label: 'Category',
                hint: 'Select category',
                icon: Iconsax.category,
                value: _selectedCategory,
                items: _categories,
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (v) => v == null ? 'Category required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownInput(
                label: 'Type',
                hint: 'Select type',
                icon: Iconsax.tag,
                value: _selectedType,
                items: _types,
                onChanged: (value) => setState(() => _selectedType = value),
                validator: (v) => v == null ? 'Type required' : null,
              ),
            ),
          ],
        ),
        
        // ROW 2: Amount & Room No
        Row(
          children: [
            Expanded(
              child: _buildTextInput(
                controller: _amountCtrl,
                label: 'Amount (in TSH)',
                hint: 'Enter price',
                icon: Iconsax.money,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Amount required';
                  if (double.tryParse(v) == null) return 'Invalid number';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextInput(
                controller: _roomNoCtrl,
                label: 'Rooms (Optional)',
                hint: 'e.g., 3',
                icon: Iconsax.buildings,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        
        // Explanation field
        _buildTextInput(
          controller: _explanationCtrl,
          label: 'Description',
          hint: 'Describe your property, features, and amenities.',
          icon: Iconsax.note,
          maxLines: 3,
          validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
        ),
        
        // ROW 3: Region & District
        Row(
          children: [
            Expanded(
              child: _buildDropdownInput(
                label: 'Region',
                hint: 'Select region',
                icon: Iconsax.map,
                value: _selectedRegion,
                items: _tanzaniaRegions,
                onChanged: (value) => setState(() => _selectedRegion = value),
                validator: (v) => v == null ? 'Region required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextInput(
                controller: _districtCtrl,
                label: 'District',
                hint: 'e.g., Kinondoni',
                icon: Iconsax.location,
                validator: (v) => (v == null || v.isEmpty) ? 'District required' : null,
              ),
            ),
          ],
        ),
        
        // Street field
        _buildTextInput(
          controller: _streetCtrl,
          label: 'Street (Optional)',
          hint: 'Enter street name or landmark',
          icon: Iconsax.route_square,
        ),
      ],
    );
  }

  // Helper function for Mobile layout (already structured well)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildDropdownInput(
          label: 'Category',
          hint: 'Select category',
          icon: Iconsax.category,
          value: _selectedCategory,
          items: _categories,
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (v) => v == null ? 'Category required' : null,
        ),
        
        _buildDropdownInput(
          label: 'Type',
          hint: 'Select type',
          icon: Iconsax.tag,
          value: _selectedType,
          items: _types,
          onChanged: (value) => setState(() => _selectedType = value),
          validator: (v) => v == null ? 'Type required' : null,
        ),
        
        _buildTextInput(
          controller: _amountCtrl,
          label: 'Amount (in TSH)',
          hint: 'Enter price',
          icon: Iconsax.money,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Amount required';
            if (double.tryParse(v) == null) return 'Invalid number';
            return null;
          },
        ),
        
        _buildTextInput(
          controller: _roomNoCtrl,
          label: 'Rooms (Optional)',
          hint: 'e.g., 3',
          icon: Iconsax.buildings,
          keyboardType: TextInputType.number,
        ),
        
        _buildTextInput(
          controller: _explanationCtrl,
          label: 'Description',
          hint: 'Describe your property, features, and amenities.',
          icon: Iconsax.note,
          maxLines: 3,
          validator: (v) => (v == null || v.isEmpty) ? 'Description is required' : null,
        ),
        
        _buildDropdownInput(
          label: 'Region',
          hint: 'Select region',
          icon: Iconsax.map,
          value: _selectedRegion,
          items: _tanzaniaRegions,
          onChanged: (value) => setState(() => _selectedRegion = value),
          validator: (v) => v == null ? 'Region required' : null,
        ),
        
        _buildTextInput(
          controller: _districtCtrl,
          label: 'District',
          hint: 'e.g., Kinondoni',
          icon: Iconsax.location,
          validator: (v) => (v == null || v.isEmpty) ? 'District required' : null,
        ),
        
        _buildTextInput(
          controller: _streetCtrl,
          label: 'Street (Optional)',
          hint: 'Enter street name or landmark',
          icon: Iconsax.route_square,
        ),
      ],
    );
  }
}