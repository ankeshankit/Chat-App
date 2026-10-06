import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final UserModel caller;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.caller,
  });

  @override
  State<IncomingCallScreen> createState() =>
      _IncomingCallScreenState();
}

class _IncomingCallScreenState
    extends State<IncomingCallScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  bool isProcessing = false;

  // --------------------------------------------------
  // ACCEPT CALL
  // --------------------------------------------------

  Future<void> acceptCall() async {
    if (isProcessing) {
      return;
    }

    isProcessing = true;

    try {
      debugPrint(
        'Accepting call: ${widget.callId}',
      );

      await firestore
          .collection('calls')
          .doc(widget.callId)
          .update({
        'status': 'accepted',
        'acceptedAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      // ----------------------------------------------
      // OPEN CALL SCREEN AS RECEIVER
      // ----------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            callId: widget.callId,
            receiver: widget.caller,
            isCaller: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Accept call error: $e',
      );

      isProcessing = false;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to accept call: $e',
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // REJECT CALL
  // --------------------------------------------------

  Future<void> rejectCall() async {
    if (isProcessing) {
      return;
    }

    isProcessing = true;

    try {
      debugPrint(
        'Rejecting call: ${widget.callId}',
      );

      await firestore
          .collection('calls')
          .doc(widget.callId)
          .update({
        'status': 'rejected',
        'rejectedAt':
        FieldValue.serverTimestamp(),
        'rejectedBy':
        'receiver',
      });

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (e) {
      debugPrint(
        'Reject call error: $e',
      );

      isProcessing = false;

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to reject call: $e',
          ),
        ),
      );
    }
  }

  // --------------------------------------------------
  // BUILD
  // --------------------------------------------------

  @override
  Widget build(
      BuildContext context,
      ) {
    final String callerName =
    widget.caller.name.isEmpty
        ? 'Unknown User'
        : widget.caller.name;

    final String firstLetter =
    callerName.isNotEmpty
        ? callerName[0].toUpperCase()
        : 'U';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor:
        Colors.blue.shade700,
        body: SafeArea(
          child: Column(
            children: [
              // ----------------------------------------
              // TOP
              // ----------------------------------------

              const Padding(
                padding:
                EdgeInsets.only(
                  top: 50,
                ),
                child: Text(
                  'Incoming Voice Call',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              // ----------------------------------------
              // USER
              // ----------------------------------------

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 75,
                      backgroundColor:
                      Colors.white,
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          color:
                          Colors.blue.shade700,
                          fontSize: 58,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    Text(
                      callerName,
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    const Text(
                      'Incoming call...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),

              // ----------------------------------------
              // BUTTONS
              // ----------------------------------------

              Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 60,
                  left: 40,
                  right: 40,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceEvenly,
                  children: [
                    // REJECT
                    _callActionButton(
                      icon: Icons.call_end,
                      label: 'Reject',
                      color: Colors.red,
                      onPressed:
                      isProcessing
                          ? null
                          : rejectCall,
                    ),

                    // ACCEPT
                    _callActionButton(
                      icon: Icons.call,
                      label: 'Accept',
                      color: Colors.green,
                      onPressed:
                      isProcessing
                          ? null
                          : acceptCall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ACTION BUTTON
  // --------------------------------------------------

  Widget _callActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(
          height: 10,
        ),
        Text(
          label,
          style:
          const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}