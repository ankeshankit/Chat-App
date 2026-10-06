# 💬 Flutter Firebase Chat App

A real-time **Flutter Chat Application** built using **Firebase Authentication, Cloud Firestore, Firebase Cloud Messaging (FCM), Flutter WebRTC and Local Notifications**.

The application provides user authentication, real-time one-to-one messaging, online/offline status, typing indicators, message read/unread status, message reactions, reply functionality, voice calling and call history.

---

## 📱 Project Overview

This project is a WhatsApp-style real-time chat application developed with Flutter.

The main goal of this project is to implement:

- Firebase Authentication
- Real-time chat
- One-to-one messaging
- Online/offline user status
- Last seen
- Typing indicator
- Message read/unread status
- Message reply
- Message reactions
- Delete message for me
- Delete message for everyone
- Push notifications
- Local notifications
- Voice calling
- WebRTC signaling
- Call history
- User profile
- Custom application icon
- Android APK generation

---

# ✨ Features

## 🔐 Authentication

- User Registration
- User Login
- Firebase Authentication
- Email & Password authentication
- User name
- Phone number
- Email
- Password
- Persistent login session
- Logout
- Firebase authentication state handling

---

## 👤 User Profile

Each user has a profile containing:

- Name
- Email
- Phone number
- Profile image field
- Online status
- Last seen
- Account creation date

---

## 💬 Real-Time Chat

Users can chat with other registered users in real time.

### Chat Features

- One-to-one chat
- Real-time messages
- Text messages
- Message timestamp
- Sender/receiver identification
- Last message preview
- Recent chat list
- Automatic chat room creation
- Chat room based on two user IDs

## 🏠 Home Screen

The Home Screen contains:

Recent Chat List
Search / New Chat
Call History
Profile
Logout
New Chat Floating Action Button

## 👥 Users Screen

The Users Screen displays all registered users.

The current logged-in user is excluded from the list.

Users can select another user and start a conversation.

## 💬 Real-Time Chat

The application provides real-time one-to-one messaging using Cloud Firestore.

Chat Features
Send text messages
Receive text messages
Real-time updates
Message timestamp
Sender information
Receiver information
Last message
Recent chat preview
Automatic chat room creation
Real-time chat list updates

## 📨 Message Feture
 📖 Read / Unread Messages
 👤 Online / Offline Status
 Message Status
  🔢 Unread Message Count
  ⌨️ Typing Indicator
  ↩️ Reply to Message
  😊 Message Reactions

🗑️ Message Delete
  Delete for Me
  Delete for Everyone

## 📞 Voice Calling

The application supports one-to-one voice calling and same wi-fi calling feture  using :

flutter_webrtc
Voice Call Features
Start Voice Call
Incoming Voice Call
Accept Call
End Call
Microphone Permission
Audio Stream
WebRTC Peer Connection
Offer / Answer
ICE Candidates
Firestore Signaling
Call Status
Call History


### 📄 pubspec.yaml Dependencies

# 📦 Dependencies

## Dependencies```yaml
dependencies:
  flutter:
    sdk: flutter

  firebase_core:
  firebase_auth:
  cloud_firestore:
  firebase_storage:
  firebase_messaging:
  flutter_local_notifications:
  flutter_webrtc:

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints:
  flutter_launcher_icons:






### 📋 Install All Dependencies

flutter pub add firebase_core
flutter pub add firebase_auth
flutter pub add cloud_firestore
flutter pub add firebase_storage
flutter pub add firebase_messaging
flutter pub add flutter_local_notifications
flutter pub add flutter_webrtc
flutter pub add --dev flutter_launcher_icons

Then:

flutter pub get


## 🎨 Application Icon
  flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/chat_icon.png"
  min_sdk_android: 21



# 🔥 Firebase Setup & Connection

This project uses Firebase for authentication, real-time chat, notifications, and call signaling.

## Firebase Services Used

- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging (FCM)
- Firebase Storage
- Firebase Core

---

## 🔗 Connect Flutter App with Firebase

### 1. Install Firebase CLI

Login to Firebase:

firebase login

Check Firebase projects:

firebase projects:list
2. Install FlutterFire CLI
dart pub global activate flutterfire_cli

3. Configure Firebase

From the Flutter project root directory:

flutterfire configure

Select your Firebase project and platforms:

Android
iOS

This generates:

lib/firebase_options.dart


## 🔄 Complete Application Flow

                         ┌───────────────────┐
                         │  Login / Register │
                         └─────────┬─────────┘
                                   │
                                   ▼
                         ┌───────────────────┐
                         │       Home        │
                         │    Chat List      │
                         └─────────┬─────────┘
                                   │
             ┌─────────────────────┼─────────────────────┐
             │                     │                     │
             ▼                     ▼                     ▼
         Profile               New Chat            Call History
                                   │
                                   ▼
                              Users List
                                   │
                                   ▼
                              Chat Screen
                                   │
                         ┌─────────┴─────────┐
                         │                   │
                         ▼                   ▼
                     Messaging           Voice Call
                         │                   │
                         ▼                   ▼
                     Firestore            WebRTC
  
  
  




## 🏗️ Application Architecture

┌─────────────────────────────────────────────┐
│                  Flutter UI                 │
│                                             │
│ Login | Home | Chat | Profile | Call       │
└──────────────────────┬──────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────┐
│                  Services                   │
│                                             │
│ AuthService                                 │
│ CallService                                 │
│ NotificationService                         │
│ LocalNotificationService                    │
│ IncomingCallService                         │
└──────────────────────┬──────────────────────┘
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
       Firebase Services       WebRTC
             │                   │
       ┌─────┼─────┐             │
       │     │     │             │
       ▼     ▼     ▼             ▼
      Auth Firestore FCM      Voice Call


## 👨‍💻 Developer
Ankit Kumar

Flutter Developer | Mobile Application Developer

Technologies
Flutter
Dart
Firebase
Android
iOS
WebRTC
Git
GitHub

## 📚 Project Purpose

This project is created to demonstrate a complete real-time communication application using Flutter and Firebase.

It can be used for:

Learning Flutter
Firebase Practice
Portfolio Project
Flutter Developer Interview Preparation
Real-Time Chat Practice
WebRTC Practice
GitHub Portfolio

## ⭐ Support

If you find this project useful:

⭐ Star the repository
🍴 Fork the repository
🐛 Report issues
💡 Suggest improvements
📚 Use it for learning

## 🙏 Thank You

Thank you for checking out this Flutter Firebase Chat Application.

