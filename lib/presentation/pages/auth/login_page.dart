import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:logger/logger.dart';

/// Login/Sign In Screen
/// Email and password authentication
class LoginPage extends StatefulWidget {
  /// Callback when login is successful
  final VoidCallback onLoginSuccess;

  /// Callback to navigate to signup
  final VoidCallback onNavigateToSignup;

  const LoginPage({
    Key? key,
    required this.onLoginSuccess,
    required this.onNavigateToSignup,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Logger _logger = Logger();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    // Clear previous errors
    setState(() => _errorMessage = null);

    // Validate inputs
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter both email and password',
      );
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _logger.i('🔐 Attempting login for: $email');

      await SupabaseConfig.signIn(
        email: email,
        password: password,
      );

      _logger.i('✅ Login successful');

      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      _logger.e('❌ Login failed: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Invalid login credentials')
              ? 'Invalid email or password'
              : 'Login failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top spacing
              SizedBox(height: AppSpacing.massive),

              // Title
              Text(
                'Welcome Back',
                style: AppTypography.header1,
              ),
              SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Sign in to continue tracking your cycle',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              // Email field
              Text(
                'Email',
                style: AppTypography.subtitle2,
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your@email.com',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: BorderSide(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: BorderSide(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: const BorderSide(
                      color: AppColors.peach,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.lg),
                ),
                style: AppTypography.body2,
              ),
              SizedBox(height: AppSpacing.xl),

              // Password field
              Text(
                'Password',
                style: AppTypography.subtitle2,
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !_isLoading,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: BorderSide(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: BorderSide(
                      color: AppColors.textTertiary.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    borderSide: const BorderSide(
                      color: AppColors.peach,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.lg),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                style: AppTypography.body2,
              ),
              SizedBox(height: AppSpacing.xl),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(AppColors.opacityLight),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              if (_errorMessage != null) SizedBox(height: AppSpacing.xl),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.peach,
                    disabledBackgroundColor: AppColors.textTertiary.withOpacity(
                      AppColors.opacityMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Sign In',
                          style: AppTypography.button,
                        ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Signup link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: AppTypography.body2,
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : widget.onNavigateToSignup,
                    child: Text(
                      'Sign Up',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.peach,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }
}
