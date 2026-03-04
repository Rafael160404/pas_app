import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/appointment_model.dart';
import '../utils/responsive_helper.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<Map<String, dynamic>> _doctors = [
    {'name': 'Dr. James Brown', 'specialty': 'Orthopedic', 'description': 'Sports injuries specialist with 10 years of experience.', 'image': 'assets/images/doc1.jpg'},
    {'name': 'Dr. Bryan Curry', 'specialty': 'Neurology', 'description': 'Brain & nervous system specialist with 8 years of experience.', 'image': 'assets/images/doc2.jpg'},
    {'name': 'Dr. Anne Thok', 'specialty': 'Pediatrics', 'description': 'Child health expert with 7 years of experience.', 'image': 'assets/images/doc7.jpg'},
    {'name': 'Dr. Lisa Thompson', 'specialty': 'Dermatology', 'description': 'Skin care specialist with 9 years of experience.', 'image': 'assets/images/doc5.webp'},
  ];

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();
  
  String _selectedSex = 'Male';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Map<String, dynamic>? _selectedDoctor;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showDoctorProfile(Map<String, dynamic> doctor, BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: isDesktop ? 500 : (isTablet ? 400 : 300),
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: isDesktop ? 120 : (isTablet ? 100 : 90),
                height: isDesktop ? 120 : (isTablet ? 100 : 90),
                color: Colors.grey.shade200,
                child: doctor['image'].toString().startsWith('assets/')
                  ? Image.asset(doctor['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, size: isDesktop ? 60 : (isTablet ? 50 : 40), color: Colors.grey))
                  : Icon(Icons.person, size: isDesktop ? 60 : (isTablet ? 50 : 40), color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              doctor['name'],
              style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 20 : 18), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              doctor['specialty'],
              style: TextStyle(fontSize: isDesktop ? 18 : (isTablet ? 16 : 14), color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              doctor['description'],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: isDesktop ? 16 : (isTablet ? 14 : 12)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(fontSize: fontSize)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showBookingModal(doctor, context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3bc1ff), foregroundColor: Colors.white),
                  child: Text('Book Appointment', style: TextStyle(fontSize: fontSize)),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  void _showBookingModal(Map<String, dynamic> doctor, BuildContext context) {
    setState(() => _selectedDoctor = doctor);
    
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * (isMobile ? 0.9 : (isTablet ? 0.8 : 0.7)),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: const BoxDecoration(
                color: Color(0xFF3bc1ff),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Book with ${doctor['name']}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isDesktop ? 24 : (isTablet ? 20 : 16),
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: isDesktop ? 28 : 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(children: [
                  _buildTextField(controller: _firstNameController, label: 'First Name', fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _lastNameController, label: 'Last Name', fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _ageController, label: 'Age', keyboardType: TextInputType.number, fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _selectBirthday(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _birthdayController,
                        label: 'Birthday',
                        hint: 'YYYY-MM-DD',
                        fontSize: fontSize,
                        isDesktop: isDesktop,
                        isTablet: isTablet,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _addressController, label: 'Address', fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration: InputDecoration(
                      labelText: 'Sex',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(fontSize: fontSize),
                    items: ['Male', 'Female'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(fontSize: fontSize)))).toList(),
                    onChanged: (v) => setState(() => _selectedSex = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: doctor['name'],
                    enabled: false,
                    style: TextStyle(fontSize: fontSize),
                    decoration: InputDecoration(
                      labelText: 'Doctor',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      labelStyle: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Date', style: TextStyle(fontSize: fontSize)),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: TextStyle(fontSize: fontSize - 2)),
                    trailing: Icon(Icons.calendar_today, size: isDesktop ? 24 : 20),
                    onTap: () => _selectDate(context),
                  ),
                  ListTile(
                    title: Text('Time', style: TextStyle(fontSize: fontSize)),
                    subtitle: Text(_selectedTime.format(context), style: TextStyle(fontSize: fontSize - 2)),
                    trailing: Icon(Icons.access_time, size: isDesktop ? 24 : 20),
                    onTap: () => _selectTime(context),
                  ),
                  _buildTextField(controller: _phoneController, label: 'Phone', keyboardType: TextInputType.phone, fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(controller: _reasonController, label: 'Reason', maxLines: 3, fontSize: fontSize, isDesktop: isDesktop, isTablet: isTablet),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 60 : (isTablet ? 55 : 50),
                    child: ElevatedButton(
                      onPressed: _saveAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3bc1ff),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Book Appointment',
                        style: TextStyle(fontSize: isDesktop ? 20 : (isTablet ? 18 : 16)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    required double fontSize,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(fontSize: fontSize),
        hintStyle: TextStyle(fontSize: fontSize - 2),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _saveAppointment() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || 
        _ageController.text.isEmpty || _birthdayController.text.isEmpty || 
        _addressController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red)
      );
      return;
    }
    if (_selectedDoctor == null) return;

    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      final appointment = AppointmentModel(
        userId: user.uid,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        birthday: DateFormat('yyyy-MM-dd').parse(_birthdayController.text.trim()),
        address: _addressController.text.trim(),
        sex: _selectedSex,
        doctor: _selectedDoctor!['name'],
        date: _selectedDate,
        time: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        phone: _phoneController.text.trim(),
        reason: _reasonController.text.trim(),
      );

      await _firestore.collection('appointments').add(appointment.toMap());

      if (mounted) {
        _firstNameController.clear(); _lastNameController.clear(); _ageController.clear(); 
        _birthdayController.clear(); _addressController.clear(); _phoneController.clear(); 
        _reasonController.clear();
        setState(() { 
          _selectedSex = 'Male'; 
          _selectedDate = DateTime.now(); 
          _selectedTime = TimeOfDay.now(); 
          _selectedDoctor = null; 
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Doctors', style: TextStyle(fontSize: isDesktop ? 24 : (isTablet ? 22 : 20))),
        backgroundColor: const Color(0xFF3bc1ff),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: isDesktop ? 300 : (isTablet ? 250 : 200),
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/girl.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
            child: Stack(children: [
              Positioned(
                right: 20,
                top: isDesktop ? 80 : (isTablet ? 60 : 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    'Find your best Doctor\nfor your needs!',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 32 : (isTablet ? 24 : 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your health, our priority.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: isDesktop ? 20 : (isTablet ? 16 : 14),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: padding,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
                childAspectRatio: isMobile ? 0.75 : 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () => _showDoctorProfile(doctor, context),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Container(
                            width: double.infinity,
                            color: Colors.grey.shade200,
                            child: doctor['image'].toString().startsWith('assets/')
                              ? Image.asset(doctor['image'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.person, size: isDesktop ? 40 : 30, color: Colors.grey))
                              : Icon(Icons.person, size: isDesktop ? 40 : 30, color: Colors.grey),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              doctor['name'],
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isDesktop ? 16 : (isTablet ? 14 : 12)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor['specialty'],
                              style: TextStyle(fontSize: isDesktop ? 14 : (isTablet ? 12 : 10), color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doctor['description'].split('.').first,
                              style: TextStyle(fontSize: isDesktop ? 12 : (isTablet ? 11 : 9)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: isMobile ? 2 : 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3bc1ff),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'View Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 12 : (isTablet ? 11 : 9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}