class TripLedgerItem {

  final DateTime date;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final bool isDebit;
  final String? receiptUrl;

  TripLedgerItem({
    required this.date,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.isDebit,
    this.receiptUrl,
  });

}