import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:iconsax/iconsax.dart';
import 'package:my_house_app/widgets/app_drawer.dart';

class NavBar extends StatefulWidget implements PreferredSizeWidget {
  const NavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late Animation<Color?> _logoColorAnimation;
  
  late AnimationController _taglineController;
  late Animation<double> _taglineScaleAnimation;
  late Animation<double> _taglineOpacityAnimation;
  
  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOutSine),
    );
    
    _logoColorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.95),
      end: Colors.white.withOpacity(0.8),
    ).animate(_logoController);

    // Tagline animation
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _taglineScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeInOutSine),
    );
    
    _taglineOpacityAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeInOutSine),
    );

    // Button animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        
        // Sign Up Button
        _buildElevatedButton(context, 'Sign Up', '/signup'),
        
        const SizedBox(width: 12),
        
        // Sign In Button
        _buildOutlinedButton(context, 'Sign In', '/signin'),
      ],
    );
  }

  Widget _buildElevatedButton(BuildContext context, String text, String routeName) {
    return MouseRegion(
      onEnter: (_) => _buttonController.forward(),
      onExit: (_) => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A11CB).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, routeName),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.user_add, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, String text, String routeName) {
    return MouseRegion(
      onEnter: (_) => _buttonController.forward(),
      onExit: (_) => _buttonController.reverse(),
      child: ScaleTransition(
        scale: _buttonScaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, routeName),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.login, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 700;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.8],
          tileMode: TileMode.mirror,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AppBar(
        title: MouseRegion(
          onEnter: (_) => _logoController.forward(),
          onExit: (_) => _logoController.reverse(),
          child: ScaleTransition(
            scale: _logoScaleAnimation,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _logoColorAnimation,
                  builder: (context, child) {
                    return Icon(
                      Iconsax.house_2,
                      color: _logoColorAnimation.value,
                      size: 32,
                    );
                  },
                ),
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _logoColorAnimation,
                  builder: (context, child) {
                    return Text(
                      'Gethouse',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        color: _logoColorAnimation.value,
                        letterSpacing: 1.8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isSmall) _buildActions(context),
          if (isSmall)
            Builder(builder: (ctx) {
              return MouseRegion(
                onEnter: (_) => _buttonController.forward(),
                onExit: (_) => _buttonController.reverse(),
                child: ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                   
                  ),
                ),
              );
            }),
        ],
        centerTitle: false,
      ),
    );
  }
}