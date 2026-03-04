import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/sms_service.dart';
import '../models/appointment_model.dart';
import '../utils/responsive_helper.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SMSService _smsService = SMSService();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedSex = 'Male';
  String _selectedDoctor = 'Dr. James Brown';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _doctors = [
    'Dr. James Brown',
    'Dr. Bryan Curry',
    'Dr. Anne Thok',
    'Dr. Lisa Thompson',
  ];

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

  // Pick appointment date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // Pick appointment time
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // Pick birthday
  Future<void> _selectBirthday(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Save appointment
  Future<void> _saveAppointment() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _birthdayController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
        doctor: _selectedDoctor,
        date: _selectedDate,
        time:
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        phone: _phoneController.text.trim(),
        reason: _reasonController.text.trim(),
      );

      await _firestore.collection('appointments').add(appointment.toMap());

      if (mounted) {
        String name =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        String dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        String timeStr =
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
        String phoneStr = _phoneController.text.trim();
        String reasonStr = _reasonController.text.trim();

        _firstNameController.clear();
        _lastNameController.clear();
        _ageController.clear();
        _birthdayController.clear();
        _addressController.clear();
        _phoneController.clear();
        _reasonController.clear();

        setState(() {
          _selectedSex = 'Male';
          _selectedDoctor = 'Dr. James Brown';
          _selectedDate = DateTime.now();
          _selectedTime = TimeOfDay.now();
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // SEND SMS NOTIFICATION
        try {
          await _smsService.sendAppointmentSMS(
            name: name,
            doctor: _selectedDoctor,
            date: dateStr,
            time: timeStr,
            phone: phoneStr,
            reason: reasonStr,
          );
          print('✅ SMS sent successfully');
        } catch (e) {
          print('❌ Failed to send SMS: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Delete appointment
  Future<void> _deleteAppointment(String id, Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('appointments').doc(id).delete();

        // SEND CANCELLATION SMS
        try {
          String name = '${data['firstName']} ${data['lastName']}';
          String doctor = data['doctor'] ?? '';
          String date = data['date'] != null
              ? DateFormat('yyyy-MM-dd')
                  .format((data['date'] as Timestamp).toDate())
              : '';
          String time = data['time'] ?? '';
          String phone = data['phone'] ?? '';

          await _smsService.sendCancellationSMS(
            name: name,
            doctor: doctor,
            date: date,
            time: time,
            phone: phone,
          );
          print('✅ Cancellation SMS sent');
        } catch (e) {
          print('❌ Failed to send cancellation SMS: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);
    final padding = ResponsiveHelper.getPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: TextStyle(
              fontSize: isDesktop ? 24 : (isTablet ? 22 : 20)),
        ),
        backgroundColor: const Color(0xFF3bc1ff),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: isDesktop ? 28 : 24),
            onPressed: () => _showAppointmentModal(context),
          )
        ],
      ),
      body: user == null
          ? Center(
              child: Text('Please login to view appointments',
                  style: TextStyle(fontSize: fontSize)),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(fontSize: fontSize)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final appointments = snapshot.data!.docs;
                if (appointments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month,
                            size: isDesktop
                                ? 120
                                : (isTablet ? 100 : 80),
                            color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('No appointments yet',
                            style: TextStyle(
                                fontSize: isDesktop
                                    ? 24
                                    : (isTablet ? 20 : 18),
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Tap the + button to book one',
                            style: TextStyle(
                                fontSize: isDesktop
                                    ? 18
                                    : (isTablet ? 16 : 14))),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: padding,
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final doc = appointments[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();

                    return Card(
                      margin: EdgeInsets.only(bottom: isMobile ? 8 : 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: data['status'] == 'cancelled'
                                  ? Colors.red
                                  : const Color(0xFF3bc1ff),
                              width: 4,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${data['firstName']} ${data['lastName']}',
                                        style: TextStyle(
                                            fontSize: isDesktop
                                                ? 20
                                                : (isTablet ? 18 : 16),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.red,
                                          size: isDesktop
                                              ? 28
                                              : (isTablet ? 24 : 20)),
                                      onPressed: () =>
                                          _deleteAppointment(doc.id, data),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Age: ${data['age']} | Sex: ${data['sex']}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text(
                                    'Birthday: ${data['birthday'] != null ? DateFormat('yyyy-MM-dd').format((data['birthday'] as Timestamp).toDate()) : ''}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text('Address: ${data['address']}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text('Doctor: ${data['doctor']}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text(
                                    'Date: ${DateFormat('yyyy-MM-dd').format(date)} | Time: ${data['time']}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text('Phone: ${data['phone']}',
                                    style: TextStyle(fontSize: fontSize)),
                                Text('Reason: ${data['reason']}',
                                    style: TextStyle(fontSize: fontSize)),
                                if (data['status'] == 'cancelled')
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: isMobile ? 6 : 8,
                                        vertical: isMobile ? 2 : 4),
                                    decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius:
                                            BorderRadius.circular(4)),
                                    child: Text(
                                      'CANCELLED',
                                      style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize - 2),
                                    ),
                                  ),
                              ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAppointmentModal(context),
        backgroundColor: const Color(0xFF3bc1ff),
        child: Icon(Icons.add,
            size: isDesktop ? 32 : (isTablet ? 28 : 24),
            color: Colors.white),
      ),
    );
  }

  void _showAppointmentModal(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontSize = ResponsiveHelper.getFontSize(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height *
            (isMobile ? 0.9 : (isTablet ? 0.8 : 0.7)),
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
                  Text(
                    'New Appointment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isDesktop ? 24 : (isTablet ? 22 : 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: Colors.white, size: isDesktop ? 28 : 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                child: Column(children: [
                  _buildTextField(
                      controller: _firstNameController,
                      label: 'First Name',
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: _lastNameController,
                      label: 'Last Name',
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: _ageController,
                      label: 'Age',
                      keyboardType: TextInputType.number,
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
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
                  _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
                  const SizedBox(height: 12),
                  // Sex Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    decoration: InputDecoration(
                      labelText: 'Sex',
                      labelStyle: TextStyle(color: Colors.black), // <--- BLACK LABEL
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: Colors.black), // <--- BLACK TEXT
                    items: ['Male', 'Female'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: Colors.black)))).toList(),
                    onChanged: (v) => setState(() => _selectedSex = v!),
                  ),

                  // Doctor Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedDoctor,
                    decoration: InputDecoration(
                      labelText: 'Doctor',
                      labelStyle: TextStyle(color: Colors.black), // <--- BLACK LABEL
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    style: TextStyle(color: Colors.black), // <--- BLACK TEXT
                    items: _doctors.map((v) => DropdownMenuItem(value: v, child: Text(v, style: TextStyle(color: Colors.black)))).toList(),
                    onChanged: (v) => setState(() => _selectedDoctor = v!),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text('Date', style: TextStyle(fontSize: fontSize)),
                    subtitle: Text(DateFormat('yyyy-MM-dd')
                        .format(_selectedDate), style: TextStyle(fontSize: fontSize - 2)),
                    trailing:
                        Icon(Icons.calendar_today, size: isDesktop ? 24 : 20),
                    onTap: () => _selectDate(context),
                  ),
                  ListTile(
                    title: Text('Time', style: TextStyle(fontSize: fontSize)),
                    subtitle:
                        Text(_selectedTime.format(context), style: TextStyle(fontSize: fontSize - 2)),
                    trailing:
                        Icon(Icons.access_time, size: isDesktop ? 24 : 20),
                    onTap: () => _selectTime(context),
                  ),
                  _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      keyboardType: TextInputType.phone,
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
                  const SizedBox(height: 12),
                  _buildTextField(
                      controller: _reasonController,
                      label: 'Reason',
                      maxLines: 3,
                      fontSize: fontSize,
                      isDesktop: isDesktop,
                      isTablet: isTablet),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 60 : (isTablet ? 55 : 50),
                    child: ElevatedButton(
                      onPressed: _saveAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3bc1ff),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Save Appointment',
                        style: TextStyle(
                            fontSize: isDesktop ? 20 : (isTablet ? 18 : 16)),
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
}