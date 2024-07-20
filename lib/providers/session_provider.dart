import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionProvider extends ChangeNotifier {
  List<dynamic> _sessions = [];
  List<dynamic> get sessions => _sessions;

  Future<void> getSessions() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('sessions')
          .orderBy('created_at', descending: true)
          .get();

      _sessions = querySnapshot.docs.map((doc) => doc.data()).toList();
      notifyListeners();
    } catch (e) {
      print("Error fetching sessions: $e");
    }
  }
}
