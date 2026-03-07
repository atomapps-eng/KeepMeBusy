import 'dart:convert';
import 'package:crypto/crypto.dart';

class ReceiptFingerprint {

  static String generate({
    required String merchant,
    required double amount,
    required String currency,
    required DateTime date,
  }) {

    final raw =
        "${merchant.toLowerCase()}_${amount}_${currency}_${date.toIso8601String().substring(0,10)}";

    final bytes = utf8.encode(raw);

    final digest = sha1.convert(bytes);

    return digest.toString();
  }
}