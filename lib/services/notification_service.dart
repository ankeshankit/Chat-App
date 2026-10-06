// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
//
// import '../firebase_options.dart';
//
// class NotificationService {
//   final FirebaseMessaging messaging =
//       FirebaseMessaging.instance;
//
//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;
//
//   final FirebaseAuth auth =
//       FirebaseAuth.instance;
//
//   // =========================
//   // INITIALIZE NOTIFICATION
//   // =========================
//
//   Future<void> initialize() async {
//     try {
//       // Request notification permission
//       final NotificationSettings settings =
//       await messaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         announcement: false,
//         carPlay: false,
//         criticalAlert: false,
//         provisional: false,
//       );
//
//       debugPrint(
//         'Notification Permission: '
//             '${settings.authorizationStatus}',
//       );
//
//       // Show notification when app is in foreground
//       await messaging
//           .setForegroundNotificationPresentationOptions(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//
//       // Get FCM token
//       final String? token =
//       await messaging.getToken();
//
//       debugPrint('==============================');
//       debugPrint('FCM TOKEN');
//       debugPrint('$token');
//       debugPrint('==============================');
//
//       // Save token if user is logged in
//       await saveTokenToFirestore(
//         token: token,
//       );
//
//       // Token refresh listener
//       messaging.onTokenRefresh.listen(
//             (String newToken) async {
//           debugPrint(
//             'FCM TOKEN REFRESHED',
//           );
//
//           debugPrint(newToken);
//
//           await saveTokenToFirestore(
//             token: newToken,
//           );
//         },
//       );
//
//       // Foreground notification
//       FirebaseMessaging.onMessage.listen(
//             (RemoteMessage message) {
//           debugPrint(
//             '==============================',
//           );
//
//           debugPrint(
//             'FOREGROUND NOTIFICATION',
//           );
//
//           debugPrint(
//             'Title: '
//                 '${message.notification?.title}',
//           );
//
//           debugPrint(
//             'Body: '
//                 '${message.notification?.body}',
//           );
//
//           debugPrint(
//             'Data: ${message.data}',
//           );
//
//           debugPrint(
//             '==============================',
//           );
//         },
//       );
//
//       // App opened from background notification
//       FirebaseMessaging.onMessageOpenedApp.listen(
//             (RemoteMessage message) {
//           debugPrint(
//             'NOTIFICATION OPENED FROM BACKGROUND',
//           );
//
//           debugPrint(
//             'Data: ${message.data}',
//           );
//
//           handleNotificationTap(message);
//         },
//       );
//
//       // App opened from terminated state
//       final RemoteMessage? initialMessage =
//       await messaging.getInitialMessage();
//
//       if (initialMessage != null) {
//         debugPrint(
//           'NOTIFICATION OPENED FROM TERMINATED APP',
//         );
//
//         debugPrint(
//           'Data: ${initialMessage.data}',
//         );
//
//         handleNotificationTap(
//           initialMessage,
//         );
//       }
//     } catch (e) {
//       debugPrint(
//         'NOTIFICATION INITIALIZATION ERROR: $e',
//       );
//     }
//   }
//
//   // =========================
//   // SAVE FCM TOKEN
//   // =========================
//
//   Future<void> saveTokenToFirestore({
//     String? token,
//   }) async {
//     try {
//       final User? user =
//           auth.currentUser;
//
//       if (user == null) {
//         debugPrint(
//           'User not logged in. '
//               'FCM token will be saved after login.',
//         );
//
//         return;
//       }
//
//       final String? fcmToken =
//           token ?? await messaging.getToken();
//
//       if (fcmToken == null ||
//           fcmToken.isEmpty) {
//         debugPrint(
//           'FCM token is empty',
//         );
//
//         return;
//       }
//
//       await firestore
//           .collection('users')
//           .doc(user.uid)
//           .set(
//         {
//           'fcmToken': fcmToken,
//           'fcmTokenUpdatedAt':
//           FieldValue.serverTimestamp(),
//         },
//         SetOptions(
//           merge: true,
//         ),
//       );
//
//       debugPrint(
//         'FCM TOKEN SAVED SUCCESSFULLY',
//       );
//     } catch (e) {
//       debugPrint(
//         'FCM TOKEN SAVE ERROR: $e',
//       );
//     }
//   }
//
//   // =========================
//   // HANDLE NOTIFICATION TAP
//   // =========================
//
//   void handleNotificationTap(
//       RemoteMessage message,
//       ) {
//     final String type =
//         message.data['type']?.toString() ?? '';
//
//     final String callId =
//         message.data['callId']?.toString() ?? '';
//
//     final String chatRoomId =
//         message.data['chatRoomId']?.toString() ?? '';
//
//     debugPrint(
//       'Notification Type: $type',
//     );
//
//     debugPrint(
//       'Call ID: $callId',
//     );
//
//     debugPrint(
//       'Chat Room ID: $chatRoomId',
//     );
//
//     if (type == 'message') {
//       debugPrint(
//         'MESSAGE NOTIFICATION CLICKED',
//       );
//
//       // ChatScreen navigation
//       // next step mein add karenge.
//     }
//
//     if (type == 'call') {
//       debugPrint(
//         'CALL NOTIFICATION CLICKED',
//       );
//
//       // IncomingCallScreen navigation
//       // next step mein add karenge.
//     }
//   }
// }
//
//
// // ==========================================
// // BACKGROUND FCM HANDLER
// // ==========================================
//
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(
//     RemoteMessage message,
//     ) async {
//   try {
//     await Firebase.initializeApp(
//       options:
//       DefaultFirebaseOptions.currentPlatform,
//     );
//
//     debugPrint(
//       '==============================',
//     );
//
//     debugPrint(
//       'BACKGROUND FCM NOTIFICATION',
//     );
//
//     debugPrint(
//       'Message ID: '
//           '${message.messageId}',
//     );
//
//     debugPrint(
//       'Title: '
//           '${message.notification?.title}',
//     );
//
//     debugPrint(
//       'Body: '
//           '${message.notification?.body}',
//     );
//
//     debugPrint(
//       'Data: ${message.data}',
//     );
//
//     debugPrint(
//       '==============================',
//     );
//   } catch (e) {
//     debugPrint(
//       'BACKGROUND FCM ERROR: $e',
//     );
//   }
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'local_notification_service.dart';

class NotificationService {
  final FirebaseMessaging messaging =
      FirebaseMessaging.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      // --------------------------------------------------------
      // REQUEST PERMISSION
      // --------------------------------------------------------

      final NotificationSettings settings =
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      debugPrint(
        'Notification Permission: '
            '${settings.authorizationStatus}',
      );

      // --------------------------------------------------------
      // FOREGROUND NOTIFICATION PRESENTATION
      // --------------------------------------------------------

      await messaging
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // --------------------------------------------------------
      // GET FCM TOKEN
      // --------------------------------------------------------

      final String? token =
      await messaging.getToken();

      debugPrint('==============================');
      debugPrint('FCM TOKEN');
      debugPrint('$token');
      debugPrint('==============================');

      // --------------------------------------------------------
      // SAVE TOKEN
      // --------------------------------------------------------

      await saveTokenToFirestore(
        token: token,
      );

      // --------------------------------------------------------
      // TOKEN REFRESH
      // --------------------------------------------------------

      messaging.onTokenRefresh.listen(
            (String newToken) async {
          debugPrint(
            'FCM TOKEN REFRESHED',
          );

          debugPrint(newToken);

          await saveTokenToFirestore(
            token: newToken,
          );
        },
      );

      // --------------------------------------------------------
      // FOREGROUND MESSAGE
      // --------------------------------------------------------

      FirebaseMessaging.onMessage.listen(
            (RemoteMessage message) async {
          debugPrint(
            '==============================',
          );

          debugPrint(
            'FOREGROUND FCM MESSAGE',
          );

          debugPrint(
            'Message ID: ${message.messageId}',
          );

          debugPrint(
            'Title: ${message.notification?.title}',
          );

          debugPrint(
            'Body: ${message.notification?.body}',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          debugPrint(
            '==============================',
          );

          // --------------------------------------------------
          // SHOW LOCAL NOTIFICATION
          // --------------------------------------------------

          final String title =
              message.notification?.title ??
                  message.data['title']?.toString() ??
                  'New Notification';

          final String body =
              message.notification?.body ??
                  message.data['body']?.toString() ??
                  'You have a new notification';

          await LocalNotificationService
              .instance
              .showMessageNotification(
            senderName: title,
            message: body,
          );
        },
      );

      // --------------------------------------------------------
      // NOTIFICATION OPENED FROM BACKGROUND
      // --------------------------------------------------------

      FirebaseMessaging.onMessageOpenedApp.listen(
            (RemoteMessage message) {
          debugPrint(
            '==============================',
          );

          debugPrint(
            'NOTIFICATION OPENED',
          );

          debugPrint(
            'Data: ${message.data}',
          );

          debugPrint(
            '==============================',
          );

          handleNotificationTap(
            message,
          );
        },
      );

      // --------------------------------------------------------
      // NOTIFICATION OPENED FROM TERMINATED STATE
      // --------------------------------------------------------

      final RemoteMessage? initialMessage =
      await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint(
          'NOTIFICATION OPENED FROM TERMINATED APP',
        );

        debugPrint(
          'Data: ${initialMessage.data}',
        );

        handleNotificationTap(
          initialMessage,
        );
      }
    } catch (e) {
      debugPrint(
        'NOTIFICATION INITIALIZATION ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE FCM TOKEN
  // ============================================================

  Future<void> saveTokenToFirestore({
    String? token,
  }) async {
    try {
      final User? user =
          auth.currentUser;

      if (user == null) {
        debugPrint(
          'User not logged in. '
              'FCM token will be saved after login.',
        );

        return;
      }

      final String? fcmToken =
          token ?? await messaging.getToken();

      if (fcmToken == null ||
          fcmToken.isEmpty) {
        debugPrint(
          'FCM token is empty',
        );

        return;
      }

      await firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': fcmToken,
          'fcmTokenUpdatedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'FCM TOKEN SAVED SUCCESSFULLY',
      );
    } catch (e) {
      debugPrint(
        'FCM TOKEN SAVE ERROR: $e',
      );
    }
  }

  // ============================================================
  // HANDLE NOTIFICATION TAP
  // ============================================================

  void handleNotificationTap(
      RemoteMessage message,
      ) {
    final String type =
        message.data['type']?.toString() ?? '';

    final String callId =
        message.data['callId']?.toString() ?? '';

    final String chatRoomId =
        message.data['chatRoomId']?.toString() ?? '';

    debugPrint(
      'Notification Type: $type',
    );

    debugPrint(
      'Call ID: $callId',
    );

    debugPrint(
      'Chat Room ID: $chatRoomId',
    );

    if (type == 'message') {
      debugPrint(
        'MESSAGE NOTIFICATION CLICKED',
      );

      // ChatScreen navigation later
    }

    if (type == 'call') {
      debugPrint(
        'CALL NOTIFICATION CLICKED',
      );

      // IncomingCallScreen navigation later
    }
  }
}


// ============================================================
// FCM BACKGROUND HANDLER
// ============================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  try {
    await Firebase.initializeApp(
      options:
      DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint(
      '==============================',
    );

    debugPrint(
      'BACKGROUND FCM MESSAGE',
    );

    debugPrint(
      'Message ID: ${message.messageId}',
    );

    debugPrint(
      'Title: ${message.notification?.title}',
    );

    debugPrint(
      'Body: ${message.notification?.body}',
    );

    debugPrint(
      'Data: ${message.data}',
    );

    debugPrint(
      '==============================',
    );
  } catch (e) {
    debugPrint(
      'BACKGROUND FCM ERROR: $e',
    );
  }
}