import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/call_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final UserModel receiver;
  final bool isCaller;

  const CallScreen({
    super.key,
    required this.callId,
    required this.receiver,
    required this.isCaller,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final CallService callService =
  CallService();

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
  callSubscription;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
  offerSubscription;

  StreamSubscription<
      QuerySnapshot<Map<String, dynamic>>>?
  candidateSubscription;

  Timer? durationTimer;

  int callDuration = 0;

  String callStatus = 'calling';

  String webRTCConnectionState = 'new';

  String iceConnectionState = 'new';

  bool isMuted = false;

  bool isSpeakerOn = true;

  bool isEndingCall = false;

  bool callInitialized = false;

  bool durationTimerStarted = false;

  bool remoteDescriptionReady = false;

  final Set<String> processedCandidateIds =
  <String>{};

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();

    initializeCall();
  }

  // ============================================================
  // INITIALIZE CALL
  // ============================================================

  Future<void> initializeCall() async {
    if (callInitialized) {
      return;
    }

    callInitialized = true;

    try {
      debugPrint(
        '====================================',
      );

      debugPrint(
        'INITIALIZING CALL',
      );

      debugPrint(
        'Call ID: ${widget.callId}',
      );

      debugPrint(
        'Current User: $currentUserId',
      );

      debugPrint(
        'Is Caller: ${widget.isCaller}',
      );

      debugPrint(
        'Receiver: ${widget.receiver.name}',
      );

      debugPrint(
        '====================================',
      );

      // ----------------------------------------------------------
      // WEBRTC CONNECTION STATE
      // ----------------------------------------------------------

      callService.onConnectionStateChanged =
          (String state) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'WEBRTC CONNECTION STATE: $state',
        );

        setState(() {
          webRTCConnectionState = state;
        });

        final String lowerState =
        state.toLowerCase();

        if (lowerState.contains('connected')) {
          startDurationTimer();
        }
      };

      // ----------------------------------------------------------
      // ICE CONNECTION STATE
      // ----------------------------------------------------------

      callService.onIceConnectionStateChanged =
          (String state) {
        if (!mounted) {
          return;
        }

        debugPrint(
          'ICE CONNECTION STATE: $state',
        );

        setState(() {
          iceConnectionState = state;
        });
      };

      // ----------------------------------------------------------
      // CREATE PEER CONNECTION FIRST
      // ----------------------------------------------------------

      await callService.createCallPeerConnection(
        callId: widget.callId,
      );

      // ----------------------------------------------------------
      // FIRESTORE CALL LISTENER
      // ----------------------------------------------------------

      listenToCall();

      // ----------------------------------------------------------
      // ICE LISTENER
      // ----------------------------------------------------------

      listenToIceCandidates();

      // ----------------------------------------------------------
      // LOCAL AUDIO
      // ----------------------------------------------------------

      await callService.getLocalAudioStream();

      // ----------------------------------------------------------
      // DEFAULT SPEAKER ON
      // ----------------------------------------------------------

      callService.setSpeaker(true);

      if (mounted) {
        setState(() {
          isSpeakerOn = true;
        });
      }

      // ----------------------------------------------------------
      // CALLER -> CREATE OFFER
      // ----------------------------------------------------------

      if (widget.isCaller) {
        await callService.createOffer(
          widget.callId,
        );
      }

      // ----------------------------------------------------------
      // RECEIVER -> WAIT FOR OFFER
      // ----------------------------------------------------------

      else {
        listenForOffer();
      }
    } catch (e) {
      debugPrint(
        'INITIALIZE CALL ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        webRTCConnectionState = 'failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Call initialization failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CALL FIRESTORE LISTENER
  // ============================================================

  void listenToCall() {
    callSubscription = firestore
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen(
          (
          DocumentSnapshot<Map<String, dynamic>>
          snapshot,
          ) async {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
        snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']?.toString() ??
                'calling';

        debugPrint(
          'CALL STATUS: $status',
        );

        if (mounted) {
          setState(() {
            callStatus = status;
          });
        }

        // --------------------------------------------------------
        // CALLER GETS ANSWER
        // --------------------------------------------------------

        if (widget.isCaller) {
          final dynamic rawAnswer =
          data['answer'];

          if (rawAnswer is Map &&
              !remoteDescriptionReady) {
            final String? sdp =
            rawAnswer['sdp']?.toString();

            final String? type =
            rawAnswer['type']?.toString();

            if (sdp != null &&
                type != null) {
              try {
                await callService.setRemoteDescription(
                  sdp,
                  type,
                );

                remoteDescriptionReady = true;

                debugPrint(
                  'CALLER: ANSWER RECEIVED',
                );
              } catch (e) {
                debugPrint(
                  'ANSWER ERROR: $e',
                );
              }
            }
          }
        }

        // --------------------------------------------------------
        // ACCEPTED
        // --------------------------------------------------------

        if (status == 'accepted') {
          debugPrint(
            'CALL ACCEPTED',
          );
        }

        // --------------------------------------------------------
        // ENDED
        // --------------------------------------------------------

        if (status == 'ended') {
          final int duration =
          _getDuration(data);

          await saveHistory(
            data: data,
            status: 'ended',
            duration: duration,
          );

          if (!isEndingCall) {
            await closeAndPop();
          }
        }

        // --------------------------------------------------------
        // MISSED
        // --------------------------------------------------------

        if (status == 'missed') {
          await saveHistory(
            data: data,
            status: 'missed',
            duration: 0,
          );

          if (!isEndingCall) {
            await closeAndPop();
          }
        }

        // --------------------------------------------------------
        // REJECTED
        // --------------------------------------------------------

        if (status == 'rejected') {
          await saveHistory(
            data: data,
            status: 'rejected',
            duration: 0,
          );

          if (!isEndingCall) {
            await closeAndPop();
          }
        }
      },
      onError: (Object error) {
        debugPrint(
          'CALL LISTENER ERROR: $error',
        );
      },
    );
  }

  // ============================================================
  // RECEIVER LISTENS FOR OFFER
  // ============================================================

  void listenForOffer() {
    offerSubscription = firestore
        .collection('calls')
        .doc(widget.callId)
        .snapshots()
        .listen(
          (
          DocumentSnapshot<Map<String, dynamic>>
          snapshot,
          ) async {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
        snapshot.data();

        if (data == null) {
          return;
        }

        final dynamic rawOffer =
        data['offer'];

        if (rawOffer is! Map) {
          return;
        }

        if (remoteDescriptionReady) {
          return;
        }

        final String? sdp =
        rawOffer['sdp']?.toString();

        final String? type =
        rawOffer['type']?.toString();

        if (sdp == null ||
            type == null) {
          return;
        }

        try {
          debugPrint(
            'RECEIVER: OFFER RECEIVED',
          );

          await callService.setRemoteDescription(
            sdp,
            type,
          );

          remoteDescriptionReady = true;

          await callService.createAnswer(
            widget.callId,
          );

          debugPrint(
            'RECEIVER: ANSWER SENT',
          );
        } catch (e) {
          debugPrint(
            'OFFER ERROR: $e',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'OFFER LISTENER ERROR: $error',
        );
      },
    );
  }

  // ============================================================
  // ICE CANDIDATES
  // ============================================================

  void listenToIceCandidates() {
    final String collectionName =
    widget.isCaller
        ? 'receiverCandidates'
        : 'callerCandidates';

    debugPrint(
      'Listening ICE collection: $collectionName',
    );

    candidateSubscription = firestore
        .collection('calls')
        .doc(widget.callId)
        .collection(collectionName)
        .snapshots()
        .listen(
          (
          QuerySnapshot<Map<String, dynamic>>
          snapshot,
          ) async {
        for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in snapshot.docs) {
          if (processedCandidateIds
              .contains(document.id)) {
            continue;
          }

          processedCandidateIds.add(
            document.id,
          );

          final Map<String, dynamic> data =
          document.data();

          final String? candidate =
          data['candidate']?.toString();

          final String? sdpMid =
          data['sdpMid']?.toString();

          int? sdpMLineIndex;

          final dynamic rawIndex =
          data['sdpMLineIndex'];

          if (rawIndex is int) {
            sdpMLineIndex = rawIndex;
          } else if (rawIndex != null) {
            sdpMLineIndex =
                int.tryParse(
                  rawIndex.toString(),
                );
          }

          if (candidate == null ||
              candidate.isEmpty) {
            continue;
          }

          try {
            await callService.addIceCandidate(
              candidate,
              sdpMid,
              sdpMLineIndex,
            );

            debugPrint(
              'ICE CANDIDATE ADDED',
            );
          } catch (e) {
            debugPrint(
              'ICE ADD ERROR: $e',
            );
          }
        }
      },
      onError: (Object error) {
        debugPrint(
          'ICE LISTENER ERROR: $error',
        );
      },
    );
  }

  // ============================================================
  // GET CALL DURATION
  // ============================================================

  int _getDuration(
      Map<String, dynamic> data,
      ) {
    final dynamic value =
    data['duration'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '0',
    ) ??
        0;
  }

  // ============================================================
  // SAVE CALL HISTORY
  // ============================================================

  Future<void> saveHistory({
    required Map<String, dynamic> data,
    required String status,
    required int duration,
  }) async {
    try {
      final Map<String, dynamic> historyData =
      Map<String, dynamic>.from(data);

      historyData['callId'] =
          widget.callId;

      historyData['status'] =
          status;

      historyData['duration'] =
          duration;

      if (historyData['createdAt']
      is! Timestamp) {
        historyData['createdAt'] =
            Timestamp.now();
      }

      historyData['endedAt'] =
          Timestamp.now();

      await callService
          .saveCallHistoryForBothUsers(
        callData: historyData,
      );

      debugPrint(
        'CALL HISTORY SAVED',
      );
    } catch (e) {
      debugPrint(
        'SAVE HISTORY ERROR: $e',
      );
    }
  }

  // ============================================================
  // START TIMER
  // ============================================================

  void startDurationTimer() {
    if (durationTimerStarted) {
      return;
    }

    durationTimerStarted = true;

    durationTimer = Timer.periodic(
      const Duration(seconds: 1),
          (Timer timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          callDuration++;
        });
      },
    );
  }

  // ============================================================
  // STOP TIMER
  // ============================================================

  void stopDurationTimer() {
    durationTimer?.cancel();

    durationTimer = null;

    durationTimerStarted = false;
  }

  // ============================================================
  // MUTE
  // ============================================================

  void toggleMute() {
    final bool value = !isMuted;

    callService.setMute(value);

    if (!mounted) {
      return;
    }

    setState(() {
      isMuted = value;
    });
  }

  // ============================================================
  // SPEAKER
  // ============================================================

  void toggleSpeaker() {
    final bool value = !isSpeakerOn;

    callService.setSpeaker(value);

    if (!mounted) {
      return;
    }

    setState(() {
      isSpeakerOn = value;
    });
  }

  // ============================================================
  // END CALL
  // ============================================================

  Future<void> endCall() async {
    if (isEndingCall) {
      return;
    }

    isEndingCall = true;

    try {
      final DocumentSnapshot<
          Map<String, dynamic>>
      snapshot =
      await firestore
          .collection('calls')
          .doc(widget.callId)
          .get();

      if (snapshot.exists) {
        final Map<String, dynamic>? data =
        snapshot.data();

        if (data != null) {
          final Map<String, dynamic>
          historyData =
          Map<String, dynamic>.from(data);

          historyData['callId'] =
              widget.callId;

          historyData['status'] =
          'ended';

          historyData['endedBy'] =
              currentUserId;

          historyData['duration'] =
              callDuration;

          if (historyData['createdAt']
          is! Timestamp) {
            historyData['createdAt'] =
                Timestamp.now();
          }

          historyData['endedAt'] =
              Timestamp.now();

          // ------------------------------------------------------
          // UPDATE MAIN CALL
          // ------------------------------------------------------

          await firestore
              .collection('calls')
              .doc(widget.callId)
              .update({
            'status': 'ended',
            'endedAt':
            FieldValue.serverTimestamp(),
            'endedBy':
            currentUserId,
            'duration':
            callDuration,
          });

          // ------------------------------------------------------
          // SAVE HISTORY FOR BOTH USERS
          // ------------------------------------------------------

          await callService
              .saveCallHistoryForBothUsers(
            callData: historyData,
          );
        }
      }
    } catch (e) {
      debugPrint(
        'END CALL ERROR: $e',
      );
    }

    stopDurationTimer();

    await callService.closeConnection();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  // ============================================================
  // CLOSE AND POP
  // ============================================================

  Future<void> closeAndPop() async {
    if (isEndingCall) {
      return;
    }

    isEndingCall = true;

    stopDurationTimer();

    await callService.closeConnection();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
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
  // USER FRIENDLY CONNECTION STATUS
  // ============================================================

  String get connectionStatusText {
    final String state =
    webRTCConnectionState.toLowerCase();

    if (state.contains('connected')) {
      return 'Connected';
    }

    if (state.contains('connecting')) {
      return 'Connecting...';
    }

    if (state.contains('checking')) {
      return 'Checking connection...';
    }

    if (state.contains('failed')) {
      return 'Connection failed';
    }

    if (state.contains('disconnected')) {
      return 'Reconnecting...';
    }

    if (state.contains('closed')) {
      return 'Call ended';
    }

    return 'Calling...';
  }

  // ============================================================
  // CONNECTION ICON
  // ============================================================

  IconData get connectionIcon {
    final String state =
    webRTCConnectionState.toLowerCase();

    if (state.contains('connected')) {
      return Icons.check_circle;
    }

    if (state.contains('failed')) {
      return Icons.error;
    }

    if (state.contains('disconnected')) {
      return Icons.sync;
    }

    return Icons.wifi_calling_3;
  }

  // ============================================================
  // ICE STATUS
  // ============================================================

  String get iceStatusText {
    final String state =
    iceConnectionState.toLowerCase();

    if (state.contains('connected') ||
        state.contains('completed')) {
      return 'Connected';
    }

    if (state.contains('checking')) {
      return 'Checking...';
    }

    if (state.contains('failed')) {
      return 'Failed';
    }

    if (state.contains('disconnected')) {
      return 'Disconnected';
    }

    if (state.contains('closed')) {
      return 'Closed';
    }

    return 'Connecting...';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final String displayName =
    widget.receiver.name.isEmpty
        ? 'User'
        : widget.receiver.name;

    final String firstLetter =
    displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (
          bool didPop,
          Object? result,
          ) {
        if (didPop) {
          return;
        }

        endCall();
      },
      child: Scaffold(
        backgroundColor:
        Colors.blue.shade700,
        body: SafeArea(
          child: Column(
            children: [

              // ==================================================
              // TOP BAR
              // ==================================================

              Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [

                    IconButton(
                      onPressed:
                      isEndingCall
                          ? null
                          : endCall,
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          'Voice Call',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 48,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CALL INFORMATION
              // ==================================================

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [

                    // PROFILE
                    CircleAvatar(
                      radius: 65,
                      backgroundColor:
                      Colors.white,
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          fontSize: 50,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.blue.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // NAME
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // CONNECTION STATUS
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [

                        Icon(
                          connectionIcon,
                          size: 17,
                          color:
                          webRTCConnectionState
                              .toLowerCase()
                              .contains(
                            'connected',
                          )
                              ? Colors
                              .greenAccent
                              : Colors.white70,
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          connectionStatusText,
                          style: const TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // TIMER
                    if (callDuration > 0)
                      Text(
                        formatDuration(
                          callDuration,
                        ),
                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ------------------------------------------------
                    // ICE STATUS
                    //
                    // Raw:
                    // RTCIceConnectionState...
                    //
                    // Ab:
                    // ICE: Connected
                    // ------------------------------------------------

                    Text(
                      'ICE: $iceStatusText',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CALL BUTTONS
              // ==================================================

              Padding(
                padding:
                const EdgeInsets.only(
                  left: 30,
                  right: 30,
                  bottom: 35,
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [

                    // MUTE
                    _callButton(
                      icon: isMuted
                          ? Icons.mic_off
                          : Icons.mic,
                      label: isMuted
                          ? 'Unmute'
                          : 'Mute',
                      backgroundColor:
                      isMuted
                          ? Colors.white
                          : Colors.white24,
                      iconColor:
                      isMuted
                          ? Colors.blue
                          : Colors.white,
                      onPressed:
                      toggleMute,
                    ),

                    // SPEAKER
                    _callButton(
                      icon: isSpeakerOn
                          ? Icons.volume_up
                          : Icons.volume_off,
                      label: isSpeakerOn
                          ? 'Speaker'
                          : 'Earpiece',
                      backgroundColor:
                      isSpeakerOn
                          ? Colors.white
                          : Colors.white24,
                      iconColor:
                      isSpeakerOn
                          ? Colors.blue
                          : Colors.white,
                      onPressed:
                      toggleSpeaker,
                    ),

                    // END CALL
                    _callButton(
                      icon: Icons.call_end,
                      label: 'End',
                      backgroundColor:
                      Colors.red,
                      iconColor:
                      Colors.white,
                      onPressed:
                      isEndingCall
                          ? null
                          : endCall,
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

  // ============================================================
  // CALL BUTTON WIDGET
  // ============================================================

  Widget _callButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback? onPressed,
  }) {
    return Column(
      children: [

        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    callSubscription?.cancel();

    offerSubscription?.cancel();

    candidateSubscription?.cancel();

    durationTimer?.cancel();

    callService.closeConnection();

    super.dispose();
  }
}