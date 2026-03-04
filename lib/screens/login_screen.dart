import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import '../utils/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (user != null && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/FP1.png'),
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
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'LOG IN',
                        style: TextStyle(
                          fontSize: isDesktop ? 80 : (isTablet ? 70 : 60),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome! Please\nlogin to your account.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Email Field
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: Colors.white, fontSize: fontSize),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: fontSize),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.8), size: isDesktop ? 24 : 20),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your email' : (!value.contains('@') ? 'Invalid email' : null),
                      ),
                      const SizedBox(height: 16),
                      // Password Field
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Password',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: TextStyle(color: Colors.white, fontSize: fontSize),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: fontSize),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.2),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.8), size: isDesktop ? 24 : 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white.withOpacity(0.8),
                              size: isDesktop ? 24 : 20,
                            ),
                            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : (value.length < 6 ? 'Min 6 characters' : null),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                          child: Text('Forgot Password?', style: TextStyle(color: Colors.white, fontSize: fontSize)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 60 : (isTablet ? 55 : 50),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: _isLoading
                              ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text('Login', style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16))),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: fontSize),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: Text('Sign up', style: TextStyle(color: Color(0xFFFFC0CB), fontSize: fontSize, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}