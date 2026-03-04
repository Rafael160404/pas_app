import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../utils/responsive_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final user = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    required bool isDesktop,
    required bool isTablet,
    required double fontSize,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: TextStyle(
          fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
          color: Colors.black87, // <--- CHANGED TO BLACK
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.black, fontSize: fontSize), // <--- CHANGED TO BLACK
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: fontSize), // <--- CHANGED TO GREY
          filled: true,
          fillColor: Colors.white.withOpacity(0.8), // <--- MORE OPAQUE FOR BETTER READABILITY
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon, color: Colors.grey.shade700, size: isDesktop ? 24 : 20), // <--- CHANGED TO DARK GREY
          suffixIcon: obscureText ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade700, // <--- CHANGED TO DARK GREY
              size: isDesktop ? 24 : 20,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ) : null,
        ),
        validator: validator,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);
    final padding = ResponsiveHelper.getPadding(context);
    final containerWidth = ResponsiveHelper.getWidth(context, mobileFactor: 0.9, tabletFactor: 0.6, desktopFactor: 0.4);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/PAS.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: padding,
              child: Container(
                width: containerWidth,
                padding: EdgeInsets.all(isMobile ? 20 : 30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85), // <--- MORE OPAQUE BACKGROUND
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      'SIGN IN',
                      style: TextStyle(
                        fontSize: isDesktop ? 80 : (isTablet ? 70 : 60),
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // <--- CHANGED TO BLACK
                      ),
                    ),
                    Text(
                      'Welcome! Please\nSign in to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                        color: Colors.black87, // <--- CHANGED TO BLACK
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'First Name',
                      hint: 'Enter your Name',
                      icon: Icons.person,
                      controller: _firstNameController,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      fontSize: fontSize,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Last Name',
                      hint: 'Enter your Last Name',
                      icon: Icons.person_outline,
                      controller: _lastNameController,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      fontSize: fontSize,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Cellphone Number',
                      hint: 'Enter your Number',
                      icon: Icons.phone,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      fontSize: fontSize,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : (v.length < 11 ? 'Invalid number' : null),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Email Address',
                      hint: 'Enter your Email',
                      icon: Icons.email,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      fontSize: fontSize,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : (!v.contains('@') ? 'Invalid email' : null),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      isDesktop: isDesktop,
                      isTablet: isTablet,
                      fontSize: fontSize,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : (v.length < 6 ? 'Min 6 characters' : null),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: isDesktop ? 60 : (isTablet ? 55 : 45),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3bc1ff),
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text('Register', style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16))),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.black87, fontSize: fontSize), // <--- CHANGED TO BLACK
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Log in',
                            style: TextStyle(
                              color: Color(0xFFFFC0CB), // <--- KEPT PINK
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}