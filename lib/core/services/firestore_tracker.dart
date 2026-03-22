import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/read_tracker_service.dart';

class FirestoreTracker {
  static Future<QuerySnapshot> get({
    required Query query,
    required String page,
    required String collection,
  }) async {
    final snapshot = await query.get();

    ReadTrackerService().trackRead(
      page: page,
      collection: collection,
      documentsCount: snapshot.docs.length,
      operation: 'getMany',
    );

    return snapshot;
  }

  static Future<DocumentSnapshot> getDoc({
    required DocumentReference docRef,
    required String page,
    required String collection,
  }) async {
    final snapshot = await docRef.get();

    ReadTrackerService().trackRead(
      page: page,
      collection: collection,
      documentsCount: 1,
      operation: 'get',
    );

    return snapshot;
  }

  // 🔥 INI YANG PENTING (AUTO PAGE DETECTION)
  static Future<QuerySnapshot> autoGet(Query query) async {
    final snapshot = await query.get();

    ReadTrackerService().trackRead(
      page: _getCallerPage(),
      collection: query.parameters['path'] ?? 'unknown',
      documentsCount: snapshot.docs.length,
      operation: 'getMany',
    );

    return snapshot;
  }

  static String _getCallerPage() {
    final stack = StackTrace.current.toString();

    // ambil baris yang mengandung "page"
    final lines = stack.split('\n');
    for (var line in lines) {
      if (line.contains('Page')) {
        return line.trim();
      }
    }

    return 'UnknownPage';
  }
}