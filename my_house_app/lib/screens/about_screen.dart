import 'package:flutter/material.dart';
import 'package:my_house_app/widgets/app_drawer.dart';
import '../widgets/navbar.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      appBar: const NavBar(),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0077B6).withOpacity(0.05),
              const Color(0xFF00B4D8).withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 24, 
                vertical: 40
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animated Header Section
                  _buildHeaderSection(context, isDesktop),
                  const SizedBox(height: 40),
                  
                  // Mission Statement Card with animation
                  _buildMissionCard(context, isDesktop),
                  const SizedBox(height: 40),
                  
                  // Call to Action
                  _buildCTASection(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        // Animated logo/icon
       
        
        // Title with gradient
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF00B4D8)],
          ).createShader(bounds),
          child: Text(
            'About Gethouse 🏠',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 42 : 32,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'Your trusted platform for finding a house and connecting with agents. '
          'Making your dream home a reality! ✨',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 20 : 16,
            color: Colors.grey[700],
            height: 1.5,
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildMissionCard(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF0FBFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with animation
          Container(
            width: isDesktop ? 80 : 60,
            height: isDesktop ? 80 : 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00B4D8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              size: 40,
              color: Color(0xFF00B4D8),
            ),
          )
          .animate()
          .scale(delay: 500.ms, duration: 600.ms),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission 🌟',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0077B6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gethouse ni platform ya nyumba za kukodisha na agents. '
                  'Inawawezesha watumiaji kuposti nyumba, kuwasiliana, na kuangalia agents waliothibitishwa.',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    height: 1.5,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(delay: 600.ms, duration: 600.ms)
    .slide(begin: const Offset(0, 0.2), curve: Curves.easeOut);
  }



  Widget _buildCTASection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), const Color(0xFF0077B6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to find your dream home? 🏡',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join thousands of satisfied users who found their perfect property through Gethouse',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context,'/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0077B6),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
            ),
            child: const Text(
              'Get Started Today',
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
    .fadeIn(delay: 1800.ms, duration: 800.ms)
    .slide(begin: const Offset(0, 0.2), curve: Curves.easeOut);
  }
}