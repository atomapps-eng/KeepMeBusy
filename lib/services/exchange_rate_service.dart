import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static Future<double> getEurToIdr() async {
    final url = Uri.parse(
      'https://api.exchangerate-api.com/v4/latest/EUR',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['rates']['IDR'] as num).toDouble();
    } else {
      throw Exception('Failed to load exchange rate');
    }
  }
}