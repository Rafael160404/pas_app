import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email'), backgroundColor: Colors.red)
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email!'), backgroundColor: Colors.green)
        );
        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      appBar: AppBar(
        title: Text(
          'Forgot Password',
          style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 22 : 20), color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/FP4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: padding,
            child: Container(
              width: containerWidth,
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85), // <--- MORE OPAQUE FOR BETTER READABILITY
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: isDesktop ? 48 : (isTablet ? 40 : 32),
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // <--- CHANGED TO BLACK
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to generate reset link',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                      color: Colors.black87, // <--- CHANGED TO BLACK87
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: Colors.black, fontSize: fontSize), // <--- CHANGED TO BLACK
                    decoration: InputDecoration(
                      hintText: 'Enter email',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: fontSize), // <--- CHANGED TO GREY
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9), // <--- MORE OPAQUE
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey.shade700, // <--- CHANGED TO DARK GREY
                        size: isDesktop ? 24 : 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 60 : (isTablet ? 55 : 45),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3bc1ff), // <--- SOLID COLOR
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Generate Reset Link',
                              style: TextStyle(fontSize: isDesktop ? 18 : (isTablet ? 16 : 14)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '← Back to Login',
                      style: TextStyle(
                        color: Colors.black87, // <--- CHANGED TO BLACK87
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}