import 'package:shared_preferences/shared_preferences.dart';

class CompanySession {
  static String? selectedCompanyId;

  static const _key = 'selected_company';

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    selectedCompanyId = prefs.getString(_key);
  }

  static Future<void> setCompany(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, companyId);
    selectedCompanyId = companyId;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    selectedCompanyId = null;
  }
}