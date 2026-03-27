import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session/company_session.dart';

class OrderOutCache {
  String _getBoxName() {
    final companyId = CompanySession.currentCompanyId;
    return 'order_out_cache_$companyId';
  }

  Future<Box> _openBox() async {
    return await Hive.openBox(_getBoxName());
  }

  Future<void> save(List<Map<String, dynamic>> docs) async {
  final box = await _openBox();

  await box.put('data', docs);
  await box.put('lastUpdated', DateTime.now().toIso8601String());
}

 Future<List<Map<String, dynamic>>> load() async {
  final box = await _openBox();

  final data = box.get('data');

  if (data == null) return [];

  // 🔑 FIX TYPE CAST
  return (data as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

  Future<bool> isExpired({int minutes = 5}) async {
    final box = await _openBox();

    final lastUpdated = box.get('lastUpdated');

    if (lastUpdated == null) return true;

    final lastTime = DateTime.parse(lastUpdated);
    return DateTime.now().difference(lastTime).inMinutes > minutes;
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }
}