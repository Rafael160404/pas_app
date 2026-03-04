import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _firstNameController.text = data['firstName'] ?? '';
        _lastNameController.text = data['lastName'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _emailController.text = data['email'] ?? user.email ?? '';
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final user = _authService.getCurrentUser();
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green)
          );
          Navigator.pop(context);
        }
      }
      setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool enabled = true,
    required double fontSize,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        label,
        style: TextStyle(
          fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: fontSize),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: isDesktop ? 24 : 20),
        ),
        validator: (value) => value == null || value.isEmpty ? '$label is required' : null,
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
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 22 : 20)),
        ),
        backgroundColor: const Color(0xFF3bc1ff),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: padding,
            child: Container(
              width: containerWidth,
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                    key: _formKey,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: isDesktop ? 48 : (isTablet ? 40 : 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        width: isDesktop ? 150 : (isTablet ? 120 : 100),
                        height: isDesktop ? 150 : (isTablet ? 120 : 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.person,
                          size: isDesktop ? 80 : (isTablet ? 60 : 50),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person,
                        fontSize: fontSize,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline,
                        fontSize: fontSize,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        fontSize: fontSize,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        enabled: false,
                        fontSize: fontSize,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: isDesktop ? 60 : (isTablet ? 55 : 45),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: _isSaving
                            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                'Update Profile',
                                style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16)),
                              ),
                        ),
                      ),
                    ]),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}