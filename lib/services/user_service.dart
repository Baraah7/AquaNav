import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/registration/user.dart';
class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<User> getCurrentUser(String uid) async {
    final doc = await _users.doc(uid).get();
    return User.fromMap(doc.data()!);
  }
}
