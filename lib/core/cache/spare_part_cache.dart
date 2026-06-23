import 'package:hive/hive.dart';
import '../../models/spare_part.dart';
import '../../core/session/company_session.dart';

class SparePartCache {
  String _getBoxName() {
  final companyId = CompanySession.currentCompanyId;
  return 'spare_parts_cache_$companyId';
}

  Future<Box> _openBox() async {
  final boxName = _getBoxName();
  return await Hive.openBox(boxName);
}

  Future<void> save(List<SparePart> parts) async {
    final box = await _openBox();

    final data = parts.map((e) => e.toJson()).toList();

    await box.put('data', data);
    await box.put('lastUpdated', DateTime.now().toIso8601String());
  }

  Future<void> saveServerSyncTime(DateTime serverTime) async {
  final box = await _openBox();

  await box.put(
    'serverSyncTime',
    serverTime.toIso8601String(),
  );
}

Future<DateTime?> getServerSyncTime() async {
  final box = await _openBox();

  final value = box.get('serverSyncTime');

  if (value == null) return null;

  return DateTime.tryParse(value);
}

  Future<List<SparePart>> load() async {
    final box = await _openBox();

    final data = box.get('data');

    if (data == null) return [];

    return (data as List)
        .map((e) => SparePart.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }

  Future<bool> isExpired({int minutes = 5}) async {
  final box = await _openBox();

  final lastUpdated = box.get('lastUpdated');

  if (lastUpdated == null) return true;

  final lastTime = DateTime.parse(lastUpdated);
  final now = DateTime.now();

  return now.difference(lastTime).inMinutes > minutes;
}

}