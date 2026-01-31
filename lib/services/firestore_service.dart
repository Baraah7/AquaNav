import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/registration/user.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUser(User user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }
}
