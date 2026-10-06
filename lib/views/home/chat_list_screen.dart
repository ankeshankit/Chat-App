// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// import '../../models/user_model.dart';
// import '../chat/chat_screen.dart';
//
// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({
//     super.key,
//   });
//
//   @override
//   State<ChatListScreen> createState() =>
//       _ChatListScreenState();
// }
//
// class _ChatListScreenState
//     extends State<ChatListScreen> {
//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;
//
//   final FirebaseAuth auth =
//       FirebaseAuth.instance;
//
//   // =====================================================
//   // CURRENT USER ID
//   // =====================================================
//
//   String get currentUserId {
//     return auth.currentUser?.uid ?? '';
//   }
//
//   // =====================================================
//   // GET USER
//   // =====================================================
//
//   Future<UserModel?> getUser(
//       String uid,
//       ) async {
//     try {
//       final DocumentSnapshot doc =
//       await firestore
//           .collection('users')
//           .doc(uid)
//           .get();
//
//       if (!doc.exists) {
//         return null;
//       }
//
//       final data =
//       doc.data() as Map<String, dynamic>;
//
//       return UserModel.fromMap(
//         data,
//         doc.id,
//       );
//     } catch (e) {
//       debugPrint(
//         'Get user error: $e',
//       );
//
//       return null;
//     }
//   }
//
//   // =====================================================
//   // FORMAT TIME
//   // =====================================================
//
//   String formatChatTime(
//       Timestamp? timestamp,
//       ) {
//     if (timestamp == null) {
//       return '';
//     }
//
//     final DateTime date =
//     timestamp.toDate();
//
//     final DateTime now =
//     DateTime.now();
//
//     final bool isToday =
//         date.year == now.year &&
//             date.month == now.month &&
//             date.day == now.day;
//
//     final int hour = date.hour > 12
//         ? date.hour - 12
//         : date.hour == 0
//         ? 12
//         : date.hour;
//
//     final String minute =
//     date.minute
//         .toString()
//         .padLeft(2, '0');
//
//     final String period =
//     date.hour >= 12
//         ? 'PM'
//         : 'AM';
//
//     if (isToday) {
//       return '$hour:$minute $period';
//     }
//
//     final DateTime yesterday =
//     now.subtract(
//       const Duration(days: 1),
//     );
//
//     final bool isYesterday =
//         date.year == yesterday.year &&
//             date.month == yesterday.month &&
//             date.day == yesterday.day;
//
//     if (isYesterday) {
//       return 'Yesterday';
//     }
//
//     return '${date.day}/${date.month}/${date.year}';
//   }
//
//   // =====================================================
//   // OPEN CHAT
//   // =====================================================
//
//   Future<void> openChat(
//       UserModel user,
//       ) async {
//     await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ChatScreen(
//           receiver: user,
//         ),
//       ),
//     );
//   }
//
//   // =====================================================
//   // LAST MESSAGE
//   // =====================================================
//
//   Widget buildLastMessage({
//     required String lastMessage,
//     required String lastMessageType,
//     required String lastMessageSenderId,
//     required int unreadCount,
//   }) {
//     String displayMessage =
//         lastMessage;
//
//     if (lastMessage.isEmpty) {
//       displayMessage =
//       'No messages yet';
//     }
//
//     if (lastMessageType == 'image') {
//       displayMessage =
//       '📷 Image';
//     }
//
//     if (lastMessage ==
//         'This message was deleted') {
//       displayMessage =
//       '🚫 This message was deleted';
//     }
//
//     final bool isMyMessage =
//         lastMessageSenderId ==
//             currentUserId;
//
//     return Row(
//       children: [
//         // My message tick
//         if (isMyMessage &&
//             lastMessage.isNotEmpty)
//           Padding(
//             padding:
//             const EdgeInsets.only(
//               right: 4,
//             ),
//             child: Icon(
//               Icons.done_all,
//               size: 15,
//               color: unreadCount == 0
//                   ? Colors.blue
//                   : Colors.grey,
//             ),
//           ),
//
//         Expanded(
//           child: Text(
//             displayMessage,
//             maxLines: 1,
//             overflow:
//             TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 13,
//               color: unreadCount > 0
//                   ? Colors.black87
//                   : Colors.grey.shade600,
//               fontWeight:
//               unreadCount > 0
//                   ? FontWeight.w600
//                   : FontWeight.normal,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // =====================================================
//   // EMPTY CHAT
//   // =====================================================
//
//   Widget emptyChatList() {
//     return Center(
//       child: Column(
//         mainAxisAlignment:
//         MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.chat_bubble_outline,
//             size: 70,
//             color: Colors.grey.shade400,
//           ),
//
//           const SizedBox(
//             height: 15,
//           ),
//
//           const Text(
//             'No chats yet',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight:
//               FontWeight.w600,
//             ),
//           ),
//
//           const SizedBox(
//             height: 6,
//           ),
//
//           Text(
//             'Start a conversation with someone',
//             style: TextStyle(
//               color:
//               Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // =====================================================
//   // CHAT ITEM
//   // =====================================================
//
//   Widget chatItem(
//       QueryDocumentSnapshot chatDoc,
//       ) {
//     final data =
//     chatDoc.data()
//     as Map<String, dynamic>;
//
//     // Participants
//     final List<dynamic> participants =
//         data['participants'] ?? [];
//
//     // Find other user
//     String otherUserId = '';
//
//     for (final participant
//     in participants) {
//       final String id =
//       participant.toString();
//
//       if (id != currentUserId) {
//         otherUserId = id;
//         break;
//       }
//     }
//
//     if (otherUserId.isEmpty) {
//       return const SizedBox.shrink();
//     }
//
//     // Chat data
//     final String lastMessage =
//         data['lastMessage'] ?? '';
//
//     final String lastMessageSenderId =
//         data['lastMessageSenderId'] ?? '';
//
//     final String lastMessageType =
//         data['lastMessageType'] ?? 'text';
//
//     final Timestamp? lastMessageTime =
//     data['lastMessageTime']
//     as Timestamp?;
//
//     final String chatRoomId =
//         chatDoc.id;
//
//     // Get other user
//     return FutureBuilder<UserModel?>(
//       future: getUser(
//         otherUserId,
//       ),
//       builder: (
//           context,
//           userSnapshot,
//           ) {
//         if (userSnapshot.connectionState ==
//             ConnectionState.waiting) {
//           return const SizedBox(
//             height: 76,
//             child: Center(
//               child:
//               LinearProgressIndicator(),
//             ),
//           );
//         }
//
//         if (userSnapshot.hasError) {
//           return const SizedBox.shrink();
//         }
//
//         final UserModel? user =
//             userSnapshot.data;
//
//         if (user == null) {
//           return const SizedBox.shrink();
//         }
//
//         // =================================================
//         // UNREAD MESSAGE STREAM
//         // =================================================
//
//         return StreamBuilder<QuerySnapshot>(
//           stream: firestore
//               .collection('chatRooms')
//               .doc(chatRoomId)
//               .collection('messages')
//               .where(
//             'receiverId',
//             isEqualTo: currentUserId,
//           )
//               .where(
//             'isRead',
//             isEqualTo: false,
//           )
//               .snapshots(),
//
//           builder: (
//               context,
//               unreadSnapshot,
//               ) {
//             int unreadCount = 0;
//
//             if (unreadSnapshot.hasData) {
//               unreadCount =
//                   unreadSnapshot
//                       .data!
//                       .docs
//                       .length;
//             }
//
//             // =================================================
//             // MATERIAL FOR INKWELL
//             // =================================================
//
//             return Material(
//               color: Colors.white,
//
//               child: InkWell(
//                 onTap: () {
//                   openChat(user);
//                 },
//
//                 child: Container(
//                   padding:
//                   const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 10,
//                   ),
//
//                   child: Row(
//                     children: [
//                       // =======================================
//                       // PROFILE
//                       // =======================================
//
//                       Stack(
//                         children: [
//                           CircleAvatar(
//                             radius: 30,
//
//                             backgroundColor:
//                             Colors.blue.shade100,
//
//                             child: Text(
//                               user.name.isNotEmpty
//                                   ? user.name[0]
//                                   .toUpperCase()
//                                   : '?',
//
//                               style:
//                               const TextStyle(
//                                 fontSize: 22,
//                                 fontWeight:
//                                 FontWeight.bold,
//                                 color: Colors.blue,
//                               ),
//                             ),
//                           ),
//
//                           // Online dot
//                           if (user.isOnline)
//                             Positioned(
//                               right: 0,
//                               bottom: 1,
//
//                               child: Container(
//                                 width: 16,
//                                 height: 16,
//
//                                 decoration:
//                                 BoxDecoration(
//                                   color:
//                                   Colors.green,
//                                   shape:
//                                   BoxShape.circle,
//                                   border:
//                                   Border.all(
//                                     color:
//                                     Colors.white,
//                                     width: 2,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//
//                       const SizedBox(
//                         width: 16,
//                       ),
//
//                       // =======================================
//                       // NAME + MESSAGE
//                       // =======================================
//
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment:
//                           CrossAxisAlignment
//                               .start,
//
//                           children: [
//                             // Name + Time
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: Text(
//                                     user.name,
//                                     maxLines: 1,
//                                     overflow:
//                                     TextOverflow
//                                         .ellipsis,
//
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight:
//                                       unreadCount >
//                                           0
//                                           ? FontWeight
//                                           .bold
//                                           : FontWeight
//                                           .w600,
//                                     ),
//                                   ),
//                                 ),
//
//                                 if (lastMessageTime !=
//                                     null)
//                                   Text(
//                                     formatChatTime(
//                                       lastMessageTime,
//                                     ),
//
//                                     style:
//                                     TextStyle(
//                                       fontSize: 12,
//                                       fontWeight:
//                                       unreadCount >
//                                           0
//                                           ? FontWeight
//                                           .bold
//                                           : FontWeight
//                                           .normal,
//                                       color:
//                                       unreadCount >
//                                           0
//                                           ? Colors
//                                           .green
//                                           : Colors
//                                           .grey,
//                                     ),
//                                   ),
//                               ],
//                             ),
//
//                             const SizedBox(
//                               height: 7,
//                             ),
//
//                             // Message + unread
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child:
//                                   buildLastMessage(
//                                     lastMessage:
//                                     lastMessage,
//                                     lastMessageType:
//                                     lastMessageType,
//                                     lastMessageSenderId:
//                                     lastMessageSenderId,
//                                     unreadCount:
//                                     unreadCount,
//                                   ),
//                                 ),
//
//                                 // Unread badge
//                                 if (unreadCount >
//                                     0)
//                                   Container(
//                                     margin:
//                                     const EdgeInsets
//                                         .only(
//                                       left: 8,
//                                     ),
//
//                                     constraints:
//                                     const BoxConstraints(
//                                       minWidth: 30,
//                                       minHeight: 30,
//                                     ),
//
//                                     padding:
//                                     const EdgeInsets
//                                         .symmetric(
//                                       horizontal: 7,
//                                     ),
//
//                                     decoration:
//                                     const BoxDecoration(
//                                       color:
//                                       Colors.green,
//                                       shape:
//                                       BoxShape.circle,
//                                     ),
//
//                                     alignment:
//                                     Alignment.center,
//
//                                     child: Text(
//                                       unreadCount >
//                                           99
//                                           ? '99+'
//                                           : unreadCount
//                                           .toString(),
//
//                                       style:
//                                       const TextStyle(
//                                         color:
//                                         Colors.white,
//                                         fontSize: 11,
//                                         fontWeight:
//                                         FontWeight
//                                             .bold,
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // =====================================================
//   // BUILD
//   // =====================================================
//
//   @override
//   Widget build(
//       BuildContext context,
//       ) {
//     if (currentUserId.isEmpty) {
//       return const Center(
//         child: Text(
//           'Please login first',
//         ),
//       );
//     }
//
//     // IMPORTANT:
//     // No Scaffold
//     // No AppBar
//     //
//     // HomeScreen already has them.
//
//     return StreamBuilder<QuerySnapshot>(
//       stream: firestore
//           .collection('chatRooms')
//           .where(
//         'participants',
//         arrayContains:
//         currentUserId,
//       )
//           .snapshots(),
//
//       builder: (
//           context,
//           snapshot,
//           ) {
//         // =================================================
//         // LOADING
//         // =================================================
//
//         if (snapshot.connectionState ==
//             ConnectionState.waiting) {
//           return const Center(
//             child:
//             CircularProgressIndicator(),
//           );
//         }
//
//         // =================================================
//         // ERROR
//         // =================================================
//
//         if (snapshot.hasError) {
//           return Center(
//             child: Padding(
//               padding:
//               const EdgeInsets.all(
//                 20,
//               ),
//               child: Text(
//                 'Something went wrong\n\n'
//                     '${snapshot.error}',
//                 textAlign:
//                 TextAlign.center,
//               ),
//             ),
//           );
//         }
//
//         // =================================================
//         // EMPTY
//         // =================================================
//
//         if (!snapshot.hasData ||
//             snapshot.data!.docs.isEmpty) {
//           return emptyChatList();
//         }
//
//         // =================================================
//         // CHAT DOCUMENTS
//         // =================================================
//
//         final List<QueryDocumentSnapshot>
//         chats =
//         List<QueryDocumentSnapshot>.from(
//           snapshot.data!.docs,
//         );
//
//         // =================================================
//         // SORT LATEST CHAT FIRST
//         // =================================================
//
//         chats.sort(
//               (a, b) {
//             final dataA =
//             a.data()
//             as Map<String, dynamic>;
//
//             final dataB =
//             b.data()
//             as Map<String, dynamic>;
//
//             final Timestamp? timeA =
//             dataA['lastMessageTime']
//             as Timestamp?;
//
//             final Timestamp? timeB =
//             dataB['lastMessageTime']
//             as Timestamp?;
//
//             if (timeA == null &&
//                 timeB == null) {
//               return 0;
//             }
//
//             if (timeA == null) {
//               return 1;
//             }
//
//             if (timeB == null) {
//               return -1;
//             }
//
//             return timeB.compareTo(
//               timeA,
//             );
//           },
//         );
//
//         // =================================================
//         // LIST
//         // =================================================
//
//         return Material(
//           color: Colors.white,
//
//           child: ListView.separated(
//             padding:
//             EdgeInsets.zero,
//
//             itemCount:
//             chats.length,
//
//             separatorBuilder:
//                 (context, index) {
//               return const Divider(
//                 height: 1,
//                 indent: 90,
//               );
//             },
//
//             itemBuilder:
//                 (context, index) {
//               return chatItem(
//                 chats[index],
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({
    super.key,
  });

  @override
  State<ChatListScreen> createState() =>
      _ChatListScreenState();
}

