import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login.dart';
import 'main.dart';

class AppStart extends StatelessWidget {
  const AppStart({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Not logged in
        if (!authSnapshot.hasData) {
          return const LoginScreen();
        }

        final user = authSnapshot.data!;
        final uid = user.uid;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${userSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Check if user document exists, if not create it
            if (userSnapshot.hasData && !userSnapshot.data!.exists) {
              return _CreateUserDocument(user: user);
            }

            return MyHomePage(title: 'Bahaar Home Page');
          },
        );
      },
    );
  }
}

class _CreateUserDocument extends StatefulWidget {
  final User user;
  const _CreateUserDocument({required this.user});

  @override
  State<_CreateUserDocument> createState() => _CreateUserDocumentState();
}

class _CreateUserDocumentState extends State<_CreateUserDocument> {
  bool _isCreating = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createDocument();
  }

  Future<void> _createDocument() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({
        'id': widget.user.uid,
        'email': widget.user.email,
        'user_name': widget.user.displayName ?? widget.user.email?.split('@')[0],
        'is_guest': widget.user.isAnonymous,
      });

      if (mounted) {
        // Trigger a rebuild by navigating
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppStart()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your account...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error creating account: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isCreating = true;
                  _error = null;
                });
                _createDocument();
              },
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
