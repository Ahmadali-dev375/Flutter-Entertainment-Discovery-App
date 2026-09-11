// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   Future<void> signInWithGoogle() async {
//     print('Starting Google Sign-In...');
//     try {
//       // Trigger the authentication flow
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         print('Google sign-in aborted by user');
//         return;
//       }

//       print('Google user signed in: ${googleUser.email}');

//       // Obtain the auth details from the request
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // Create a new credential
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase
//       UserCredential userCredential = await _auth.signInWithCredential(
//         credential,
//       );

//       final User? user = userCredential.user;

//       if (user == null) {
//         print('User is null after sign-in');
//         return;
//       }

//       print('Firebase user: ${user.uid} - ${user.email}');

//       // Save user profile in Firestore
//       await _firestore.collection('users').doc(user.uid).set({
//         'uid': user.uid,
//         'name': user.displayName,
//         'email': user.email,
//         'photoUrl': user.photoURL,
//         'signedInAt': Timestamp.now(),
//       }, SetOptions(merge: true));

//       print('User data written to Firestore');

//       // Sync local data from SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       final localUsername = prefs.getString('username') ?? '';

//       if (localUsername.isNotEmpty) {
//         await _firestore.collection('users').doc(user.uid).update({
//           'localUsername': localUsername,
//         });
//         print('Local data synced to Firestore: $localUsername');
//       }
//     } catch (e, stackTrace) {
//       print('Google Sign-In failed: $e');
//       print(stackTrace);
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//     print('User signed out.');
//   }

//   User? get currentUser => _auth.currentUser;
// }