class _ChatListScreenState
    extends State<ChatListScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  // =====================================================
  // CURRENT USER ID
  // =====================================================

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // =====================================================
  // GET USER
  // =====================================================

  Future<UserModel?> getUser(
      String uid,
      ) async {
    try {
      final DocumentSnapshot doc =
      await firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final Object? rawData = doc.data();

      if (rawData is! Map) {
        return null;
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        rawData,
      );

      return UserModel.fromMap(
        data,
        doc.id,
      );
    } catch (e) {
      debugPrint(
        'Get user error: $e',
      );

      return null;
    }
  }

  // =====================================================
  // FORMAT TIME
  // =====================================================

  String formatChatTime(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return '';
    }

    final DateTime date =
    timestamp.toDate();

    final DateTime now =
    DateTime.now();

    final bool isToday =
        date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

    final int hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
        ? 12
        : date.hour;

    final String minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    final String period =
    date.hour >= 12
        ? 'PM'
        : 'AM';

    if (isToday) {
      return '$hour:$minute $period';
    }

    final DateTime yesterday =
    now.subtract(
      const Duration(days: 1),
    );

    final bool isYesterday =
        date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day;

    if (isYesterday) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  // =====================================================
  // OPEN CHAT
  // =====================================================

  Future<void> openChat(
      UserModel user,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiver: user,
        ),
      ),
    );

    // Chat se back aane ke baad
    // StreamBuilder automatically latest data
    // show karega.
    if (mounted) {
      setState(() {});
    }
  }

  // =====================================================
  // LAST MESSAGE
  // =====================================================

  Widget buildLastMessage({
    required String lastMessage,
    required String lastMessageType,
    required String lastMessageSenderId,
    required int unreadCount,
  }) {
    String displayMessage =
        lastMessage;

    if (lastMessage.isEmpty) {
      displayMessage =
      'No messages yet';
    }

    if (lastMessageType == 'image') {
      displayMessage =
      '📷 Image';
    }

    if (lastMessage ==
        'This message was deleted') {
      displayMessage =
      '🚫 This message was deleted';
    }

    final bool isMyMessage =
        lastMessageSenderId ==
            currentUserId;

    return Row(
      children: [
        // =================================================
        // MY MESSAGE TICK
        // =================================================

        if (isMyMessage &&
            lastMessage.isNotEmpty)
          Padding(
            padding:
            const EdgeInsets.only(
              right: 4,
            ),
            child: Icon(
              Icons.done_all,
              size: 15,

              // Agar unread message 0 hai
              // to blue tick
              color: unreadCount == 0
                  ? Colors.blue
                  : Colors.grey,
            ),
          ),

        // =================================================
        // LAST MESSAGE
        // =================================================

        Expanded(
          child: Text(
            displayMessage,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unreadCount > 0
                  ? Colors.black87
                  : Colors.grey.shade600,
              fontWeight:
              unreadCount > 0
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // EMPTY CHAT LIST
  // =====================================================

  Widget emptyChatList() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Start a conversation with someone',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CHAT ITEM
  // =====================================================

  Widget chatItem(
      QueryDocumentSnapshot chatDoc,
      ) {
    final Object? rawChatData =
    chatDoc.data();

    if (rawChatData is! Map) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      rawChatData,
    );

    // =====================================================
    // PARTICIPANTS
    // =====================================================

    final List<dynamic> participants =
    data['participants'] is List
        ? List<dynamic>.from(
      data['participants'],
    )
        : <dynamic>[];

    // =====================================================
    // FIND OTHER USER
    // =====================================================

    String otherUserId = '';

    for (final dynamic participant
    in participants) {
      final String id =
      participant.toString();

      if (id != currentUserId) {
        otherUserId = id;
        break;
      }
    }

    if (otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    // =====================================================
    // CHAT DATA
    // =====================================================

    final String lastMessage =
        data['lastMessage']
            ?.toString() ??
            '';

    final String lastMessageSenderId =
        data['lastMessageSenderId']
            ?.toString() ??
            '';

    final String lastMessageType =
        data['lastMessageType']
            ?.toString() ??
            'text';

    final Timestamp? lastMessageTime =
    data['lastMessageTime']
    is Timestamp
        ? data['lastMessageTime']
    as Timestamp
        : null;

    final String chatRoomId =
        chatDoc.id;

    // =====================================================
    // GET OTHER USER
    // =====================================================

    return FutureBuilder<UserModel?>(
      future: getUser(
        otherUserId,
      ),
      builder: (
          context,
          userSnapshot,
          ) {
        if (userSnapshot
            .connectionState ==
            ConnectionState.waiting) {
          return const SizedBox(
            height: 76,
            child: Center(
              child:
              LinearProgressIndicator(),
            ),
          );
        }

        if (userSnapshot.hasError) {
          return const SizedBox.shrink();
        }

        final UserModel? user =
            userSnapshot.data;

        if (user == null) {
          return const SizedBox.shrink();
        }

        // =================================================
        // REAL-TIME UNREAD MESSAGE STREAM
        // =================================================

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .collection('messages')
              .where(
            'receiverId',
            isEqualTo: currentUserId,
          )
              .where(
            'isRead',
            isEqualTo: false,
          )
              .snapshots(),

          builder: (
              context,
              unreadSnapshot,
              ) {
            int unreadCount = 0;

            if (unreadSnapshot.hasData) {
              unreadCount =
                  unreadSnapshot
                      .data!
                      .docs
                      .length;
            }

            // =================================================
            // CHAT ITEM
            // =================================================

            return Material(
              color: Colors.white,

              child: InkWell(
                onTap: () {
                  openChat(user);
                },

                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),

                  child: Row(
                    children: [
                      // =======================================
                      // PROFILE
                      // =======================================

                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,

                            backgroundColor:
                            Colors.blue.shade100,

                            child: Text(
                              user.name.isNotEmpty
                                  ? user.name[0]
                                  .toUpperCase()
                                  : '?',

                              style:
                              const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Colors.blue,
                              ),
                            ),
                          ),

                          // =================================
                          // ONLINE DOT
                          // =================================

                          if (user.isOnline)
                            Positioned(
                              right: 0,
                              bottom: 1,

                              child: Container(
                                width: 16,
                                height: 16,

                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors.green,
                                  shape:
                                  BoxShape.circle,
                                  border:
                                  Border.all(
                                    color:
                                    Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        width: 16,
                      ),

                      // =======================================
                      // NAME + MESSAGE
                      // =======================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                          children: [
                            // =================================
                            // NAME + TIME
                            // =================================

                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    user.name,
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow
                                        .ellipsis,

                                    style:
                                    TextStyle(
                                      fontSize: 18,
                                      fontWeight:
                                      unreadCount >
                                          0
                                          ? FontWeight
                                          .bold
                                          : FontWeight
                                          .w600,
                                    ),
                                  ),
                                ),

                                if (lastMessageTime !=
                                    null)
                                  Text(
                                    formatChatTime(
                                      lastMessageTime,
                                    ),

                                    style:
                                    TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                      unreadCount >
                                          0
                                          ? FontWeight
                                          .bold
                                          : FontWeight
                                          .normal,
                                      color:
                                      unreadCount >
                                          0
                                          ? Colors
                                          .green
                                          : Colors
                                          .grey,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            // =================================
                            // MESSAGE + BADGE
                            // =================================

                            Row(
                              children: [
                                Expanded(
                                  child:
                                  buildLastMessage(
                                    lastMessage:
                                    lastMessage,
                                    lastMessageType:
                                    lastMessageType,
                                    lastMessageSenderId:
                                    lastMessageSenderId,
                                    unreadCount:
                                    unreadCount,
                                  ),
                                ),

                                // =============================
                                // UNREAD BADGE
                                // =============================

                                if (unreadCount > 0)
                                  Container(
                                    margin:
                                    const EdgeInsets
                                        .only(
                                      left: 8,
                                    ),

                                    constraints:
                                    const BoxConstraints(
                                      minWidth: 30,
                                      minHeight: 30,
                                    ),

                                    padding:
                                    const EdgeInsets
                                        .symmetric(
                                      horizontal: 7,
                                    ),

                                    decoration:
                                    const BoxDecoration(
                                      color:
                                      Colors.green,
                                      shape:
                                      BoxShape.circle,
                                    ),

                                    alignment:
                                    Alignment.center,

                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount
                                          .toString(),

                                      style:
                                      const TextStyle(
                                        color:
                                        Colors.white,
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (currentUserId.isEmpty) {
      return const Center(
        child: Text(
          'Please login first',
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: firestore
          .collection('chatRooms')
          .where(
        'participants',
        arrayContains:
        currentUserId,
      )
          .snapshots(),

      builder: (
          context,
          snapshot,
          ) {
        // =================================================
        // LOADING
        // =================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        // =================================================
        // ERROR
        // =================================================

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Text(
                'Something went wrong\n\n'
                    '${snapshot.error}',
                textAlign:
                TextAlign.center,
              ),
            ),
          );
        }

        // =================================================
        // EMPTY
        // =================================================

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return emptyChatList();
        }

        // =================================================
        // CHAT DOCUMENTS
        // =================================================

        final List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>> chats =
        List<
            QueryDocumentSnapshot<
                Map<String, dynamic>>>.from(
          snapshot.data!.docs,
        );

        // =================================================
        // SORT LATEST CHAT FIRST
        // =================================================

        chats.sort(
              (a, b) {
            final Map<String, dynamic> dataA =
            a.data();

            final Map<String, dynamic> dataB =
            b.data();

            final Timestamp? timeA =
            dataA['lastMessageTime']
            is Timestamp
                ? dataA['lastMessageTime']
            as Timestamp
                : null;

            final Timestamp? timeB =
            dataB['lastMessageTime']
            is Timestamp
                ? dataB['lastMessageTime']
            as Timestamp
                : null;

            if (timeA == null &&
                timeB == null) {
              return 0;
            }

            if (timeA == null) {
              return 1;
            }

            if (timeB == null) {
              return -1;
            }

            return timeB.compareTo(
              timeA,
            );
          },
        );

        // =================================================
        // LIST
        // =================================================

        return Material(
          color: Colors.white,

          child: ListView.separated(
            padding: EdgeInsets.zero,

            itemCount:
            chats.length,

            separatorBuilder:
                (context, index) {
              return const Divider(
                height: 1,
                indent: 90,
              );
            },

            itemBuilder:
                (context, index) {
              return chatItem(
                chats[index],
              );
            },
          ),
        );
      },
    );
  }
}