class TripExpense {

  final String id;
  final DateTime date;
  final String employeeId;
  final double amount;
  final String currency;
  final String category;
  final String description;
  final String receiptUrl;
  final String fingerprint;

  TripExpense({
    required this.id,
    required this.date,
    required this.employeeId,
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    required this.receiptUrl,
    required this.fingerprint,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'employeeId': employeeId,
      'amount': amount,
      'currency': currency,
      'category': category,
      'description': description,
      'receiptUrl': receiptUrl,
      'fingerprint': fingerprint,
    };
  }

  factory TripExpense.fromMap(String id, Map<String, dynamic> map) {
    return TripExpense(
      id: id,
      date: (map['date']).toDate(),
      employeeId: map['employeeId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      receiptUrl: map['receiptUrl'] ?? '',
       fingerprint: map['fingerprint'] ?? '',
    );
  }
}