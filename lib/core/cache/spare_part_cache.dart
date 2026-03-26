import 'package:hive/hive.dart';
import '../../models/spare_part.dart';

class SparePartCache {
  static const String _boxName = 'spare_parts_cache';

  Future<Box> _openBox() async {
    return await Hive.openBox(_boxName);
  }

  Future<void> save(List<SparePart> parts) async {
    final box = await _openBox();

    final data = parts.map((e) => e.toJson()).toList();

    await box.put('data', data);
    await box.put('lastUpdated', DateTime.now().toIso8601String());
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
}