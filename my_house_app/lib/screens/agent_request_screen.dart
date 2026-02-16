import 'package:flutter/material.dart';
import 'package:hashids2/hashids2.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/navigation_service.dart';

class AgentRequestScreen extends StatefulWidget {
  const AgentRequestScreen({super.key});

  @override
  State<AgentRequestScreen> createState() => _AgentRequestScreenState();
}

class _AgentRequestScreenState extends State<AgentRequestScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _specializationController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _userId;
  bool _agreedToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final HashIds _hashIds = HashIds(
    salt: 'my_house_app_salt', // Must match across the app
    minHashLength: 8,
    alphabet: 'abcdefghijklmnopqrstuvwxyz1234567890',
  );

  // List of Tanzanian regions
  static const List<String> tanzanianRegions = [
    'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa', 'Kagera', 'Katavi',
    'Kigoma', 'Kilimanjaro', 'Lindi', 'Manyara', 'Mara', 'Mbeya', 'Morogoro',
    'Mtwara', 'Mwanza', 'Njombe', 'Pemba North', 'Pemba South', 'Pwani', 'Rukwa',
    'Ruvuma', 'Shinyanga', 'Simiyu', 'Singida', 'Songwe', 'Tabora', 'Tanga',
    'Zanzibar North', 'Zanzibar South and Central', 'Zanzibar West',
  ];

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
    _fetchUserId();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _specializationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserId() async {
    try {
      _userId = await AuthService.getUserId();
      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch user ID: $e';
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || !_agreedToTerms) {
      if (!_agreedToTerms) {
        setState(() {
          _error = 'You must agree to the terms and conditions';
        });
      }
      return;
    }

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
            'Confirm Submission',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
          ),
          content: const Text('Are you sure you want to submit your agent application?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final encodedUserId = _userId != null ? _hashIds.encode(int.parse(_userId!)) : null;
      final fields = {
        'agent_name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'experience': _experienceController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'user_id': encodedUserId,
      };

      await ApiService.postJson('/api/agent/requests', fields);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agent request submitted successfully!'),
          backgroundColor: Color(0xFF1976D2),
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          NavigationService.navigateToReplacement('/user-dashboard');
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.body?.toString() ?? 'Submission failed. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A202C)),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'By applying to become a real estate agent, you agree to:\n\n'
            '1. Provide accurate and truthful information.\n'
            '2. Comply with all applicable laws and regulations in Tanzania.\n'
            '3. Allow us to verify your details and contact you for further information.\n'
            '4. Maintain professionalism in all dealings with clients.\n\n'
            'We reserve the right to reject applications that do not meet our standards.',
            style: TextStyle(fontSize: 14, color: Color(0xFF1A202C)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF1976D2))),
          ),
        ],
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
          'Become a Real Estate Agent',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFD), Color(0xFFE8EBF5)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? screenWidth * 0.1 : 16,
            vertical: 24,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Agent Application',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A202C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fill out the form below to apply as a real estate agent. Our team will review your application and get back to you soon.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF1976D2)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your full name';
                                }
                                if (value.trim().length < 3) {
                                  return 'Name must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _regionController.text.isEmpty ? null : _regionController.text,
                              decoration: InputDecoration(
                                labelText: 'Region/Area of Operation',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.location_on_rounded, color: Color(0xFF1976D2)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              items: tanzanianRegions.map((region) {
                                return DropdownMenuItem<String>(
                                  value: region,
                                  child: Text(region),
                                );
                              }).toList(),
                              onChanged: (value) {
                                _regionController.text = value ?? '';
                              },
                              validator: (value) => value == null ? 'Please select a region' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF1976D2)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (!value.startsWith('+255') || !RegExp(r'^\+255[0-9]{9}$').hasMatch(value)) {
                                  return 'Phone number must start with +255 and be 12 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _experienceController,
                              decoration: InputDecoration(
                                labelText: 'Experience (Years)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.work_rounded, color: Color(0xFF1976D2)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your experience';
                                }
                                if (int.tryParse(value) == null || int.parse(value) < 0) {
                                  return 'Please enter a valid number of years';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _specializationController,
                              decoration: InputDecoration(
                                labelText: 'Specialization',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFF1976D2)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your specialization';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_error != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: const TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_error != null) const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _agreedToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreedToTerms = value ?? false;
                                      if (_agreedToTerms && _error == 'You must agree to the terms and conditions') {
                                        _error = null;
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF1976D2),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: _showTermsDialog,
                                    child: const Text(
                                      'I agree to the Terms and Conditions',
                                      style: TextStyle(
                                        color: Color(0xFF1976D2),
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _submit,
                                icon: const Icon(Icons.send_rounded, size: 20),
                                label: Text(
                                  _loading ? 'Submitting...' : 'Submit Application',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1976D2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'By submitting this form, you agree to our terms and conditions. We may contact you for additional information.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
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
}
