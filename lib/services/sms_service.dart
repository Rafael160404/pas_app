import 'package:http/http.dart' as http;
import 'dart:convert';

class SMSService {
  static const String _apiKey = "7c8bb01d-0eda-4d6d-9b25-7698ff2150e8";
  static const String _deviceId = "699d24d48afaf7aa2c57ad1f";
  static const String _adminNumber = "639613015686";

  // Send appointment confirmation SMS
  Future<bool> sendAppointmentSMS({
    required String name,
    required String doctor,
    required String date,
    required String time,
    required String phone,
    required String reason,
  }) async {
    try {
      String formattedPhone = _formatPhoneNumber(phone);
      
      final patientMsg = '''
Hello $name!
Your appointment is confirmed.

Doctor: $doctor
Date: $date
Time: $time
Reason: $reason

Thank you for choosing PAS!
''';

      await _sendSMS(formattedPhone, patientMsg);

      final adminMsg = '''
NEW APPOINTMENT
Name: $name
Doctor: $doctor
Date: $date
Time: $time
Reason: $reason
Phone: $phone
''';

      await _sendSMS(_adminNumber, adminMsg);
      
      return true;
    } catch (e) {
      print('SMS Error: $e');
      return false;
    }
  }

  // Send cancellation SMS
  Future<bool> sendCancellationSMS({
    required String name,
    required String doctor,
    required String date,
    required String time,
    required String phone,
  }) async {
    try {
      String formattedPhone = _formatPhoneNumber(phone);

      final message = '''
APPOINTMENT CANCELLED
Name: $name
Doctor: $doctor
Date: $date
Time: $time

Your appointment has been cancelled.
''';

      await _sendSMS(formattedPhone, message);

      final adminMsg = '''
CANCELLED APPOINTMENT
Name: $name
Doctor: $doctor
Date: $date
Time: $time
''';
      await _sendSMS(_adminNumber, adminMsg);
      
      return true;
    } catch (e) {
      print('SMS Error: $e');
      return false;
    }
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '63${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('63')) {
      cleaned = '63$cleaned';
    }
    return cleaned;
  }

  Future<void> _sendSMS(String number, String message) async {
    final url = Uri.parse(
      'https://api.textbee.dev/api/v1/gateway/devices/$_deviceId/send-sms',
    );

    final response = await http.post(
      url,
      headers: {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'recipients': [number],
        'message': message,
      }),
    );

    print('SMS API Response: ${response.body}');
    
    if (response.statusCode != 200) {
      throw Exception('Failed to send SMS: ${response.body}');
    }
  }
}