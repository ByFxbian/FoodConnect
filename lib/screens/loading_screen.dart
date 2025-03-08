
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingScreen extends StatefulWidget {
  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    return AnimatedOpacity(
      opacity: _opacityAnimation.value,
      duration: Duration(milliseconds: 500),
      child: Text(
      "Einen Moment bitte...",
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
      );
  }
  Widget _buildAnimatedLogo() {
    return ScaleTransition(
        scale: _scaleAnimation,
        child: Image.asset(
          'assets/app_icon.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
    );
  }
}
