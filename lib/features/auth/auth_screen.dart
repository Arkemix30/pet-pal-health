import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/ui/overlays/overlay_manager.dart';
import 'auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool initialIsLogin;
  const AuthScreen({super.key, this.initialIsLogin = true});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isLogin;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  void _toggleMode(bool isLogin) {
    if (_isLogin == isLogin) return;
    setState(() {
      _isLogin = isLogin;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: e.message,
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayManager.showToast(
          context,
          message: 'An unexpected error occurred. Please try again.',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    // Header Image & Branding
                    Column(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.2,
                              ),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Pet Pal Health',
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 8),
                        Text(
                          'Your pet\'s health, simplified.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF64748B),
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Segmented Control / Tabs
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A3222)
                            : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(true),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _isLogin
                                      ? (isDark
                                            ? const Color(0xFF244730)
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _isLogin
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Log In',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _isLogin
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                        : (isDark
                                              ? const Color(0xFF93C8A5)
                                              : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _toggleMode(false),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: !_isLogin
                                      ? (isDark
                                            ? const Color(0xFF244730)
                                            : Colors.white)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: !_isLogin
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: !_isLogin
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A))
                                        : (isDark
                                              ? const Color(0xFF93C8A5)
                                              : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 24),

                    // Form Fields
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isLogin) ...[
                          _buildLabel('Full Name'),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Your names',
                            icon: Icons.person_outline,
                            animateDelay: 500.ms,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildLabel('Email Address'),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'user@example.com',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          animateDelay: 600.ms,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Password'),
                        _buildTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFF93C8A5)
                                  : const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          animateDelay: 700.ms,
                        ),
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Primary Action Button
                    Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF112116),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _isLogin
                                            ? 'Get Started'
                                            : 'Create Account',
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 900.ms)
                        .scale(begin: const Offset(0.9, 0.9)),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF346544)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or continue with',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF93C8A5)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark
                                ? const Color(0xFF346544)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms),

                    const SizedBox(height: 24),

                    // Social Login Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildSocialButton(
                            'Google',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCS7QQ1Xzzza5qjBwmcb2l05oC3qFXxCed4xDtQhLJ445s_JOC86lYT7-rEVt5xI_dxnQxMZ1Q6c40EPUkQwaz7NJUCBBkSHqVDSEO5ZuZeNzF6Q7x1O0E3vHoxqHDuNmqtCl-bhvd2D0xZ2QZir75AsuqMjxDfrO4p2WDCcrpq_9Rj5pAXvRZMFSOm6apyLtnctB482X3AJ4Ox6JIXW9_qsm0rcRaSFGP70ldstPtbGrkehKvCLkAfsW6KJFFCMBO1rCtiWTUwpmI',
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSocialButton(
                            'Apple',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuC6CklbO75m6bwsxenQuMpP5iuWE5xmR5D36ljREH2-f_9RFyexfSugy1slbPiotMzrfJzQP-OdypyarWzOBgegezVD2-iEiA7dNZxNIIuGlt1rK5Qf5pmqYb6YMHCGgtVerZgZoCk7AGXqDa_OBpQYKf_nP3fxSu6IjcFnJenpb8tymSMLEFOKlXCVKGs6LwQN8SbtDn6jeT1u_4tYKfFLDNVSLwl3vi-2WCakuKKSMjZ7H3z61soeK1-4SOxzx6qdSzlnMPPDTLU',
                            isDark,
                            invert: isDark,
                          ),
                        ),
                      ],
                    ).animate(delay: 1100.ms).fadeIn().slideY(begin: 0.1, end: 0),

                    const Spacer(flex: 2),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Text(
                        'By continuing, you agree to our Terms of Service and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF5D856B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1200.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    required Duration animateDelay,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF93C8A5) : const Color(0xFF94A3B8),
        ),
        suffixIcon: suffix,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        return null;
      },
    ).animate().fadeIn(delay: animateDelay).slideX(begin: -0.05, end: 0);
  }

  Widget _buildSocialButton(
    String label,
    String imageUrl,
    bool isDark, {
    bool invert = false,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A3222) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF346544) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                imageUrl,
                width: 20,
                height: 20,
                color: invert ? Colors.white : null,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
