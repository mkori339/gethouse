import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:iconsax/iconsax.dart'; // Added Iconsax for consistent design
import '../models/agent.dart';


class AgentCard extends StatelessWidget {
  final Agent agent;
  const AgentCard({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Card(
      elevation: 4, // Increased elevation for better depth
      margin: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8, horizontal: isMobile ? 8 : 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          // Use a subtle white gradient for a clean look
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFD)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Avatar
                    // _buildAvatar(),
                    // const SizedBox(height: 12),

                    // Agent Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name
                        Text(
                          agent.agentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A202C),
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 6),

                        // Primary details: Region and Phone
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _buildInfoChip(
                              icon: Iconsax.location,
                              value: agent.region,
                              iconColor: const Color(0xFF1976D2),
                            ),
                            _buildInfoChip(
                              icon: Iconsax.call,
                              value: agent.phone,
                              iconColor: Colors.teal,
                            ),
                          ],
                        ),
                        // const SizedBox(height: 8),

                        // // Secondary details: Rating and Houses Count
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     _buildStatItem(
                        //       icon: Iconsax.star5,
                        //       value: '3.0',
                        //       color: Colors.amber,
                        //     ),
                        //     const SizedBox(width: 16),
                        //     _buildStatItem(
                        //       icon: Iconsax.home_hashtag,
                        //       value: '5',
                        //       color: const Color(0xFF2575FC),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),

                    // WhatsApp Button
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: _buildWhatsAppButton(context)),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Avatar
                    // _buildAvatar(),
                    // const SizedBox(width: 16),

                    // Agent Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            agent.agentName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A202C),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),

                          // Primary details: Region and Phone
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              _buildInfoChip(
                                icon: Iconsax.location,
                                value: agent.region,
                                iconColor: const Color(0xFF1976D2),
                              ),
                              _buildInfoChip(
                                icon: Iconsax.call,
                                value: agent.phone,
                                iconColor: Colors.teal,
                              ),
                            ],
                          ),
                          // const SizedBox(height: 10),

                          // Secondary details: Rating and Houses Count
                          // Row(
                          //   children: [
                          //     _buildStatItem(
                          //       icon: Iconsax.star5,
                          //       value: '3.0', // Using hardcoded value from original code
                          //       color: Colors.amber,
                          //     ),
                          //     const SizedBox(width: 20),
                          //     _buildStatItem(
                          //       icon: Iconsax.home_hashtag,
                          //       value: '5', // Using hardcoded value from original code
                          //       color: const Color(0xFF2575FC),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    // WhatsApp Button
                    _buildWhatsAppButton(context),
                  ],
                ),
        ),
      ),
    );
  }

  /// Builds the agent's profile avatar.
  // Widget _buildAvatar() {
  //   return Container(
  //     width: 60,
  //     height: 60,
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       gradient: const LinearGradient(
  //         colors: [Color(0xFF1976D2), Color(0xFF2575FC)],
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF1976D2).withOpacity(0.4),
  //           blurRadius: 8,
  //           offset: const Offset(0, 4),
  //         )
  //       ],
  //     ),
  //     child: Center(
  //       child: Text(
  //         agent.agentName.isNotEmpty ? agent.agentName[0].toUpperCase() : 'A',
  //         style: const TextStyle(
  //           fontSize: 24,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.white,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  /// Builds a small chip for primary agent information.
  Widget _buildInfoChip({
    required IconData icon,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: iconColor.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a small item for statistical information (rating, houses count).
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Builds the WhatsApp contact button.
  Widget _buildWhatsAppButton(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return InkWell(
      onTap: () => _launchWhatsApp(context, agent.phone),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 10, horizontal: isMobile ? 8 : 12),
        decoration: BoxDecoration(
          color: Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 41, 147, 229).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat, color: Colors.white, size: isMobile ? 20 : 24),
            if (!isMobile) const SizedBox(height: 4),
            if (!isMobile)
              Text(
                "Chat",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              )
          ],
        ),
      ),
    );
  }

  /// Launches WhatsApp with the agent's phone number.
  void _launchWhatsApp(BuildContext context, String phone) async {
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      // Added error handling similar to the previous file
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
}