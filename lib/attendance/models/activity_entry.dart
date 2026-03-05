class ActivityEntry {

  final DateTime date;
  final String factoryClient;
  final String customerId;

  final String machine;
  final String serialNumber;

  final String activityType;
  final String description;

  final String status;
  final String note;

  ActivityEntry({
    required this.date,
    required this.factoryClient,
    required this.customerId,
    required this.machine,
    required this.serialNumber,
    required this.activityType,
    required this.description,
    required this.status,
    required this.note,
  });

}