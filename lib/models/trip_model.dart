class Trip {
  final String id;
  final String title;
  final String partnerId;
  final String partnerName;
  final String country;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> members;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final String status;

  Trip({
    required this.id,
    required this.title,
    required this.partnerId,
    required this.partnerName,
    required this.country,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.members,
    required this.createdBy,
     required this.createdByName,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'country': country,
      'currency': currency,
      'startDate': startDate,
      'endDate': endDate,
      'members': members,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
  return Trip(
    id: id,
    title: map['title'] ?? '',
    partnerId: map['partnerId'] ?? '',
    partnerName: map['partnerName'] ?? '',
    country: map['country'] ?? '',
    currency: map['currency'] ?? '',

    startDate: map['startDate'] != null
        ? map['startDate'].toDate()
        : DateTime.now(),

    endDate: map['endDate'] != null
        ? map['endDate'].toDate()
        : DateTime.now(),

    members: List<String>.from(map['members'] ?? []),

    createdBy: map['createdBy'] ?? '',
    createdByName: map['createdByName'] ?? '',

    createdAt: map['createdAt'] != null
        ? map['createdAt'].toDate()
        : DateTime.now(),

    status: map['status'] ?? 'open',
  );
}
}