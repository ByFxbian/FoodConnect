import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodconnect/widgets/taste_profile_sheet.dart';
import 'package:foodconnect/widgets/primary_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Orte entdecken',
      'description':
          'Finde die besten Restaurants, Cafés und Bars in deiner Nähe und entdecke neue Geheimtipps.',
      'icon': Icons.explore_rounded,
    },
    {
      'title': 'Listen erstellen',
      'description':
          'Speichere deine Lieblingsorte in persönlichen Listen und verliere nie wieder den Überblick.',
      'icon': Icons.view_list_rounded,
    },
    {
      'title': 'Teile den Geschmack',
      'description':
          'Teile deine Empfehlungen mit Freunden und entdecke, wo andere am liebsten essen gehen. Dein Kulinarik-Netzwerk.',
      'icon': Icons.people_alt_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      context.go('/explore');

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      TasteProfileSheet.show(context, dismissible: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_seen_onboarding', true);
                  if (context.mounted) context.go('/explore');
                },
                child: Text(
                  'Überspringen',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon Container
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _pages[index]['icon'],
                            size: 64,
                            color: theme.primaryColor,
                          ),
                        )
                            .animate()
                            .scale(delay: 200.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 60),
                        Text(
                          _pages[index]['title'],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 24),
                        Text(
                          _pages[index]['description'],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.primaryColor
                              : theme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 40),
                  // Next / Start Button
                  PrimaryButton(
                    buttonLabel: _currentPage == _pages.length - 1
                        ? 'Starten'
                        : 'Weiter',
                    pressAction: () async {
                      _onNext();
                    },
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
