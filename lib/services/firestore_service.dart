import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registration/user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUser(User user) async {
    print('FirestoreService: Creating user document for ${user.id}');
    try {
      await _db.collection('users').doc(user.id).set(user.toMap());
      print('FirestoreService: Document created successfully');
    } catch (e) {
      print('FirestoreService: Error creating document: $e');
      rethrow;
    }
  }

  Future<bool> userExists(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists;
  }
}
