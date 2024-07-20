import 'package:cloud_firestore/cloud_firestore.dart';

final firestore = FirebaseFirestore.instance;
final sessionsRef = firestore.collection('sessions');
final favouritesRef = firestore.collection('favourites');
