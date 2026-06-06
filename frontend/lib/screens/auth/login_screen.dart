import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/exports.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      final error = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Login failed'),
        ),
      );
    }
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      prefixIcon: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: const BoxDecoration(
          border: Border(
            right: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Icon(icon, color: AppColor.kPrimaryColor),
      ),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
<<<<<<< HEAD
        borderSide: BorderSide(
          color: AppColor.kPrimaryColor.withValues(alpha: 0.35),
        ),
=======
        borderSide: BorderSide(color: AppColor.kPrimaryColor.withValues(alpha: 0.35)),
>>>>>>> 32bc85c5f392e098a181db65d1e8fda72c5e3890
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      errorMaxLines: 2,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Email address is required';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
  }) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            foregroundColor: AppColor.kSecondColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.kSecondColor,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              children: [
<<<<<<< HEAD
                StudyPlannerLogoBadge(
                  size: 110,
                  backgroundColor: AppColor.kPrimaryColor,
                  borderRadius: 32,
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.kPrimaryColor.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
=======
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimaryColor,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.kPrimaryColor.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 48,
                  ),
>>>>>>> 32bc85c5f392e098a181db65d1e8fda72c5e3890
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColor.kSecondColor,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your academic goals are waiting for you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColor.kTextStyleColorGray,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _hasSubmitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kTextStyleColorGray,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username, AutofillHints.email],
                        validator: _validateEmail,
                        decoration: _buildInputDecoration(
                          hintText: 'name@university.edu',
                          icon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'PASSWORD',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColor.kTextStyleColorGray,
                          fontFamily: GoogleFonts.poppins().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: _validatePassword,
                        onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter your password',
                          icon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColor.kTextStyleColorGray,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: AppColor.kPrimaryColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: GoogleFonts.poppins().fontFamily,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColor.kTextStyleColorGray,
                                fontWeight: FontWeight.w600,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildSocialButton(
                            icon: Icons.g_translate,
                            label: 'Google',
                          ),
                          const SizedBox(width: 12),
                          _buildSocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Don\'t have an account? Sign Up',
                            style: TextStyle(
                              color: AppColor.kSecondColor,
                              fontWeight: FontWeight.w600,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
