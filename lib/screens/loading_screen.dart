
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _dotsAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<int> _dotsAnimation;

  @override
  void initState() {
    super.initState();

    // Logo Animation Controller
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Scale Animation for Logo
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.easeInOut),
    );

    // Opacity Animation for Text
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.easeInOut),
    );

    // Dots Animation Controller
    _dotsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();

    // Dots Animation
    _dotsAnimation = IntTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _dotsAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _dotsAnimationController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: _buildLoadingContent(),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return AnimatedBuilder(
      animation: _dotsAnimationController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedLogo(),
            SizedBox(height: 30),
            _buildLoadingText(),
            SizedBox(height: 30),
            _buildLoadingIndicator(),
          ],
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 60,
      width: 60,
      child: CircularProgressIndicator.adaptive(
        strokeWidth: 6,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

 Widget _buildLoadingText() {
  String dots = "";
  for (int i = 0; i < _dotsAnimation.value; i++) {
    dots += ".";
  }
  return AnimatedOpacity(
    opacity: _opacityAnimation.value,
    duration: Duration(milliseconds: 500),
    child: Text(
      "Restaurants werden geladen$dots",
      style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface),
    ),
  );
}
  Widget _buildAnimatedLogo() {
        return ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          'assets/app_icon_vertical_text.png',
          width: 300,
          fit: BoxFit.contain,
        ),
      );
  }
}
