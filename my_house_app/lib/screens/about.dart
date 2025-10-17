import 'package:flutter/material.dart';
import 'package:my_house_app/widgets/app_drawer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

// --- Blue Color Constants ---
const Color _primaryBlue = Color(0xFF1E88E5); // Material Blue 600 - Main Accent
const Color _deepBlue = Color(0xFF2575FC); // Deeper Blue - Used in gradients
const Color _darkText = Color(0xFF2D3748); // Consistent Dark Text Color

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Gethouse Developer 👨‍💻',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        // --- Updated: Blue AppBar Background ---
        backgroundColor: const Color.fromARGB(255, 57, 30, 229),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          // --- Updated: Blue Gradient Background ---
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 176, 30, 229).withOpacity(0.8),
              _deepBlue.withOpacity(0.6),
              Colors.white.withOpacity(0.9),
            ],
            stops: const [0.0, 0.3, 0.7],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 30 : 20),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Developer Profile with animation
                  _buildDeveloperProfile(context, isDesktop),
                  const SizedBox(height: 30),
                
                  // Contact Section
                  _buildContactSection(context, isDesktop),
                  const SizedBox(height: 30),
                  
                  // Projects Section
                  _buildProjectsSection(context, isDesktop),
                  const SizedBox(height: 30),
                  
                  // Footer
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperProfile(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // --- Updated: Blue Shadow ---
            color: Colors.blue.withOpacity(0.2), 
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Profile Image
          Container(
            width: isDesktop ? 150 : 120,
            height: isDesktop ? 150 : 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // --- Updated: Blue Profile Gradient ---
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryBlue, _deepBlue],
              ),
              boxShadow: [
                BoxShadow(
                  // --- Updated: Blue Shadow ---
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.white,
            ),
          )
          .animate()
          .scale(duration: 600.ms)
          .then(delay: 200.ms)
          .shake(duration: 400.ms),
          
          const SizedBox(height: 20),
          
          // Developer Name
          const Text(
            'Hafidhi Mkori',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _darkText,
            ),
          )
          .animate()
          .fadeIn(delay: 300.ms, duration: 600.ms),
          
          const SizedBox(height: 8),
          
          // Title
          const Text(
            'Flutter Developer & UI/UX Designer 🎨',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 400.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Divider
          Divider(
            color: Colors.grey[300],
            height: 1,
            thickness: 1,
          )
          .animate()
          .fadeIn(delay: 500.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // About Section
          const Text(
            'About Me 🙋‍♂️',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          )
          .animate()
          .fadeIn(delay: 600.ms, duration: 600.ms),
          
          const SizedBox(height: 12),
          
          const Text(
            'I am a passionate Flutter developer with expertise in creating '
            'beautiful and functional mobile applications. With over 3 years '
            'of experience in mobile development, I specialize in building '
            'cross-platform apps that deliver exceptional user experiences.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fadeIn(delay: 700.ms, duration: 600.ms),
        ],
      ),
    )
    .animate()
    .slide(begin: const Offset(0, 0.2), duration: 600.ms);
  }


  Widget _buildContactSection(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // --- Updated: Blue Shadow ---
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Get In Touch 📞',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          )
          .animate()
          .fadeIn(delay: 1200.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          // Contact Info
          _buildContactInfo(
            Icons.email,
            'Email',
            'mkorihafidhi67@gmail.com',
            onTap: () => _launchEmail('mkorihafidhi67@gmail.com'),
            delay: const Duration(milliseconds: 1300),
          ),
          const SizedBox(height: 16),
          
          _buildContactInfo(
            Icons.phone,
            'Phone',
            '+255 785 226 584',
            onTap: () => _launchPhone('+255785226584'),
            delay: const Duration(milliseconds: 1400),
          ),
          const SizedBox(height: 16),
          
          _buildContactInfo(
            Icons.location_on,
            'Location',
            'Dodoma, Tanzania',
            delay: const Duration(milliseconds: 1500),
          ),
          const SizedBox(height: 20),
          
          // WhatsApp Button (Arrangement Improvement: ConstrainedBox for better desktop scaling)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 350 : double.infinity, // Set max width for desktop
            ),
            child: ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(context, '+255785226584'),
              style: ElevatedButton.styleFrom(
                // --- Updated: Primary Blue Button Color ---
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
                // --- Updated: Deep Blue Shadow ---
                shadowColor: _deepBlue.withOpacity(0.5),
              ),
              icon: const Icon(Icons.chat, size: 24),
              label: const Text(
                'Chat on WhatsApp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .animate()
          .scale(delay: 1600.ms, duration: 600.ms),
        ],
      ),
    )
    .animate()
    .slide(begin: const Offset(0, 0.2), delay: 1200.ms, duration: 600.ms);
  }

  Widget _buildContactInfo(IconData icon, String title, String value, {VoidCallback? onTap, Duration delay = Duration.zero}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            // --- Updated: Blue Icon Background ---
            color: _primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          // --- Updated: Blue Icon Color ---
          child: Icon(icon, color: _primaryBlue),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: _darkText,
          ),
        ),
        subtitle: Text(value),
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        trailing: onTap != null 
          ? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
          : null,
      ),
    )
    .animate()
    .fadeIn(delay: delay, duration: 600.ms)
    .slide(begin: const Offset(0.2, 0), duration: 400.ms);
  }

  Widget _buildProjectsSection(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // --- Updated: Blue Shadow ---
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Recent Projects 🚀',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _darkText,
            ),
          )
          .animate()
          .fadeIn(delay: 1700.ms, duration: 600.ms),
          
          const SizedBox(height: 20),
          
          _buildProjectItem(
            'Grain App',
            'Apllication that helps farmers to connect with thier customers',
            Icons.house_rounded,
            delay: const Duration(milliseconds: 1800),
          ),
          const SizedBox(height: 16),
          
          _buildProjectItem(
            'Civehub.store',
            'Studend platform for accademic share issues at university of Dodoma',
            Icons.shopping_cart_rounded,
            delay: const Duration(milliseconds: 1900),
          ),
          const SizedBox(height: 16),
          
          _buildProjectItem(
            'Mikangaula.store',
            'The platform that allowa users to interact with the custormers to sell their products',
            Icons.fitness_center_rounded,
            delay: const Duration(milliseconds: 2000),
          ),
        ],
      ),
    )
    .animate()
    .slide(begin: const Offset(0, 0.2), delay: 1700.ms, duration: 600.ms);
  }

  Widget _buildProjectItem(String title, String description, IconData icon, {Duration delay = Duration.zero}) {
    return Container(
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
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              // --- Updated: Blue Icon Background ---
              color: _primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            // --- Updated: Blue Icon Color ---
            child: Icon(icon, color: _primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // --- Updated: Blue Footer Gradient ---
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryBlue, _deepBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // --- Updated: Blue Shadow ---
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Let\'s work together to bring your ideas to life! 💡',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'I\'m available for freelance work and new opportunities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _launchEmail('mkorihafidhi67@gmail.com'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              // --- Updated: Blue Button Text Color ---
              foregroundColor: _primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text(
              'Get In Touch',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 2100.ms, duration: 800.ms)
    .slide(begin: const Offset(0, 0.2), curve: Curves.easeOut);
  }

  void _launchWhatsApp(BuildContext context, String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
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

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchPhone(String phone) async {
    final url = 'tel:$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}