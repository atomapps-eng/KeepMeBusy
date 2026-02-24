// lib/models/analytics_data.dart
class AnalyticsData {
  final int totalReads;
  final Map<String, int> readsByPage;
  final Map<String, int> readsByCollection;
  final Map<String, int> readsByHour;
  final List<ReadOperation> recentReads;

  AnalyticsData({
    required this.totalReads,
    required this.readsByPage,
    required this.readsByCollection,
    required this.readsByHour,
    required this.recentReads,
  });
}

class ReadOperation {
  final String page;
  final String collection;
  final String operation;
  final DateTime timestamp;
  final int documentsCount;

  ReadOperation({
    required this.page,
    required this.collection,
    required this.operation,
    required this.timestamp,
    required this.documentsCount,
  });
}