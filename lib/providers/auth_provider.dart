// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';
import '../services/local_storage_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ FIXED: Correct initialization for google_sign_in ^6.2.1 with serverClientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // ✅ REQUIRED: Add the web client ID from your google-services.json
    serverClientId:
        '199184765065-99rfj6tg5ou8h6eviccrovcp3sk49bk7.apps.googleusercontent.com',
  );

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  // Rest of your constructor and methods remain the same...
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        // When user logs in, sync data
        _syncDataOnLogin(user);
      }
      notifyListeners();
    });
  }

  // ✅ FIXED: Correct Google Sign-In method for version 6.2.1
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();
      print('→ initializing Google Sign-In');

      // First sign out to ensure clean state
      await _googleSignIn.signOut();
      print('→ authenticating...');

      // ✅ For version 6.2.1: Use signIn() method
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        print('❌ User canceled Google Sign-In');
        _setLoading(false);
        return false;
      }

      print('✅ Google user signed in: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ✅ For version 6.2.1: Both accessToken and idToken are available
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      if (userCredential.user != null) {
        await _ensureUserDocument(userCredential.user!);

        // Sync data after successful Google login
        await _syncDataOnLogin(userCredential.user!);

        _user = userCredential.user;
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _setError(_getErrorMessage(e));
    } on PlatformException catch (e) {
      print('Platform Error: ${e.code} - ${e.message}');
      _setError('Google sign in failed. Please try again.');
    } catch (e) {
      print('General Error: $e');
      _setError('Google sign in failed. Please try again.');
    }

    _setLoading(false);
    return false;
  }

  // Your other methods remain the same...
  Future<bool> signUp(String email, String password, String name) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await _createUserDocument(userCredential.user!, name, email);
        await _syncDataOnLogin(userCredential.user!);
        _user = userCredential.user;
        _setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      print('Signup error: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _clearError();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user;
        await _syncDataOnLogin(userCredential.user!);
        _setLoading(false);
        return true;
      }
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e));
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      print('Signin error: $e');
    }

    _setLoading(false);
    return false;
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      // Clear local watchlist and owner to prevent cross-account leakage
      await LocalStorageService.clearWatchlist();
      await LocalStorageService.setWatchlistOwner(null);
      _clearError();
    } catch (e) {
      _setError('Failed to sign out. Please try again.');
      print('Signout error: $e');
    }
    notifyListeners();
  }

  // Add your other helper methods here...
  Future<void> _syncDataOnLogin(User user) async {
    try {
      print('🔄 Starting data sync for user: ${user.uid}');
      final previousOwner = await LocalStorageService.getWatchlistOwner();
      final firebaseMovies = await FirebaseService.fetchWatchlistFromFirebase(
        user.uid,
      );

      // If local data belongs to another user or ownership cannot be established,
      // wipe local storage to prevent cross-account leakage/uploads.
      if (previousOwner != user.uid) {
        await LocalStorageService.clearWatchlist();
        await LocalStorageService.saveWatchlist(firebaseMovies);
        await LocalStorageService.setWatchlistOwner(user.uid);
        return;
      }

      // If already owned by this user, update local storage with remote source of truth
      await LocalStorageService.saveWatchlist(firebaseMovies);
      await LocalStorageService.setWatchlistOwner(user.uid);
    } catch (e) {
      print('❌ Error during data sync: $e');
    }
  }

  Future<void> _createUserDocument(User user, String name, String email) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'displayName': user.displayName ?? name,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'preferences': {
          'favoriteGenres': [],
          'favoriteActors': [],
          'favoriteDirectors': [],
          'favoriteTitles': [],
        },
        'watchlist': [],
        'watchHistory': [],
      });
    } catch (e) {
      print('❌ Error creating user document: $e');
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _createUserDocument(
          user,
          user.displayName ?? 'User',
          user.email ?? '',
        );
      } else {
        await _firestore.collection('users').doc(user.uid).update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('❌ Error ensuring user document: $e');
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();
}
