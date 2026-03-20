
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityEntry {
  final DateTime date;
  final String factoryId;
  final String factoryClient;
  final String customerId;

  final String machine;
  final String serialNumber;

  final String activityType;
  final String description;

  final String status;
  final String note;

  ActivityEntry({
    required this.date,
    required this.factoryId,
    required this.factoryClient,
    required this.customerId,
    required this.machine,
    required this.serialNumber,
    required this.activityType,
    required this.description,
    required this.status,
    required this.note,
  });

  // 🔥 TAMBAHKAN INI
  factory ActivityEntry.fromMap(Map<String, dynamic> map, DateTime date) {
    return ActivityEntry(
      date: date,
      factoryId: map['factoryId'] ?? '',
      factoryClient: map['factoryClient'] ?? '',
      customerId: map['customerId'] ?? '',
      machine: map['machine'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      activityType: map['activityType'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      note: map['note'] ?? '',
    );
  }
  Map<String, dynamic> toMap() {
  return {
    'factoryId': factoryId,
    'factoryClient': factoryClient,
    'customerId': customerId,
    'machine': machine,
    'serialNumber': serialNumber,
    'activityType': activityType,
    'description': description,
    'status': status,
    'note': note,
    'createdAt': Timestamp.now(), // 🔥 penting
    'date': Timestamp.fromDate(date),
  };
}
}