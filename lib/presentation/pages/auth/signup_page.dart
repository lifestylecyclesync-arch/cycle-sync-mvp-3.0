import 'package:flutter/material.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_colors.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_spacing.dart';
import 'package:cycle_sync_mvp_2/core/theme/app_typography.dart';
import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:logger/logger.dart';

/// Sign Up/Registration Screen
/// Email and password registration
class SignupPage extends StatefulWidget {
  /// Callback when signup is successful
  final VoidCallback onSignupSuccess;

  /// Callback to navigate to login
  final VoidCallback onNavigateToLogin;

  const SignupPage({
    super.key,
    required this.onSignupSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final Logger _logger = Logger();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  /// Validate password strength
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  /// Handle signup button press
  Future<void> _handleSignup() async {
    // Clear previous errors
    setState(() => _errorMessage = null);

    // Validate inputs
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(
        () => _errorMessage = 'Please fill in all fields',
      );
      return;
    }

    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    final passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => _errorMessage = passwordError);
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      setState(
        () => _errorMessage = 'Please agree to the Terms of Service',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      _logger.i('📝 Attempting signup for: $email');

      await SupabaseConfig.signUp(
        email: email,
        password: password,
      );

      _logger.i('✅ Signup successful');

      if (mounted) {
        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created! Please check your email.'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to login after delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            widget.onSignupSuccess();
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      _logger.e('❌ Signup failed: $e');

      if (mounted) {
        setState(() {
          if (e.toString().contains('already registered')) {
            _errorMessage = 'This email is already registered';
          } else if (e.toString().contains('invalid_grant')) {
            _errorMessage = 'Invalid credentials';
          } else {
            _errorMessage = 'Signup failed. Please try again.';
          }
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
              SizedBox(height: AppSpacing.xxl),

              // Title
              Text(
                'Create Account',
                style: AppTypography.header1,
              ),
              SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                'Join us to track your cycle with ease',
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
                      color: AppColors.mint,
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
                  hintText: 'Min 8 chars, uppercase, number',
                  hintStyle: AppTypography.caption.copyWith(
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
                      color: AppColors.mint,
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

              // Confirm password field
              Text(
                'Confirm Password',
                style: AppTypography.subtitle2,
              ),
              SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                enabled: !_isLoading,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm your password',
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
                      color: AppColors.mint,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.lg),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () {
                      setState(
                        () => _showConfirmPassword = !_showConfirmPassword,
                      );
                    },
                  ),
                ),
                style: AppTypography.body2,
              ),
              SizedBox(height: AppSpacing.xl),

              // Terms agreement checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                    activeColor: AppColors.mint,
                  ),
                  Expanded(
                    child: Text(
                      'I agree to the Terms of Service',
                      style: AppTypography.body2,
                    ),
                  ),
                ],
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

              // Signup button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mint,
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
                          'Create Account',
                          style: AppTypography.button,
                        ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: AppTypography.body2,
                  ),
                  GestureDetector(
                    onTap: _isLoading ? null : widget.onNavigateToLogin,
                    child: Text(
                      'Sign In',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.mint,
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
