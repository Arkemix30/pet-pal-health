import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_provider.dart';
import 'auth_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  // Changed to ConsumerWidget
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header / Logo Area
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.pets,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PetCare Brain',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            // Hero Illustration Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCohgFYVnqiShVYAA98o66XC9YNiqJAgYDEuy1b6HKvn7342XBJx9J5FEqiMYtLSknpMa44scygKHKV8tfHFe-lkmbb13e8dgVphzjIqt_JGxrGIQvpiaE_9GJNvPxkrZctv5pb7rtIMicWJnUTkroGS6exXkoCg7t_-B97c6eL-jpTgJRpoEPdXhtd4v7bFpdfZoAfgfTTJRzGNvM83zIKr2vNAp1biEIXor2OIvxTPhvLxTq2600-qzzY6tZX2sIkkp3kEAFAieE',
                                    fit: BoxFit.cover,
                                  )
                                  .animate()
                                  .fadeIn(duration: 800.ms)
                                  .scale(
                                    begin: const Offset(1.1, 1.1),
                                    end: const Offset(1.0, 1.0),
                                    curve: Curves.easeOut,
                                  ),
                              // Gradients
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.scaffoldBackgroundColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      Colors.transparent,
                                      theme.scaffoldBackgroundColor.withValues(
                                        alpha: 0.9,
                                      ),
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Vaccine Tag Overlay
                      Positioned(
                        top: 24,
                        right: 24,
                        child:
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? theme.colorScheme.surface.withValues(
                                            alpha: 0.8,
                                          )
                                        : Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 8,
                                        width: 8,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Vaccine due',
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .shimmer(delay: 2000.ms, duration: 1500.ms),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Text Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      children: [
                        const TextSpan(text: 'Never Miss a\n'),
                        TextSpan(
                          text: 'Vet Visit',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'The all-in-one health memory for your furry friends. Keep track of meds, vaccines, and habits effortlessly.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey[400]
                          : const Color(0xFF64748B),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),

            // Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 8,
                    width: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(onboardingStateProvider.notifier)
                            .completeOnboarding(); // Added line
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AuthScreen(initialIsLogin: false),
                          ),
                        );
                      },
                      child: const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: TextButton(
                      onPressed: () {
                        ref
                            .read(onboardingStateProvider.notifier)
                            .completeOnboarding(); // Added line
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AuthScreen(initialIsLogin: true),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? theme.colorScheme.primary
                              : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'By continuing, you agree to our Terms & Privacy Policy',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
