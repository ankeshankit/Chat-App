// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:flutter/material.dart';
// //
// // import 'firebase_options.dart';
// // import 'views/auth/login_screen.dart';
// //
// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //   await Firebase.initializeApp(
// //     options: DefaultFirebaseOptions.currentPlatform,
// //   );
// //
// //   runApp(const ChatApp());
// // }
// //
// // class ChatApp extends StatelessWidget {
// //   const ChatApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       title: 'Chat App',
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(
// //           seedColor: Colors.blue,
// //         ),
// //         useMaterial3: true,
// //       ),
// //       home: const LoginScreen(),
// //     );
// //   }
// // }
//
//
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
//
// import 'firebase_options.dart';
// import 'services/local_notification_service.dart';
// import 'services/notification_service.dart';
// import 'views/auth/login_screen.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // ==========================================
//   // FIREBASE INITIALIZATION
//   // ==========================================
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   // ==========================================
//   // LOCAL NOTIFICATION INITIALIZATION
//   // ==========================================
//
//   await LocalNotificationService.instance.initialize();
//
//   // ==========================================
//   // FCM BACKGROUND HANDLER
//   // ==========================================
//
//   FirebaseMessaging.onBackgroundMessage(
//     firebaseMessagingBackgroundHandler,
//   );
//
//   // ==========================================
//   // FCM NOTIFICATION SERVICE
//   // ==========================================
//
//   final NotificationService notificationService =
//   NotificationService();
//
//   await notificationService.initialize();
//
//   // ==========================================
//   // RUN APP
//   // ==========================================
//
//   runApp(const ChatApp());
// }
//
// class ChatApp extends StatelessWidget {
//   const ChatApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Chat App',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.blue,
//         ),
//         useMaterial3: true,
//       ),
//       home: const LoginScreen(),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'services/local_notification_service.dart';
import 'services/notification_service.dart';
import 'views/auth/login_screen.dart';
import 'views/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ============================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // ============================================================

  await LocalNotificationService.instance.initialize();

  // ============================================================
  // FCM BACKGROUND HANDLER
  // ============================================================

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // ============================================================
  // FCM NOTIFICATION SERVICE
  // ============================================================

  final NotificationService notificationService =
  NotificationService();

  await notificationService.initialize();

  // ============================================================
  // RUN APP
  // ============================================================

  runApp(const ChatApp());
}


// ============================================================
// CHAT APP
// ============================================================

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Chat App',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),

      // IMPORTANT:
      // LoginScreen directly nahi lagana hai.
      // AuthGate decide karega Login ya Home.
      home: const AuthGate(),
    );
  }
}


// ============================================================
// AUTH GATE
// ============================================================
//
// Firebase check karega:
// User logged in hai  -> HomeScreen
// User logged out hai -> LoginScreen
//
// App close karne par Firebase session automatically delete
// nahi hota.
// ============================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),

      builder: (
          BuildContext context,
          AsyncSnapshot<User?> snapshot,
          ) {

        // --------------------------------------------------------
        // Firebase authentication check ho raha hai
        // --------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // --------------------------------------------------------
        // USER LOGGED IN
        // --------------------------------------------------------

        if (snapshot.hasData &&
            snapshot.data != null) {
          return const HomeScreen();
        }

        // --------------------------------------------------------
        // USER LOGGED OUT
        // --------------------------------------------------------

        return const LoginScreen();
      },
    );
  }
}