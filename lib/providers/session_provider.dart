import 'package:flutter/material.dart';
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
      print("Error fetching sessions: $e");
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getSessionStream(
      String sessionID) {
    return FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionID)
        .snapshots();
  }

  void addSession(Map<String, dynamic> session) {
    _sessions.insert(0, session);
    notifyListeners();
  }
}
