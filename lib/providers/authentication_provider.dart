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
    required String firstName,
    required String lastName,
    required String userName,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final displayName = '$firstName $lastName';
      final user = await _AuthenticationService.register(email, password, displayName: displayName);

      if (user != null) {
        final appUser = AppUser.User(
          id: user.uid,
          email: user.email ?? email,
          firstName: firstName,
          lastName: lastName,
          userName: userName,
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

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = await _AuthenticationService.login(email, password);

      if (user == null) {
        error = 'Invalid email or password';
        return false;
      }
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInAsGuest() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final user = await _AuthenticationService.signInAsGuest();

      if (user == null) {
        error = 'Failed to sign in as guest';
        return false;
      }
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
