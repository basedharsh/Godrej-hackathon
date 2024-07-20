import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionProvider extends ChangeNotifier {
  List<dynamic> _sessions = [];
  List<dynamic> get sessions => _sessions;

  Future<void> getSessions() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('sessions').get();

      _sessions = querySnapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching sessions: $e");
      }
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSessionStream(
      String sessionID) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionID)
        .snapshots();
  }

  Future<String> getSessionName(String sessionID) async {
    final sessionDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionID)
        .get();
    return sessionDoc['name'] as String;
  }

  void addSession(Map<String, dynamic> session) {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
