// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class LocalNotificationService {
//   LocalNotificationService._internal();
//
//   static final LocalNotificationService instance =
//   LocalNotificationService._internal();
//
//   final FlutterLocalNotificationsPlugin
//   flutterLocalNotificationsPlugin =
//   FlutterLocalNotificationsPlugin();
//
//   // ==========================================
//   // INITIALIZE
//   // ==========================================
//
//   Future<void> initialize() async {
//     const AndroidInitializationSettings
//     androidSettings =
//     AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//
//     const DarwinInitializationSettings
//     iosSettings =
//     DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const InitializationSettings settings =
//     InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await flutterLocalNotificationsPlugin.initialize(
//       settings: settings,
//     );
//
//     // Android notification permission
//     final AndroidFlutterLocalNotificationsPlugin?
//     androidPlugin =
//     flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>();
//
//     await androidPlugin?.requestNotificationsPermission();
//   }
//
//   // ==========================================
//   // MESSAGE NOTIFICATION
//   // ==========================================
//
//   Future<void> showMessageNotification({
//     required String senderName,
//     required String message,
//   }) async {
//     const AndroidNotificationDetails
//     androidDetails =
//     AndroidNotificationDetails(
//       'chat_messages',
//       'Chat Messages',
//       channelDescription:
//       'Notifications for new chat messages',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//     );
//
//     const DarwinNotificationDetails
//     iosDetails =
//     DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     const NotificationDetails details =
//     NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     await flutterLocalNotificationsPlugin.show(
//       id: DateTime.now()
//           .millisecondsSinceEpoch ~/ 1000,
//       title: senderName,
//       body: message.isEmpty
//           ? 'New message'
//           : message,
//       notificationDetails: details,
//     );
//   }
//
//   // ==========================================
//   // INCOMING CALL NOTIFICATION
//   // ==========================================
//
//   Future<void> showCallNotification({
//     required String callerName,
//   }) async {
//     const AndroidNotificationDetails
//     androidDetails =
//     AndroidNotificationDetails(
//       'incoming_calls',
//       'Incoming Calls',
//       channelDescription:
//       'Notifications for incoming voice calls',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       fullScreenIntent: true,
//     );
//
//     const DarwinNotificationDetails
//     iosDetails =
//     DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );
//
//     const NotificationDetails details =
//     NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
//
//     await flutterLocalNotificationsPlugin.show(
//       id: DateTime.now()
//           .millisecondsSinceEpoch ~/ 1000,
//       title: 'Incoming Voice Call',
//       body: '$callerName is calling you',
//       notificationDetails: details,
//     );
//   }
//
//   // ==========================================
//   // CANCEL ONE NOTIFICATION
//   // ==========================================
//
//   Future<void> cancelNotification(int id) async {
//     await flutterLocalNotificationsPlugin.cancel(
//       id: id,
//     );
//   }
//
//   // ==========================================
//   // CANCEL ALL
//   // ==========================================
//
//   Future<void> cancelAllNotifications() async {
//     await flutterLocalNotificationsPlugin
//         .cancelAll();
//   }
// }

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._internal();

  static final LocalNotificationService instance =
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin
  flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: settings,
    );

    final AndroidFlutterLocalNotificationsPlugin?
    androidPlugin =
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String message,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription:
      'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: senderName,
      body: message.isEmpty ? 'New message' : message,
      notificationDetails: notificationDetails,
    );
  }

  Future<void> showCallNotification({
    required String callerName,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription:
      'Notifications for incoming voice calls',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true,
    );

    const DarwinNotificationDetails iosDetails =
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Incoming Voice Call',
      body: '$callerName is calling you',
      notificationDetails: notificationDetails,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(
      id: id,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}