import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'jigsaw_intro_screen.dart';

class JigsawSplashScreen extends StatefulWidget {
  const JigsawSplashScreen({super.key});

  @override
  State<JigsawSplashScreen> createState() => _JigsawSplashScreenState();
}

class _JigsawSplashScreenState extends State<JigsawSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Switch to landscape for jigsaw puzzle
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller = AnimationController(vsync: this);
  }

  void _restorePortrait() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _restorePortrait();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
                'assets/animations/loader_puzzle.json',
                controller: _controller,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    ..forward().whenComplete(() {
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const JigsawIntroScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            transitionDuration: const Duration(milliseconds: 800),
                          ),
                        );
                      }
                    });
                },
                errorBuilder: (context, error, stackTrace) {
                  // If Lottie not found, skip to intro after delay
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const JigsawIntroScreen()),
                      );
                    }
                  });
                  return const CircularProgressIndicator();
                },
              ),
            ),
        ),
      ),
    );
  }
}
