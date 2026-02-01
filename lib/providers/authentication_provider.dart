import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/registration/authentication_service.dart';
import '../services/firestore_service.dart';
import '../models/registration/user.dart' as AppUser;

class AuthProvider with ChangeNotifier {
  final AuthenticationService _AuthenticationService = AuthenticationService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  String? error;
  AppUser.User? _currentAppUser;

  /// Returns the current Firebase Auth user
  fb.User? get currentFirebaseUser => _AuthenticationService.getCurrentUser();

  /// Returns the current app user with full profile data
  AppUser.User? get currentAppUser => _currentAppUser;

  /// Returns true if a user is logged in
  bool get isLoggedIn => currentFirebaseUser != null;

  /// Returns true if the current user is a guest
  bool get isGuest => _currentAppUser?.isGuest ?? false;

  /// Initializes the auth state by checking for an existing Firebase session
  /// and fetching the user profile if found
  Future<void> initializeAuthState() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser != null && _currentAppUser == null) {
      // User is logged in via Firebase but we don't have their profile yet
      if (firebaseUser.isAnonymous) {
        _currentAppUser = AppUser.User.guest(id: firebaseUser.uid);
        notifyListeners();
      } else {
        await fetchCurrentUserProfile();
      }
    }
  }

  /// Fetches the current user's profile from Firestore
  Future<AppUser.User?> fetchCurrentUserProfile() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;

    try {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _currentAppUser = AppUser.User.fromMap({...doc.data()!, 'id': doc.id});
        notifyListeners();
        return _currentAppUser;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

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
        _currentAppUser = appUser;
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

      // Fetch user profile from Firestore
      await fetchCurrentUserProfile();
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

      // Create guest user profile
      _currentAppUser = AppUser.User.guest(id: user.uid);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _AuthenticationService.signOut();
    _currentAppUser = null;
    notifyListeners();
  }
}

final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});
