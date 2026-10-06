import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/call_model.dart';
import '../../models/user_model.dart';
import 'call_screen.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({
    super.key,
  });

  @override
  State<CallHistoryScreen> createState() =>
      _CallHistoryScreenState();
}

class _CallHistoryScreenState
    extends State<CallHistoryScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // ============================================================
  // STREAM
  // ============================================================

  Stream<
      QuerySnapshot<
          Map<String, dynamic>>>
  get callHistoryStream {
    return firestore
        .collection('users')
        .doc(currentUserId)
        .collection('callHistory')
        .snapshots();
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Unknown time';
    }

    final int hour =
    date.hour > 12
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

    return '${date.day}/'
        '${date.month}/'
        '${date.year} '
        '$hour:$minute $period';
  }

  // ============================================================
  // FORMAT DURATION
  // ============================================================

  String formatDuration(
      int seconds,
      ) {
    final int minutes =
        seconds ~/ 60;

    final int remaining =
        seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // OUTGOING
  // ============================================================

  bool isOutgoing(
      CallModel call,
      ) {
    return call.callerId ==
        currentUserId;
  }

  // ============================================================
  // NAME
  // ============================================================

  String getCallName(
      CallModel call,
      ) {
    if (isOutgoing(call)) {
      return call.receiverName.isEmpty
          ? 'Unknown User'
          : call.receiverName;
    }

    return call.callerName.isEmpty
        ? 'Unknown User'
        : call.callerName;
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  String getCallSubtitle(
      CallModel call,
      ) {
    if (call.status == 'missed') {
      return 'Missed call';
    }

    if (call.status == 'rejected') {
      return 'Call rejected';
    }

    if (isOutgoing(call)) {
      return 'Outgoing call';
    }

    return 'Incoming call';
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData getCallIcon(
      CallModel call,
      ) {
    if (call.status == 'missed' ||
        call.status == 'rejected') {
      return Icons.call_missed;
    }

    if (isOutgoing(call)) {
      return Icons.call_made;
    }

    return Icons.call_received;
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color getCallColor(
      CallModel call,
      ) {
    if (call.status == 'missed' ||
        call.status == 'rejected') {
      return Colors.red;
    }

    if (isOutgoing(call)) {
      return Colors.green;
    }

    return Colors.blue;
  }

  // ============================================================
  // GET USER
  // ============================================================

  Future<UserModel?> getOtherUser(
      CallModel call,
      ) async {
    final String userId =
    isOutgoing(call)
        ? call.receiverId
        : call.callerId;

    if (userId.isEmpty) {
      return null;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>>
      doc =
      await firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final Map<String, dynamic>? data =
      doc.data();

      if (data == null) {
        return null;
      }

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

  // ============================================================
  // CALL AGAIN
  // ============================================================

  Future<void> callAgain(
      BuildContext context,
      CallModel call,
      ) async {
    final UserModel? receiver =
    await getOtherUser(call);

    if (receiver == null) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'User not found',
          ),
        ),
      );

      return;
    }

    try {
      final String callId =
          firestore
              .collection('calls')
              .doc()
              .id;

      final DocumentSnapshot<
          Map<String, dynamic>>
      currentUserDoc =
      await firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      String callerName = 'User';

      final Map<String, dynamic>? userData =
      currentUserDoc.data();

      if (userData != null) {
        final String name =
            userData['name']
                ?.toString()
                .trim() ??
                '';

        if (name.isNotEmpty) {
          callerName = name;
        }
      }

      await firestore
          .collection('calls')
          .doc(callId)
          .set({
        'callId': callId,
        'callerId': currentUserId,
        'receiverId': receiver.uid,
        'callerName': callerName,
        'receiverName': receiver.name,
        'status': 'calling',
        'type': 'voice',
        'duration': 0,
        'createdAt':
        FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'endedAt': null,
        'endedBy': null,
        'missedAt': null,
        'rejectedAt': null,
      });

      if (!context.mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callId: callId,
            receiver: receiver,
            isCaller: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Call again error: $e',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Call failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteCall(
      BuildContext context,
      String callId,
      ) async {
    try {
      await firestore
          .collection('users')
          .doc(currentUserId)
          .collection('callHistory')
          .doc(callId)
          .delete();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Call removed from history',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Delete history error: $e',
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<void> confirmDelete(
      BuildContext context,
      CallModel call,
      ) async {
    final bool? result =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext context,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete call?',
          ),
          content: const Text(
            'This call will be removed from your history only.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await deleteCall(
        context,
        call.callId,
      );
    }
  }

  // ============================================================
  // DETAILS
  // ============================================================

  Future<void> showCallDetails(
      BuildContext context,
      CallModel call,
      ) async {
    final String name =
    getCallName(call);

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (
          BuildContext context,
          ) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 35,
                  child: Text(
                    name.isEmpty
                        ? 'U'
                        : name[0]
                        .toUpperCase(),
                    style:
                    const TextStyle(
                      fontSize: 28,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  name,
                  style:
                  const TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                _detailRow(
                  Icons.call,
                  'Type',
                  getCallSubtitle(call),
                ),

                _detailRow(
                  Icons.access_time,
                  'Date',
                  formatDate(
                    call.createdAt,
                  ),
                ),

                _detailRow(
                  Icons.timer,
                  'Duration',
                  formatDuration(
                    call.duration,
                  ),
                ),

                _detailRow(
                  Icons.info_outline,
                  'Status',
                  call.status,
                ),

                const SizedBox(
                  height: 15,
                ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );

                          callAgain(
                            this.context,
                            call,
                          );
                        },
                        icon: const Icon(
                          Icons.call,
                        ),
                        label: const Text(
                          'Call Again',
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );

                          confirmDelete(
                            this.context,
                            call,
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: const Text(
                          'Delete',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 7,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            '$title:',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              value,
              textAlign:
              TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (currentUserId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Please login first',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Call History',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: callHistoryStream,
        builder: (
            BuildContext context,
            AsyncSnapshot<
                QuerySnapshot<
                    Map<String, dynamic>>>
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Text(
                  'Error:\n${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          final List<
              QueryDocumentSnapshot<
                  Map<String, dynamic>>>
          docs =
              snapshot.data?.docs ?? [];

          debugPrint(
            'CALL HISTORY COUNT: ${docs.length}',
          );

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.call,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Text(
                    'No call history',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final List<CallModel> calls =
          docs.map(
                (
                QueryDocumentSnapshot<
                    Map<String, dynamic>>
                doc,
                ) {
              return CallModel.fromMap(
                doc.data(),
                doc.id,
              );
            },
          ).toList();

          // ------------------------------------------------------
          // SORT
          // ------------------------------------------------------

          calls.sort(
                (
                CallModel a,
                CallModel b,
                ) {
              final DateTime dateA =
                  a.createdAt ??
                      DateTime
                          .fromMillisecondsSinceEpoch(
                        0,
                      );

              final DateTime dateB =
                  b.createdAt ??
                      DateTime
                          .fromMillisecondsSinceEpoch(
                        0,
                      );

              return dateB.compareTo(
                dateA,
              );
            },
          );

          // ------------------------------------------------------
          // LIST
          // ------------------------------------------------------

          return ListView.separated(
            itemCount: calls.length,
            separatorBuilder: (
                BuildContext context,
                int index,
                ) {
              return const Divider(
                height: 1,
              );
            },
            itemBuilder: (
                BuildContext context,
                int index,
                ) {
              final CallModel call =
              calls[index];

              final String name =
              getCallName(call);

              final Color color =
              getCallColor(call);

              return ListTile(
                onTap: () {
                  showCallDetails(
                    context,
                    call,
                  );
                },

                // ----------------------------------------------
                // AVATAR
                // ----------------------------------------------

                leading: CircleAvatar(
                  backgroundColor:
                  color.withOpacity(
                    0.12,
                  ),
                  child: Icon(
                    getCallIcon(call),
                    color: color,
                  ),
                ),

                // ----------------------------------------------
                // TITLE
                // ----------------------------------------------

                title: Text(
                  name,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                // ----------------------------------------------
                // SUBTITLE
                // ----------------------------------------------

                subtitle: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          getCallIcon(call),
                          size: 15,
                          color: color,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          getCallSubtitle(
                            call,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      formatDate(
                        call.createdAt,
                      ),
                      style:
                      const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                // ----------------------------------------------
                // TRAILING
                // ----------------------------------------------

                trailing: PopupMenuButton<
                    String>(
                  onSelected: (
                      String value,
                      ) {
                    if (value ==
                        'call') {
                      callAgain(
                        context,
                        call,
                      );
                    }

                    if (value ==
                        'details') {
                      showCallDetails(
                        context,
                        call,
                      );
                    }

                    if (value ==
                        'delete') {
                      confirmDelete(
                        context,
                        call,
                      );
                    }
                  },
                  itemBuilder: (
                      BuildContext context,
                      ) {
                    return const [
                      PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            Icon(
                              Icons.call,
                              color:
                              Colors.green,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Call Again',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Details',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color:
                              Colors.red,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Delete',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}