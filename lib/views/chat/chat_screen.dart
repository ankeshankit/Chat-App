
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_model.dart';
import '../call/call_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserModel receiver;

  const ChatScreen({
    super.key,
    required this.receiver,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final TextEditingController messageController =
  TextEditingController();

  final ScrollController scrollController =
  ScrollController();

  Timer? typingTimer;

  String? replyToMessageId;
  String? replyToSenderId;
  String? replyToText;

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  String get chatRoomId {
    final List<String> ids = [
      currentUserId,
      widget.receiver.uid,
    ];

    ids.sort();

    return '${ids[0]}_${ids[1]}';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    typingTimer?.cancel();

    // Stop typing when leaving chat
    setTyping(false);

    messageController.dispose();
    scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // TYPING
  // ============================================================

  Future<void> setTyping(bool value) async {
    if (currentUserId.isEmpty) return;

    try {
      await firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .set(
        {
          'typing_$currentUserId': value,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Typing error: $e');
    }
  }

  void onTypingChanged(String value) {
    if (value.trim().isEmpty) {
      typingTimer?.cancel();
      setTyping(false);
      return;
    }

    setTyping(true);

    typingTimer?.cancel();

    typingTimer = Timer(
      const Duration(seconds: 2),
          () {
        setTyping(false);
      },
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage() async {
    final String message =
    messageController.text.trim();

    if (message.isEmpty) return;

    if (currentUserId.isEmpty) return;

    try {
      final DocumentReference chatRoomReference =
      firestore
          .collection('chatRooms')
          .doc(chatRoomId);

      // Create/update chat room
      await chatRoomReference.set(
        {
          'participants': [
            currentUserId,
            widget.receiver.uid,
          ],
          'lastMessage': message,
          'lastMessageSenderId': currentUserId,
          'lastMessageType': 'text',
          'lastMessageTime':
          FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Add message
      await chatRoomReference
          .collection('messages')
          .add(
        {
          'senderId': currentUserId,
          'receiverId': widget.receiver.uid,
          'message': message,
          'type': 'text',

          'timestamp':
          FieldValue.serverTimestamp(),

          // Read
          'isRead': false,
          'readAt': null,

          // Delete
          'isDeleted': false,
          'deletedAt': null,
          'deletedBy': null,

          // Reply
          'replyToMessage': replyToMessageId,
          'replyToSenderId': replyToSenderId,
          'replyToText': replyToText,

          // Reaction
          'reactions': <String, String>{},
        },
      );

      messageController.clear();

      cancelReply();

      await setTyping(false);

      Future.delayed(
        const Duration(milliseconds: 200),
        scrollToBottom,
      );
    } catch (e) {
      debugPrint(
        'Send message error: $e',
      );
    }
  }

  // ============================================================
  // MARK MESSAGES AS READ
  // ============================================================

  Future<void> markMessagesAsRead(
      List<QueryDocumentSnapshot> messages,
      ) async {
    if (currentUserId.isEmpty) return;

    try {
      final WriteBatch batch =
      firestore.batch();

      int unreadCount = 0;

      for (
      final QueryDocumentSnapshot messageDoc
      in messages
      ) {
        final Object? rawData =
        messageDoc.data();

        if (rawData is! Map) {
          continue;
        }

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          rawData,
        );

        final String senderId =
            data['senderId']?.toString() ?? '';

        final String receiverId =
            data['receiverId']?.toString() ?? '';

        final bool isRead =
            data['isRead'] == true;

        final bool isDeleted =
            data['isDeleted'] == true;

        // IMPORTANT:
        // Sirf current user ko receive hue
        // unread messages ko read karo.
        if (receiverId == currentUserId &&
            senderId != currentUserId &&
            !isRead &&
            !isDeleted) {
          unreadCount++;

          batch.update(
            messageDoc.reference,
            {
              'isRead': true,
              'readAt':
              FieldValue.serverTimestamp(),
            },
          );
        }
      }

      if (unreadCount > 0) {
        await batch.commit();

        debugPrint(
          'Marked $unreadCount messages as read',
        );
      }
    } catch (e) {
      debugPrint(
        'Mark read error: $e',
      );
    }
  }

  // ============================================================
  // REPLY
  // ============================================================

  void startReply(
      QueryDocumentSnapshot messageDoc,
      ) {
    final Object? rawData =
    messageDoc.data();

    if (rawData is! Map) return;

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      rawData,
    );

    if (data['isDeleted'] == true) {
      return;
    }

    setState(() {
      replyToMessageId =
          messageDoc.id;

      replyToSenderId =
          data['senderId']?.toString();

      replyToText =
          data['message']?.toString();
    });
  }

  void cancelReply() {
    if (!mounted) return;

    setState(() {
      replyToMessageId = null;
      replyToSenderId = null;
      replyToText = null;
    });
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> copyMessage(
      String message,
      ) async {
    await Clipboard.setData(
      ClipboardData(
        text: message,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Message copied',
        ),
        duration:
        Duration(seconds: 1),
      ),
    );
  }

  // ============================================================
  // DELETE FOR ME
  // ============================================================

  Future<void> deleteForMe(
      QueryDocumentSnapshot messageDoc,
      ) async {
    if (currentUserId.isEmpty) return;

    try {
      await firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('deletedFor')
          .doc(currentUserId)
          .collection('messages')
          .doc(messageDoc.id)
          .set(
        {
          'messageId': messageDoc.id,
          'deletedAt':
          FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      debugPrint(
        'Delete for me error: $e',
      );
    }
  }

  // ============================================================
  // DELETE FOR EVERYONE
  // ============================================================

  Future<void> deleteForEveryone(
      QueryDocumentSnapshot messageDoc,
      ) async {
    try {
      final Object? rawData =
      messageDoc.data();

      if (rawData is! Map) return;

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        rawData,
      );

      final String senderId =
          data['senderId']?.toString() ?? '';

      if (senderId != currentUserId) {
        return;
      }

      await messageDoc.reference.update(
        {
          'isDeleted': true,
          'message': '',
          'deletedAt':
          FieldValue.serverTimestamp(),
          'deletedBy': currentUserId,

          'replyToMessage': null,
          'replyToSenderId': null,
          'replyToText': null,

          'reactions':
          <String, String>{},
        },
      );

      await updateLastMessageAfterDelete();
    } catch (e) {
      debugPrint(
        'Delete everyone error: $e',
      );
    }
  }

  // ============================================================
  // UPDATE LAST MESSAGE
  // ============================================================

  Future<void> updateLastMessageAfterDelete() async {
    try {
      final QuerySnapshot snapshot =
      await firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy(
        'timestamp',
        descending: true,
      )
          .limit(20)
          .get();

      QueryDocumentSnapshot? latestMessage;

      for (
      final QueryDocumentSnapshot doc
      in snapshot.docs
      ) {
        final Object? rawData =
        doc.data();

        if (rawData is! Map) {
          continue;
        }

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          rawData,
        );

        final bool isDeleted =
            data['isDeleted'] == true;

        if (!isDeleted) {
          latestMessage = doc;
          break;
        }
      }

      final DocumentReference
      chatRoomReference =
      firestore
          .collection('chatRooms')
          .doc(chatRoomId);

      if (latestMessage == null) {
        await chatRoomReference.update(
          {
            'lastMessage':
            'This message was deleted',
            'lastMessageType': 'deleted',
            'lastMessageSenderId':
            currentUserId,
            'lastMessageTime':
            FieldValue.serverTimestamp(),
          },
        );

        return;
      }

      final Object? rawData =
      latestMessage.data();

      if (rawData is! Map) return;

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        rawData,
      );

      await chatRoomReference.update(
        {
          'lastMessage':
          data['message']?.toString() ?? '',
          'lastMessageType':
          data['type']?.toString() ?? 'text',
          'lastMessageSenderId':
          data['senderId']?.toString() ?? '',
          'lastMessageTime':
          data['timestamp'],
        },
      );
    } catch (e) {
      debugPrint(
        'Update last message error: $e',
      );
    }
  }

  // ============================================================
  // REACTION
  // ============================================================

  Future<void> addReaction(
      QueryDocumentSnapshot messageDoc,
      String reaction,
      ) async {
    try {
      final Object? rawData =
      messageDoc.data();

      if (rawData is! Map) return;

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(
        rawData,
      );

      final bool isDeleted =
          data['isDeleted'] == true;

      if (isDeleted) return;

      final Object? rawReactions =
      data['reactions'];

      final Map<String, dynamic> reactions =
      rawReactions is Map
          ? Map<String, dynamic>.from(
        rawReactions,
      )
          : <String, dynamic>{};

      final String? oldReaction =
      reactions[currentUserId]?.toString();

      // Same reaction -> remove
      if (oldReaction == reaction) {
        await messageDoc.reference.update(
          {
            'reactions.$currentUserId':
            FieldValue.delete(),
          },
        );

        return;
      }

      // New/change reaction
      await messageDoc.reference.update(
        {
          'reactions.$currentUserId':
          reaction,
        },
      );
    } catch (e) {
      debugPrint(
        'Reaction error: $e',
      );
    }
  }

  // ============================================================
  // REACTION PICKER
  // ============================================================

  void showReactionPicker(
      QueryDocumentSnapshot messageDoc,
      ) {
    final Object? rawData =
    messageDoc.data();

    if (rawData is! Map) return;

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      rawData,
    );

    if (data['isDeleted'] == true) {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin:
          const EdgeInsets.all(16),
          padding:
          const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceEvenly,
            children: [
              reactionButton(
                messageDoc,
                '👍',
              ),
              reactionButton(
                messageDoc,
                '❤️',
              ),
              reactionButton(
                messageDoc,
                '😂',
              ),
              reactionButton(
                messageDoc,
                '😮',
              ),
              reactionButton(
                messageDoc,
                '😢',
              ),
              reactionButton(
                messageDoc,
                '🙏',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget reactionButton(
      QueryDocumentSnapshot messageDoc,
      String reaction,
      ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);

        await addReaction(
          messageDoc,
          reaction,
        );
      },
      child: Text(
        reaction,
        style: const TextStyle(
          fontSize: 30,
        ),
      ),
    );
  }

  // ============================================================
  // LONG PRESS MENU
  // ============================================================

  void showMessageMenu(
      QueryDocumentSnapshot messageDoc,
      ) {
    final Object? rawData =
    messageDoc.data();

    if (rawData is! Map) return;

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      rawData,
    );

    final String senderId =
        data['senderId']?.toString() ?? '';

    final bool isMe =
        senderId == currentUserId;

    final bool isDeleted =
        data['isDeleted'] == true;

    if (isDeleted) {
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.emoji_emotions_outlined,
                ),
                title: const Text(
                  'React to message',
                ),
                onTap: () {
                  Navigator.pop(context);

                  showReactionPicker(
                    messageDoc,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.reply,
                ),
                title: const Text(
                  'Reply',
                ),
                onTap: () {
                  Navigator.pop(context);

                  startReply(
                    messageDoc,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.copy,
                ),
                title: const Text(
                  'Copy',
                ),
                onTap: () {
                  Navigator.pop(context);

                  copyMessage(
                    data['message']
                        ?.toString() ??
                        '',
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                ),
                title: const Text(
                  'Delete for me',
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await deleteForMe(
                    messageDoc,
                  );
                },
              ),

              if (isMe)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete for everyone',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);

                    await deleteForEveryone(
                      messageDoc,
                    );
                  },
                ),

              ListTile(
                leading:
                const Icon(Icons.close),
                title:
                const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void scrollToBottom() {
    if (!scrollController.hasClients) {
      return;
    }

    scrollController.animateTo(
      scrollController
          .position
          .maxScrollExtent,
      duration:
      const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  String formatMessageTime(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return '';
    }

    final DateTime date =
    timestamp.toDate();

    int hour = date.hour;

    final String minute =
    date.minute
        .toString()
        .padLeft(2, '0');

    final String period =
    hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  String formatLastSeen(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return 'Last seen recently';
    }

    final DateTime date =
    timestamp.toDate();

    final DateTime now =
    DateTime.now();

    final DateTime today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime messageDate =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final int difference =
        today.difference(messageDate).inDays;

    final String time =
    formatMessageTime(timestamp);

    if (difference == 0) {
      return 'Last seen today at $time';
    }

    if (difference == 1) {
      return 'Last seen yesterday at $time';
    }

    return 'Last seen on '
        '${date.day}/${date.month}/${date.year} '
        'at $time';
  }

  // ============================================================
  // RECEIVER STATUS
  // ============================================================

  Widget receiverStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore
          .collection('users')
          .doc(widget.receiver.uid)
          .snapshots(),
      builder: (
          BuildContext context,
          AsyncSnapshot<DocumentSnapshot>
          snapshot,
          ) {
        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return const Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          );
        }

        final Object? rawData =
        snapshot.data?.data();

        if (rawData is! Map) {
          return const Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          );
        }

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          rawData,
        );

        final bool isOnline =
            data['isOnline'] == true;

        final Timestamp? lastSeen =
        data['lastSeen'] is Timestamp
            ? data['lastSeen'] as Timestamp
            : null;

        if (isOnline) {
          return const Text(
            'Online',
            style: TextStyle(
              fontSize: 12,
              color: Colors.greenAccent,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        return Text(
          formatLastSeen(lastSeen),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        );
      },
    );
  }

  // ============================================================
  // TYPING STATUS
  // ============================================================

  Widget receiverTypingStatus() {
    return StreamBuilder<DocumentSnapshot>(
      stream: firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .snapshots(),
      builder: (
          BuildContext context,
          AsyncSnapshot<DocumentSnapshot>
          snapshot,
          ) {
        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return receiverStatus();
        }

        final Object? rawData =
        snapshot.data?.data();

        if (rawData is! Map) {
          return receiverStatus();
        }

        final Map<String, dynamic> data =
        Map<String, dynamic>.from(
          rawData,
        );

        final bool isTyping =
            data[
            'typing_${widget.receiver.uid}'
            ] ==
                true;

        if (isTyping) {
          return const Text(
            'typing...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.greenAccent,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        return receiverStatus();
      },
    );
  }

  // ============================================================
  // REPLY PREVIEW
  // ============================================================

  Widget replyPreview() {
    if (replyToText == null ||
        replyToText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin:
      const EdgeInsets.only(bottom: 8),
      padding:
      const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(
            color: Colors.blue,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply,
            size: 20,
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyToText!,
              maxLines: 2,
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            onPressed: cancelReply,
            icon: const Icon(
              Icons.close,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REACTIONS UI
  // ============================================================

  Widget buildReactions(
      Map<String, dynamic> reactions,
      ) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, int> counts =
    <String, int>{};

    for (final dynamic value
    in reactions.values) {
      final String reaction =
      value.toString();

      counts[reaction] =
          (counts[reaction] ?? 0) + 1;
    }

    return Container(
      margin:
      const EdgeInsets.only(top: 4),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.08,
            ),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: counts.entries
            .map(
              (
              MapEntry<String, int> entry,
              ) {
            return Padding(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 2,
              ),
              child: Text(
                entry.value > 1
                    ? '${entry.key} ${entry.value}'
                    : entry.key,
                style:
                const TextStyle(
                  fontSize: 14,
                ),
              ),
            );
          },
        )
            .toList(),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget buildMessageBubble(
      QueryDocumentSnapshot messageDoc,
      ) {
    final Object? rawData =
    messageDoc.data();

    if (rawData is! Map) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> data =
    Map<String, dynamic>.from(
      rawData,
    );

    final String senderId =
        data['senderId']?.toString() ?? '';

    final bool isMe =
        senderId == currentUserId;

    final bool isDeleted =
        data['isDeleted'] == true;

    final bool isRead =
        data['isRead'] == true;

    final String message =
        data['message']?.toString() ?? '';

    final Timestamp? timestamp =
    data['timestamp'] is Timestamp
        ? data['timestamp'] as Timestamp
        : null;

    final Object? rawReactions =
    data['reactions'];

    final Map<String, dynamic> reactions =
    rawReactions is Map
        ? Map<String, dynamic>.from(
      rawReactions,
    )
        : <String, dynamic>{};

    final String? replyText =
    data['replyToText']?.toString();

    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          showMessageMenu(
            messageDoc,
          );
        },
        child: Container(
          margin:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          padding:
          const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          constraints:
          BoxConstraints(
            maxWidth:
            MediaQuery.of(context)
                .size
                .width *
                0.78,
          ),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.blue
                : Colors.grey.shade200,
            borderRadius:
            BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              if (replyText != null &&
                  replyText.isNotEmpty &&
                  !isDeleted)
                Container(
                  width: double.infinity,
                  margin:
                  const EdgeInsets.only(
                    bottom: 6,
                  ),
                  padding:
                  const EdgeInsets.all(7),
                  decoration:
                  BoxDecoration(
                    color: isMe
                        ? Colors.white
                        .withValues(
                      alpha: 0.15,
                    )
                        : Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    replyText,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe
                          ? Colors.white70
                          : Colors.black54,
                      fontStyle:
                      FontStyle.italic,
                    ),
                  ),
                ),

              // Message
              Text(
                isDeleted
                    ? 'This message was deleted'
                    : message,
                style: TextStyle(
                  fontSize: 15,
                  color: isDeleted
                      ? Colors.grey
                      : isMe
                      ? Colors.white
                      : Colors.black87,
                  fontStyle: isDeleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),

              const SizedBox(height: 4),

              // Time + Seen
              Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Text(
                    formatMessageTime(
                      timestamp,
                    ),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),

                  if (isMe &&
                      !isDeleted) ...[
                    const SizedBox(width: 5),

                    Icon(
                      isRead
                          ? Icons.done_all
                          : Icons.done,
                      size: 16,
                      color: isRead
                          ? Colors.lightBlueAccent
                          : Colors.white70,
                    ),
                  ],
                ],
              ),

              if (!isDeleted &&
                  reactions.isNotEmpty)
                buildReactions(
                  reactions,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST
  // ============================================================

  Widget messageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy(
        'timestamp',
        descending: false,
      )
          .snapshots(),
      builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot>
          snapshot,
          ) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'Start a conversation 👋',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          );
        }

        final List<QueryDocumentSnapshot>
        allMessages =
            snapshot.data!.docs;

        // IMPORTANT:
        // Chat open hote hi receiver ke
        // unread messages read honge.
        WidgetsBinding.instance
            .addPostFrameCallback(
              (_) {
            if (mounted) {
              markMessagesAsRead(
                allMessages,
              );
            }
          },
        );

        return StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('chatRooms')
              .doc(chatRoomId)
              .collection('deletedFor')
              .doc(currentUserId)
              .collection('messages')
              .snapshots(),
          builder: (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot>
              deletedSnapshot,
              ) {
            final Set<String>
            deletedForMeIds =
            <String>{};

            if (deletedSnapshot.hasData) {
              for (
              final QueryDocumentSnapshot doc
              in deletedSnapshot
                  .data!.docs
              ) {
                deletedForMeIds.add(
                  doc.id,
                );
              }
            }

            final List<QueryDocumentSnapshot>
            visibleMessages =
            allMessages.where(
                  (
                  QueryDocumentSnapshot doc,
                  ) {
                return !deletedForMeIds
                    .contains(doc.id);
              },
            ).toList();

            WidgetsBinding.instance
                .addPostFrameCallback(
                  (_) {
                scrollToBottom();
              },
            );

            return ListView.builder(
              controller:
              scrollController,
              padding:
              const EdgeInsets.symmetric(
                vertical: 12,
              ),
              itemCount:
              visibleMessages.length,
              itemBuilder:
                  (
                  BuildContext context,
                  int index,
                  ) {
                return buildMessageBubble(
                  visibleMessages[index],
                );
              },
            );
          },
        );
      },
    );
  }

  // ============================================================
  // INPUT
  // ============================================================

  Widget inputArea() {
    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.fromLTRB(
          8,
          6,
          8,
          8,
        ),
        child: Column(
          children: [
            replyPreview(),

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller:
                    messageController,
                    onChanged:
                    onTypingChanged,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction:
                    TextInputAction.newline,
                    decoration:
                    InputDecoration(
                      hintText:
                      'Type a message...',
                      filled: true,
                      fillColor:
                      Colors.grey.shade100,
                      contentPadding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          25,
                        ),
                        borderSide:
                        BorderSide.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                CircleAvatar(
                  radius: 25,
                  backgroundColor:
                  Colors.blue,
                  child: IconButton(
                    onPressed:
                    sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        Colors.blue,
        foregroundColor:
        Colors.white,

        actions: [
          IconButton(
            onPressed: () {
              startVoiceCall();
            },
            icon: const Icon(
              Icons.call,
            ),
          ),
        ],

        title:
        StreamBuilder<DocumentSnapshot>(
          stream: firestore
              .collection('users')
              .doc(widget.receiver.uid)
              .snapshots(),
          builder: (
              BuildContext context,
              AsyncSnapshot<DocumentSnapshot>
              snapshot,
              ) {
            String name =
                widget.receiver.name;

            String image =
                widget.receiver.profileImage;

            if (snapshot.hasData &&
                snapshot.data!.exists) {
              final Object? rawData =
              snapshot.data?.data();

              if (rawData is Map) {
                final Map<String, dynamic>
                data =
                Map<String, dynamic>.from(
                  rawData,
                );

                name =
                    data['name']?.toString() ??
                        name;

                image =
                    data['profileImage']
                        ?.toString() ??
                        image;
              }
            }

            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                  Colors.white,
                  backgroundImage:
                  image.isNotEmpty
                      ? NetworkImage(
                    image,
                  )
                      : null,
                  child: image.isEmpty
                      ? const Icon(
                    Icons.person,
                    color:
                    Colors.blue,
                  )
                      : null,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      receiverTypingStatus(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: messageList(),
          ),
          inputArea(),
        ],
      ),
    );
  }

  // ============================================================
  // START VOICE CALL
  // ============================================================

  Future<void> startVoiceCall() async {
    if (currentUserId.isEmpty) {
      return;
    }

    try {
      final DocumentReference callRef =
      firestore
          .collection('calls')
          .doc();

      await callRef.set({
        'callId': callRef.id,
        'callerId': currentUserId,
        'receiverId':
        widget.receiver.uid,
        'callerName': 'Caller',
        'receiverName':
        widget.receiver.name,
        'status': 'calling',
        'type': 'voice',
        'createdAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callId: callRef.id,
            receiver: widget.receiver,
            isCaller: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Start call error: $e',
      );
    }
  }
}


