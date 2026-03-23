import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuotationService {
  static final _db = FirebaseFirestore.instance;

  static Future<String> generateQuotationNumber(String companyId) async {
    final year = DateTime.now().year;

    final counterRef = _db
        .collection('companies')
        .doc(companyId)
        .collection('counters')
        .doc('quotation');

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int lastNumber = 0;

      if (snapshot.exists) {
        final data = snapshot.data()!;
        final storedYear = data['year'] ?? year;

        if (storedYear == year) {
          lastNumber = data['lastNumber'] ?? 0;
        } else {
          lastNumber = 0; // reset tiap tahun
        }
      }

      final newNumber = lastNumber + 1;

      transaction.set(counterRef, {
        'year': year,
        'lastNumber': newNumber,
      });

      final code = _getCompanyCode(companyId);

      return "Q-$code-$year-${newNumber.toString().padLeft(4, '0')}";
    });
  }

  static String _getCompanyCode(String companyId) {
    switch (companyId) {
      case 'atomIndonesia':
        return 'IND';
      case 'atomVietnam':
        return 'VNM';
      case 'atomIndia':
        return 'INDIA';
      default:
        return 'UNK';
    }
  }

  static Future<void> createQuotation({
  required String companyId,
  required String userId,
  required String userName,
  required String partnerName,
required String partnerAddress,
  required String currency,
  required double exchangeRate,
  required List<Map<String, dynamic>> items,
  required int priceValidityDays,
  required double vatPercent,
  required double discountPercent,
  required double discountAmount,
required double vatAmount,
}) async {
  final docRef = _db
      .collection('companies')
      .doc(companyId)
      .collection('quotations')
      .doc();

  // 🔥 generate quotation number
  final quotationNumber = await generateQuotationNumber(companyId);

  double totalAmount = 0;

  final processedItems = items.map((item) {
    final qty = item['qty'] ?? 0;
    final priceEur = (item['priceEur'] ?? 0).toDouble();

    final priceLocal = priceEur * exchangeRate;
    final total = priceLocal * qty;

    totalAmount += total;

    return {
      'partId': item['partId'],
      'partCode': item['partCode'],
      'partName': item['partName'],
      'qty': qty,
      'stock': item['stock'], // snapshot
      'priceEur': priceEur,
      'priceLocal': priceLocal,
      'total': total,
    };
  }).toList();

  await docRef.set({
    'quotationNumber': quotationNumber,
    'companyId': companyId,

    'createdBy': userId,
    'createdByName': userName,

    'status': 'draft',
    'partnerName': partnerName,
'partnerAddress': partnerAddress,

    'currency': currency,
    'exchangeRate': exchangeRate,

    'items': processedItems,
    'totalAmount': totalAmount,
    'subtotal': totalAmount, // sementara (akan kita refine nanti)
'discountPercent': discountPercent,
'discountAmount': discountAmount,
'vatPercent': vatPercent,
'vatAmount': vatAmount,

    'priceValidityDays': priceValidityDays,
  'validUntil': Timestamp.fromDate(
    DateTime.now().add(Duration(days: priceValidityDays)),
  ),
  'vatPercent': vatPercent,
  'discountPercent': discountPercent,

    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

static String getCurrencyByCompany(String companyId) {
  switch (companyId) {
    case 'atomIndonesia':
      return 'IDR';
    case 'atomVietnam':
      return 'VND';
    case 'atomIndia':
      return 'INR';
    default:
      return 'EUR';
  }
}

static double getExchangeRate(String companyId) {
  switch (companyId) {
    case 'atomIndonesia':
      return 17000; // EUR → IDR
    case 'atomVietnam':
      return 27000; // EUR → VND
    case 'atomIndia':
      return 90; // EUR → INR
    default:
      return 1;
  }
}

static Map<String, dynamic> getCurrencyConfig(String companyId) {
  return {
    'currency': getCurrencyByCompany(companyId),
    'rate': getExchangeRate(companyId),
  };
}

static Future<void> submitQuotation({
  required String companyId,
  required String quotationId,
  required String userId,
}) async {
  final docRef = _db
      .collection('companies')
      .doc(companyId)
      .collection('quotations')
      .doc(quotationId);

  // 🔽 ambil data user dulu
final user = FirebaseAuth.instance.currentUser;

final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final userData = userDoc.data() as Map<String, dynamic>?;

// 🔽 update quotation
await docRef.update({
  'status': 'approved',
  'approvedAt': FieldValue.serverTimestamp(),
  'approvedBy': userId,
  'approvedByName': userData?['name'] ?? '-',
});
}

static Future<void> approveQuotation({
  required String companyId,
  required String quotationId,
  required String userId,
}) async {
  final docRef = _db
      .collection('companies')
      .doc(companyId)
      .collection('quotations')
      .doc(quotationId);

  await docRef.update({
    'status': 'approved',
    'approvedAt': FieldValue.serverTimestamp(),
    'approvedBy': userId,
  });
}

static Future<void> rejectQuotation({
  required String companyId,
  required String quotationId,
  required String userId,
  required String note,
}) async {
  final docRef = _db
      .collection('companies')
      .doc(companyId)
      .collection('quotations')
      .doc(quotationId);

  await docRef.update({
    'status': 'rejected',
    'rejectedAt': FieldValue.serverTimestamp(),
    'rejectedBy': userId,
    'rejectionNote': note,
  });
}

}