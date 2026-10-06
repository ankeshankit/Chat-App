// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// //
// // class AuthService {
// //   final FirebaseAuth _auth = FirebaseAuth.instance;
// //
// //   final FirebaseFirestore _firestore =
// //       FirebaseFirestore.instance;
// //
// //   // ================= REGISTER =================
// //
// //   Future<String?> registerUser({
// //     required String name,
// //     required String email,
// //     required String phone,
// //     required String password,
// //   }) async {
// //     try {
// //       UserCredential credential =
// //       await _auth.createUserWithEmailAndPassword(
// //         email: email.trim(),
// //         password: password.trim(),
// //       );
// //
// //       final user = credential.user;
// //
// //       if (user == null) {
// //         return 'User creation failed';
// //       }
// //
// //       await _firestore
// //           .collection('users')
// //           .doc(user.uid)
// //           .set({
// //         'uid': user.uid,
// //         'name': name.trim(),
// //         'email': email.trim(),
// //         'phone': phone.trim(),
// //         'profileImage': '',
// //         'isOnline': true,
// //         'lastSeen': FieldValue.serverTimestamp(),
// //         'createdAt': FieldValue.serverTimestamp(),
// //       });
// //
// //       return null;
// //     } on FirebaseAuthException catch (e) {
// //       return e.message ?? 'Registration failed';
// //     } catch (e) {
// //       return e.toString();
// //     }
// //   }
// //
// //   // ================= LOGIN =================
// //
// //   Future<String?> loginUser({
// //     required String email,
// //     required String password,
// //   }) async {
// //     try {
// //       UserCredential credential =
// //       await _auth.signInWithEmailAndPassword(
// //         email: email.trim(),
// //         password: password.trim(),
// //       );
// //
// //       final user = credential.user;
// //
// //       if (user == null) {
// //         return 'User not found';
// //       }
// //
// //       await setUserOnline(user.uid);
// //
// //       return null;
// //     } on FirebaseAuthException catch (e) {
// //       return e.message ?? 'Login failed';
// //     } catch (e) {
// //       return e.toString();
// //     }
// //   }
// //
// //   // ================= ONLINE =================
// //
// //   Future<void> setUserOnline(String uid) async {
// //     await _firestore
// //         .collection('users')
// //         .doc(uid)
// //         .set(
// //       {
// //         'isOnline': true,
// //         'lastSeen': FieldValue.serverTimestamp(),
// //       },
// //       SetOptions(merge: true),
// //     );
// //   }
// //
// //   // ================= OFFLINE =================
// //
// //   Future<void> setUserOffline(String uid) async {
// //     await _firestore
// //         .collection('users')
// //         .doc(uid)
// //         .set(
// //       {
// //         'isOnline': false,
// //         'lastSeen': FieldValue.serverTimestamp(),
// //       },
// //       SetOptions(merge: true),
// //     );
// //   }
// //
// //   // ================= LOGOUT =================
// //
// //   Future<void> logout() async {
// //     try {
// //       final user = _auth.currentUser;
// //
// //       if (user != null) {
// //         await setUserOffline(user.uid);
// //       }
// //
// //       await _auth.signOut();
// //     } catch (e) {
// //       await _auth.signOut();
// //     }
// //   }
// //
// //   // ================= CURRENT USER =================
// //
// //   User? get currentUser => _auth.currentUser;
// // }
//
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import 'notification_service.dart';
//
// class AuthService {
//   final FirebaseAuth _auth =
//       FirebaseAuth.instance;
//
//   final FirebaseFirestore _firestore =
//       FirebaseFirestore.instance;
//
//   // =========================
//   // REGISTER USER
//   // =========================
//
//   Future<String?> registerUser({
//     required String name,
//     required String email,
//     required String phone,
//     required String password,
//   }) async {
//     try {
//       // Create Firebase Auth user
//       final UserCredential credential =
//       await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//
//       final User? user = credential.user;
//
//       if (user == null) {
//         return 'User creation failed';
//       }
//
//       // Save user data in Firestore
//       await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .set({
//         'uid': user.uid,
//         'name': name.trim(),
//         'email': email.trim(),
//         'phone': phone.trim(),
//         'profileImage': '',
//         'isOnline': true,
//
//         // FCM Token
//         'fcmToken': '',
//
//         'createdAt':
//         FieldValue.serverTimestamp(),
//
//         'lastSeen':
//         FieldValue.serverTimestamp(),
//       });
//
//       // Save FCM token
//       final NotificationService
//       notificationService =
//       NotificationService();
//
//       await notificationService
//           .saveTokenToFirestore();
//
//       return null;
//     }
//
//     on FirebaseAuthException catch (e) {
//       return e.message ?? 'Registration failed';
//     }
//
//     catch (e) {
//       return e.toString();
//     }
//   }
//
//   // =========================
//   // LOGIN USER
//   // =========================
//
//   Future<String?> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       // Login
//       final UserCredential credential =
//       await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//
//       final User? user = credential.user;
//
//       if (user == null) {
//         return 'User not found';
//       }
//
//       // User online
//       await setUserOnline(user.uid);
//
//       // Save FCM token
//       final NotificationService
//       notificationService =
//       NotificationService();
//
//       await notificationService
//           .saveTokenToFirestore();
//
//       return null;
//     }
//
//     on FirebaseAuthException catch (e) {
//       return e.message ?? 'Login failed';
//     }
//
//     catch (e) {
//       return e.toString();
//     }
//   }
//
//   // =========================
//   // SET USER ONLINE
//   // =========================
//
//   Future<void> setUserOnline(
//       String uid,
//       ) async {
//     await _firestore
//         .collection('users')
//         .doc(uid)
//         .set(
//       {
//         'isOnline': true,
//         'lastSeen':
//         FieldValue.serverTimestamp(),
//       },
//       SetOptions(
//         merge: true,
//       ),
//     );
//   }
//
//   // =========================
//   // SET USER OFFLINE
//   // =========================
//
//   Future<void> setUserOffline(
//       String uid,
//       ) async {
//     await _firestore
//         .collection('users')
//         .doc(uid)
//         .set(
//       {
//         'isOnline': false,
//         'lastSeen':
//         FieldValue.serverTimestamp(),
//       },
//       SetOptions(
//         merge: true,
//       ),
//     );
//   }
//
//   // =========================
//   // LOGOUT
//   // =========================
//
//   Future<void> logout() async {
//     try {
//       final User? user =
//           _auth.currentUser;
//
//       if (user != null) {
//         await setUserOffline(user.uid);
//       }
//
//       await _auth.signOut();
//     } catch (e) {
//       await _auth.signOut();
//     }
//   }
//
//   // =========================
//   // CURRENT USER
//   // =========================
//
//   User? get currentUser {
//     return _auth.currentUser;
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'notification_service.dart';

