import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final CollectionReference _users = FirebaseFirestore.instance.collection('users');

  // Sign in with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> register(String email, String password, {String? displayName}) async {
    UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Set display name if provided
    if (displayName != null && userCredential.user != null) {
      await userCredential.user!.updateDisplayName(displayName);
    }

    return userCredential.user;
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> upgradeGuest({
  required String email,
  required String password,
  required String userName,
}) async {
  final user = _firebaseAuth.currentUser!;
  final credential = EmailAuthProvider.credential(
    email: email,
    password: password,
  );

  await user.linkWithCredential(credential);

  await _users.doc(user.uid).update({
    'email': email,
    'user_name': userName,
    'is_guest': false,
  });
}

}