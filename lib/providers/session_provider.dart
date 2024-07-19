import 'package:flutter/material.dart';
import 'package:godrage/globals.dart';

class SessionProvider extends ChangeNotifier {
  List<dynamic> _sessions = [];
  List<dynamic> get session => _sessions;

  final Map<String, dynamic> _currentOrder = {};
  Map<String, dynamic> get currentOrder => _currentOrder;

  Future<void> getSessions() async {
    final querySnapshot =
        await sessionsRef.orderBy('createdAt', descending: true).get();
    _sessions = querySnapshot.docs.map((doc) => doc.data()).toList();
    print("sessions: $_sessions");
    print(querySnapshot.docs);
    notifyListeners();
  }
}
