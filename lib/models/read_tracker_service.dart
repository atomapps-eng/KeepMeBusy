// lib/services/read_tracker_service.dart
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_data.dart';

class ReadTrackerService {
  static final ReadTrackerService _instance = ReadTrackerService._internal();
  factory ReadTrackerService() => _instance;
  ReadTrackerService._internal();

  // Flag untuk enable/disable tracking
  bool _isTracking = false;
  
  // Getter untuk isTracking
  bool get isTracking => _isTracking;
  
  // Data storage
  final List<Map<String, dynamic>> _readLogs = [];
  static const int _maxLogs = 1000;

  // Start tracking
  void startTracking() {
    _isTracking = true;
    _readLogs.clear();
    print('📊 Read tracking started'); // GANTI DENGAN print
  }

  // Stop tracking
  void stopTracking() {
    _isTracking = false;
    print('📊 Read tracking stopped. Total reads: ${_readLogs.length}'); // GANTI DENGAN print
  }

  // Clear logs
  void clearLogs() {
    _readLogs.clear();
    print('📊 Read logs cleared'); // GANTI DENGAN print
  }

  // Track a read operation
  void trackRead({
    required String page,
    required String collection,
    required String operation,
    required int documentsCount,
    String? queryParams,
  }) {
    if (!_isTracking) return;

    final logEntry = {
      'page': page,
      'collection': collection,
      'operation': operation,
      'documentsCount': documentsCount,
      'timestamp': DateTime.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
      'queryParams': queryParams,
    };

    _readLogs.add(logEntry);

    if (_readLogs.length > _maxLogs) {
      _readLogs.removeAt(0);
    }

    print('📖 READ: $page - $collection ($documentsCount docs)'); // GANTI DENGAN print
  }

  // Get analytics data
  AnalyticsData getAnalytics() {
    if (_readLogs.isEmpty) {
      return AnalyticsData(
        totalReads: 0,
        readsByPage: {},
        readsByCollection: {},
        readsByHour: {},
        recentReads: [],
      );
    }

    // Hitung reads per page
    final readsByPage = <String, int>{};
    for (var log in _readLogs) {
      final page = log['page'] as String;
      readsByPage[page] = (readsByPage[page] ?? 0) + 1;
    }

    // Hitung reads per collection
    final readsByCollection = <String, int>{};
    for (var log in _readLogs) {
      final collection = log['collection'] as String;
      readsByCollection[collection] = (readsByCollection[collection] ?? 0) + 1;
    }

    // Hitung reads per hour
    final readsByHour = <String, int>{};
    for (var log in _readLogs) {
      final hour = (log['timestamp'] as DateTime).hour.toString();
      readsByHour[hour] = (readsByHour[hour] ?? 0) + 1;
    }

    // Recent reads
    final recentReads = _readLogs.reversed.take(50).map((log) {
      return ReadOperation(
        page: log['page'],
        collection: log['collection'],
        operation: log['operation'],
        timestamp: log['timestamp'],
        documentsCount: log['documentsCount'],
      );
    }).toList();

    return AnalyticsData(
      totalReads: _readLogs.length,
      readsByPage: readsByPage,
      readsByCollection: readsByCollection,
      readsByHour: readsByHour,
      recentReads: recentReads,
    );
  }

  // Export data sebagai JSON
  Map<String, dynamic> exportData() {
    return {
      'totalReads': _readLogs.length,
      'logs': _readLogs.map((log) {
        return {
          ...log,
          'timestamp': (log['timestamp'] as DateTime).toIso8601String(),
        };
      }).toList(),
    };
  }
}