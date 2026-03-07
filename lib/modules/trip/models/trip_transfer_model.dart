class TripTransfer {

  final String id;
  final DateTime date;
  final String createdBy;
  final List<Map<String, dynamic>> transfers;
  final String note;

  TripTransfer({
    required this.id,
    required this.date,
    required this.createdBy,
    required this.transfers,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'createdBy': createdBy,
      'transfers': transfers,
      'note': note,
    };
  }

  factory TripTransfer.fromMap(String id, Map<String, dynamic> map) {
    return TripTransfer(
      id: id,
      date: (map['date']).toDate(),
      createdBy: map['createdBy'] ?? '',
      transfers: List<Map<String, dynamic>>.from(map['transfers'] ?? []),
      note: map['note'] ?? '',
    );
  }
}