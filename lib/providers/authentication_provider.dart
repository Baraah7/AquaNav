import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/authentication_service.dart';
import '../services/firestore_service.dart';
import '../models/registration/user.dart' as AppUser;

class AuthProvider with ChangeNotifier {
  final AuthenticationService _AuthenticationService = AuthenticationService();
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = false;
  String? error;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = await _AuthenticationService.register(email, password, displayName: name);

      if (user != null) {
        final appUser = AppUser.User(
          id: user.uid,
          email: user.email ?? email,
          userName: name,
          password: password,
        );
        await _firestoreService.createUser(appUser);
        print('User document created successfully for ${user.uid}');
      } else {
        error = 'Registration failed - no user returned';
      }
    } catch (e) {
      error = e.toString();
      print('Registration error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
