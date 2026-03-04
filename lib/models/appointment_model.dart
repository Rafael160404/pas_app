import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  String? id;
  String userId;
  String firstName;
  String lastName;
  int age;
  DateTime birthday;
  String address;
  String sex;
  String doctor;
  DateTime date;
  String time;
  String phone;
  String reason;
  String status;
  DateTime? createdAt;

  AppointmentModel({
    this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.birthday,
    required this.address,
    required this.sex,
    required this.doctor,
    required this.date,
    required this.time,
    required this.phone,
    required this.reason,
    this.status = 'upcoming',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'birthday': Timestamp.fromDate(birthday),
      'address': address,
      'sex': sex,
      'doctor': doctor,
      'date': Timestamp.fromDate(date),
      'time': time,
      'phone': phone,
      'reason': reason,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory AppointmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AppointmentModel(
      id: id,
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      age: map['age'] ?? 0,
      birthday: (map['birthday'] as Timestamp).toDate(),
      address: map['address'] ?? '',
      sex: map['sex'] ?? '',
      doctor: map['doctor'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      phone: map['phone'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'upcoming',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }
}