import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/exports.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _isLoading = false;
  bool _hasSubmitted = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
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

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Full name is required';
    }
    if (name.length < 2) {
      return 'Enter at least 2 characters';
    }
    return null;
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

  String? _validateConfirmPassword(String? value) {
    final confirm = value?.trim() ?? '';
    if (confirm.isEmpty) {
      return 'Confirm your password';
    }
    if (confirm != passwordController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _hasSubmitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
      return;
    }

    final error = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).error;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Registration failed'),
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
                  'Create Account',
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
                  'Join 50,000+ students studying smarter.',
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
                        'FULL NAME',
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
                        controller: nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: _validateName,
                        decoration: _buildInputDecoration(
                          hintText: 'Farax Ali',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 18),
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
                          hintText: 'farax@gmail.com',
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
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: _validatePassword,
                        decoration: _buildInputDecoration(
                          hintText: 'Enter password',
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
                      const SizedBox(height: 18),
                      Text(
                        'CONFIRM PASSWORD',
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
                        controller: confirmController,
                        obscureText: !_isConfirmVisible,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        validator: _validateConfirmPassword,
                        onFieldSubmitted: (_) => _isLoading ? null : _handleRegister(),
                        decoration: _buildInputDecoration(
                          hintText: 'Confirm password',
                          icon: Icons.check_circle_outline,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _isConfirmVisible = !_isConfirmVisible;
                              });
                            },
                            icon: Icon(
                              _isConfirmVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColor.kTextStyleColorGray,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: GoogleFonts.poppins().fontFamily,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColor.kTextStyleColorGray,
                              fontFamily: GoogleFonts.poppins().fontFamily,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: AppColor.kPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontFamily: GoogleFonts.poppins().fontFamily,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}