class AuthService {
  // ============================================================
  // FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;


  // ============================================================
  // REGISTER USER
  // ============================================================

  Future<String?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // --------------------------------------------------------
      // Create Firebase Authentication User
      // --------------------------------------------------------

      final UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;

      if (user == null) {
        return 'User creation failed';
      }

      // --------------------------------------------------------
      // Save User Data in Firestore
      // --------------------------------------------------------

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,

        'name': name.trim(),

        'email': email.trim(),

        'phone': phone.trim(),

        'profileImage': '',

        'isOnline': true,

        'fcmToken': '',

        'createdAt':
        FieldValue.serverTimestamp(),

        'lastSeen':
        FieldValue.serverTimestamp(),
      });

      // --------------------------------------------------------
      // Save FCM Token
      // --------------------------------------------------------

      final NotificationService
      notificationService =
      NotificationService();

      await notificationService
          .saveTokenToFirestore();

      return null;
    }

    // ----------------------------------------------------------
    // Firebase Authentication Error
    // ----------------------------------------------------------

    on FirebaseAuthException catch (e) {
      return e.message ?? 'Registration failed';
    }

    // ----------------------------------------------------------
    // Other Error
    // ----------------------------------------------------------

    catch (e) {
      return e.toString();
    }
  }


  // ============================================================
  // LOGIN USER
  // ============================================================

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // --------------------------------------------------------
      // Firebase Login
      // --------------------------------------------------------

      final UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final User? user = credential.user;

      if (user == null) {
        return 'User not found';
      }

      // --------------------------------------------------------
      // Set User Online
      // --------------------------------------------------------

      await setUserOnline(user.uid);

      // --------------------------------------------------------
      // Save / Update FCM Token
      // --------------------------------------------------------

      final NotificationService
      notificationService =
      NotificationService();

      await notificationService
          .saveTokenToFirestore();

      return null;
    }

    // ----------------------------------------------------------
    // Firebase Authentication Error
    // ----------------------------------------------------------

    on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    }

    // ----------------------------------------------------------
    // Other Error
    // ----------------------------------------------------------

    catch (e) {
      return e.toString();
    }
  }


  // ============================================================
  // SET USER ONLINE
  // ============================================================

  Future<void> setUserOnline(
      String uid,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        'isOnline': true,

        'lastSeen':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }


  // ============================================================
  // SET USER OFFLINE
  // ============================================================

  Future<void> setUserOffline(
      String uid,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(
      {
        'isOnline': false,

        'lastSeen':
        FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }


  // ============================================================
  // LOGOUT
  // ============================================================
  //
  // IMPORTANT:
  // Ye function sirf tab call hoga jab user Logout button
  // press karega.
  //
  // App close karne par is function ko call MAT karna.
  // ============================================================

  Future<void> logout() async {
    try {
      final User? user =
          _auth.currentUser;

      // --------------------------------------------------------
      // User ko offline set karo
      // --------------------------------------------------------

      if (user != null) {
        await setUserOffline(
          user.uid,
        );
      }

      // --------------------------------------------------------
      // Firebase Sign Out
      // --------------------------------------------------------

      await _auth.signOut();
    }

    catch (e) {
      // Agar offline update fail ho jaye,
      // tab bhi Firebase se logout karo.

      await _auth.signOut();
    }
  }


  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }


  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String get currentUserId {
    return _auth.currentUser?.uid ?? '';
  }


  // ============================================================
  // IS USER LOGGED IN?
  // ============================================================

  bool get isLoggedIn {
    return _auth.currentUser != null;
  }
}