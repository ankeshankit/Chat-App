import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../views/call/incoming_call_screen.dart';

class IncomingCallService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  StreamSubscription<
      QuerySnapshot<Map<String, dynamic>>>?
  callSubscription;

  bool isListening = false;

  String? currentIncomingCallId;

  // --------------------------------------------------
  // CURRENT USER ID
  // --------------------------------------------------

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // --------------------------------------------------
  // START LISTENER
  // --------------------------------------------------

  void startListening(
      BuildContext context,
      ) {
    if (isListening) {
      return;
    }

    if (currentUserId.isEmpty) {
      debugPrint(
        'Incoming call listener: user not logged in',
      );

      return;
    }

    isListening = true;

    debugPrint(
      'Incoming call listener started',
    );

    callSubscription = firestore
        .collection('calls')
        .where(
      'receiverId',
      isEqualTo: currentUserId,
    )
        .where(
      'status',
      isEqualTo: 'calling',
    )
        .snapshots()
        .listen(
          (
          QuerySnapshot<Map<String, dynamic>>
          snapshot,
          ) async {
        if (snapshot.docs.isEmpty) {
          return;
        }

        // Take the latest incoming call.
        final QueryDocumentSnapshot<
            Map<String, dynamic>>
        callDoc = snapshot.docs.last;

        final String callId =
            callDoc.id;

        // Prevent opening same screen multiple times.
        if (currentIncomingCallId == callId) {
          return;
        }

        currentIncomingCallId = callId;

        debugPrint(
          'Incoming call received: $callId',
        );

        await showIncomingCall(
          context,
          callDoc,
        );
      },
      onError: (Object error) {
        debugPrint(
          'Incoming call listener error: $error',
        );
      },
    );
  }

  // --------------------------------------------------
  // SHOW INCOMING CALL
  // --------------------------------------------------

  Future<void> showIncomingCall(
      BuildContext context,
      QueryDocumentSnapshot<
          Map<String, dynamic>>
      callDoc,
      ) async {
    try {
      final Map<String, dynamic> data =
      callDoc.data();

      final String callerId =
          data['callerId']?.toString() ?? '';

      if (callerId.isEmpty) {
        currentIncomingCallId = null;
        return;
      }

      // ----------------------------------------------
      // GET CALLER USER DATA
      // ----------------------------------------------

      final DocumentSnapshot<
          Map<String, dynamic>>
      userDoc =
      await firestore
          .collection('users')
          .doc(callerId)
          .get();

      if (!userDoc.exists) {
        debugPrint(
          'Caller user document not found',
        );

        currentIncomingCallId = null;

        return;
      }

      final Map<String, dynamic>? userData =
      userDoc.data();

      if (userData == null) {
        currentIncomingCallId = null;
        return;
      }

      final UserModel caller =
      UserModel.fromMap(
        userData,
        userDoc.id,
      );

      if (!context.mounted) {
        return;
      }

      // ----------------------------------------------
      // OPEN INCOMING CALL SCREEN
      // ----------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              IncomingCallScreen(
                callId: callDoc.id,
                caller: caller,
              ),
        ),
      );

      // Allow future calls.
      currentIncomingCallId = null;
    } catch (e) {
      debugPrint(
        'Show incoming call error: $e',
      );

      currentIncomingCallId = null;
    }
  }

  // --------------------------------------------------
  // STOP LISTENER
  // --------------------------------------------------

  Future<void> stopListening() async {
    await callSubscription?.cancel();

    callSubscription = null;

    isListening = false;

    currentIncomingCallId = null;

    debugPrint(
      'Incoming call listener stopped',
    );
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  Future<void> dispose() async {
    await stopListening();
  }
}