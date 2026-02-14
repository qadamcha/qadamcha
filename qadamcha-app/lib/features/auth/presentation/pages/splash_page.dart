import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import 'role_selection_page.dart';
import 'phone_page.dart';

/// Splash Screen - matching full_architecture.html design
/// Gradient: #2D6A9F → #7C4DFF → #FF4081
/// Decorative circles, loading animation, emoji logo
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // Check auth status after animation starts
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<AuthBloc>().add(CheckAuthStatusEvent());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateBasedOnAuthStatus(AuthStatus status) {
    if (status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    } else if (status == AuthStatus.unauthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated ||
            state.status == AuthStatus.unauthenticated) {
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              _navigateBasedOnAuthStatus(state.status);
            }
          });
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.splashGradient,
          ),
          child: Stack(
            children: [
              // Decorative circle top-right
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              // Decorative circle bottom-left
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              // Main content
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo container with emoji
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 32,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '👨‍👩‍👧‍👦',
                                  style: TextStyle(fontSize: 44),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // App name
                            const Text(
                              'Oilaviy',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Nunito',
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Tagline
                            Text(
                              'Farzandingiz uchun eng yaxshi ilova',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Loading indicator at bottom
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        value: null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
