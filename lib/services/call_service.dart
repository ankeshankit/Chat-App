import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

class CallService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  webrtc.RTCPeerConnection? peerConnection;

  webrtc.MediaStream? localStream;

  final List<webrtc.RTCIceCandidate> pendingCandidates = [];

  bool remoteDescriptionSet = false;

  Function(String state)? onConnectionStateChanged;

  Function(String state)? onIceConnectionStateChanged;

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // ============================================================
  // CREATE PEER CONNECTION
  // ============================================================

  Future<webrtc.RTCPeerConnection> createCallPeerConnection({
    required String callId,
  }) async {
    debugPrint('================================');
    debugPrint('CREATING PEER CONNECTION');
    debugPrint('CALL ID: $callId');
    debugPrint('CURRENT USER: $currentUserId');
    debugPrint('================================');

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {
          'urls': [
            'stun:stun.l.google.com:19302',
          ],
        },
      ],

      // Important for real devices
      'sdpSemantics': 'unified-plan',

      // Try all available ICE candidates
      'iceTransportPolicy': 'all',
    };

    final webrtc.RTCPeerConnection connection =
    await webrtc.createPeerConnection(
      configuration,
    );

    peerConnection = connection;

    debugPrint('PEER CONNECTION CREATED');

    // ============================================================
    // ICE CANDIDATE
    // ============================================================

    connection.onIceCandidate =
        (webrtc.RTCIceCandidate candidate) async {
      try {
        if (candidate.candidate == null ||
            candidate.candidate!.isEmpty) {
          debugPrint('Empty ICE candidate');
          return;
        }

        final String callerId =
        await _getCallerId(callId);

        if (callerId.isEmpty) {
          debugPrint('CALLER ID NOT FOUND');
          return;
        }

        final String collectionName =
        currentUserId == callerId
            ? 'callerCandidates'
            : 'receiverCandidates';

        await firestore
            .collection('calls')
            .doc(callId)
            .collection(collectionName)
            .add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint(
          'ICE CANDIDATE SAVED: $collectionName',
        );
      } catch (e) {
        debugPrint(
          'ICE CANDIDATE ERROR: $e',
        );
      }
    };

    // ============================================================
    // REMOTE TRACK
    // ============================================================

    connection.onTrack =
        (webrtc.RTCTrackEvent event) {
      debugPrint(
        'REMOTE TRACK: ${event.track.kind}',
      );

      if (event.track.kind == 'audio') {
        event.track.enabled = true;

        debugPrint(
          'REMOTE AUDIO TRACK ENABLED',
        );
      }

      if (event.streams.isNotEmpty) {
        debugPrint(
          'REMOTE STREAM RECEIVED',
        );
      }
    };

    // ============================================================
    // CONNECTION STATE
    // ============================================================

    connection.onConnectionState =
        (
        webrtc.RTCPeerConnectionState state,
        ) {
      final String stateText =
      state.toString();

      debugPrint(
        '================================',
      );
      debugPrint(
        'WEBRTC CONNECTION STATE: $stateText',
      );
      debugPrint(
        '================================',
      );

      onConnectionStateChanged
          ?.call(stateText);
    };

    // ============================================================
    // ICE CONNECTION STATE
    // ============================================================

    connection.onIceConnectionState =
        (
        webrtc.RTCIceConnectionState state,
        ) {
      final String stateText =
      state.toString();

      debugPrint(
        '================================',
      );
      debugPrint(
        'ICE CONNECTION STATE: $stateText',
      );
      debugPrint(
        '================================',
      );

      onIceConnectionStateChanged
          ?.call(stateText);
    };

    return connection;
  }

  // ============================================================
  // GET CALLER ID
  // ============================================================

  Future<String> _getCallerId(
      String callId,
      ) async {
    try {
      final DocumentSnapshot<
          Map<String, dynamic>> doc =
      await firestore
          .collection('calls')
          .doc(callId)
          .get();

      if (!doc.exists) {
        debugPrint(
          'CALL DOCUMENT NOT FOUND',
        );

        return '';
      }

      final Map<String, dynamic>? data =
      doc.data();

      if (data == null) {
        return '';
      }

      return data['callerId']
          ?.toString() ??
          '';
    } catch (e) {
      debugPrint(
        'GET CALLER ID ERROR: $e',
      );

      return '';
    }
  }

  // ============================================================
  // LOCAL AUDIO
  // ============================================================

  Future<webrtc.MediaStream>
  getLocalAudioStream() async {
    try {
      final Map<String, dynamic>
      constraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      };

      debugPrint(
        'REQUESTING MICROPHONE',
      );

      final webrtc.MediaStream stream =
      await webrtc
          .navigator
          .mediaDevices
          .getUserMedia(
        constraints,
      );

      localStream = stream;

      debugPrint(
        'MICROPHONE ACCESS GRANTED',
      );

      final List<webrtc.MediaStreamTrack>
      tracks =
      stream.getAudioTracks();

      debugPrint(
        'AUDIO TRACK COUNT: ${tracks.length}',
      );

      if (peerConnection != null) {
        for (final webrtc.MediaStreamTrack
        track in tracks) {
          await peerConnection!.addTrack(
            track,
            stream,
          );

          debugPrint(
            'AUDIO TRACK ADDED TO PEER',
          );
        }
      }

      return stream;
    } catch (e) {
      debugPrint(
        'LOCAL AUDIO ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // CREATE OFFER
  // ============================================================

  Future<void> createOffer(
      String callId,
      ) async {
    if (peerConnection == null) {
      throw Exception(
        'Peer connection is not created',
      );
    }

    try {
      final Map<String, dynamic>
      constraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      };

      debugPrint(
        'CREATING OFFER...',
      );

      final webrtc.RTCSessionDescription
      offer =
      await peerConnection!.createOffer(
        constraints,
      );

      await peerConnection!
          .setLocalDescription(
        offer,
      );

      debugPrint(
        'LOCAL OFFER DESCRIPTION SET',
      );

      await firestore
          .collection('calls')
          .doc(callId)
          .update({
        'offer': {
          'sdp': offer.sdp,
          'type': offer.type,
        },
      });

      debugPrint(
        'OFFER SAVED TO FIRESTORE',
      );
    } catch (e) {
      debugPrint(
        'CREATE OFFER ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // CREATE ANSWER
  // ============================================================

  Future<void> createAnswer(
      String callId,
      ) async {
    if (peerConnection == null) {
      throw Exception(
        'Peer connection is not created',
      );
    }

    try {
      final Map<String, dynamic>
      constraints = {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': false,
      };

      debugPrint(
        'CREATING ANSWER...',
      );

      final webrtc.RTCSessionDescription
      answer =
      await peerConnection!.createAnswer(
        constraints,
      );

      await peerConnection!
          .setLocalDescription(
        answer,
      );

      debugPrint(
        'LOCAL ANSWER DESCRIPTION SET',
      );

      await firestore
          .collection('calls')
          .doc(callId)
          .update({
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      });

      debugPrint(
        'ANSWER SAVED TO FIRESTORE',
      );
    } catch (e) {
      debugPrint(
        'CREATE ANSWER ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // SET REMOTE DESCRIPTION
  // ============================================================

  Future<void> setRemoteDescription(
      String? sdp,
      String? type,
      ) async {
    if (peerConnection == null) {
      debugPrint(
        'PEER CONNECTION IS NULL',
      );

      return;
    }

    if (sdp == null || type == null) {
      debugPrint(
        'REMOTE SDP OR TYPE IS NULL',
      );

      return;
    }

    if (remoteDescriptionSet) {
      debugPrint(
        'REMOTE DESCRIPTION ALREADY SET',
      );

      return;
    }

    try {
      final webrtc.RTCSessionDescription
      description =
      webrtc.RTCSessionDescription(
        sdp,
        type,
      );

      await peerConnection!
          .setRemoteDescription(
        description,
      );

      remoteDescriptionSet = true;

      debugPrint(
        'REMOTE DESCRIPTION SET SUCCESSFULLY',
      );

      await _processPendingCandidates();
    } catch (e) {
      debugPrint(
        'SET REMOTE DESCRIPTION ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // ADD ICE CANDIDATE
  // ============================================================

  Future<void> addIceCandidate(
      String? candidate,
      String? sdpMid,
      int? sdpMLineIndex,
      ) async {
    if (peerConnection == null) {
      debugPrint(
        'PEER CONNECTION NULL - ICE NOT ADDED',
      );

      return;
    }

    if (candidate == null ||
        candidate.isEmpty) {
      return;
    }

    final webrtc.RTCIceCandidate
    iceCandidate =
    webrtc.RTCIceCandidate(
      candidate,
      sdpMid,
      sdpMLineIndex,
    );

    if (!remoteDescriptionSet) {
      pendingCandidates.add(
        iceCandidate,
      );

      debugPrint(
        'ICE CANDIDATE QUEUED',
      );

      return;
    }

    try {
      await peerConnection!.addCandidate(
        iceCandidate,
      );

      debugPrint(
        'REMOTE ICE CANDIDATE ADDED',
      );
    } catch (e) {
      debugPrint(
        'ADD ICE CANDIDATE ERROR: $e',
      );
    }
  }

  // ============================================================
  // PROCESS PENDING ICE
  // ============================================================

  Future<void>
  _processPendingCandidates() async {
    if (peerConnection == null) {
      return;
    }

    if (!remoteDescriptionSet) {
      return;
    }

    if (pendingCandidates.isEmpty) {
      return;
    }

    debugPrint(
      'PROCESSING ${pendingCandidates.length} PENDING ICE CANDIDATES',
    );

    for (final webrtc.RTCIceCandidate
    candidate
    in List<webrtc.RTCIceCandidate>.from(
      pendingCandidates,
    )) {
      try {
        await peerConnection!
            .addCandidate(
          candidate,
        );
      } catch (e) {
        debugPrint(
          'PENDING ICE ERROR: $e',
        );
      }
    }

    pendingCandidates.clear();

    debugPrint(
      'PENDING ICE CANDIDATES PROCESSED',
    );
  }

  // ============================================================
  // MUTE
  // ============================================================

  void setMute(
      bool mute,
      ) {
    if (localStream == null) {
      return;
    }

    final List<webrtc.MediaStreamTrack>
    tracks =
    localStream!.getAudioTracks();

    for (final webrtc.MediaStreamTrack
    track in tracks) {
      track.enabled = !mute;
    }

    debugPrint(
      mute
          ? 'MIC MUTED'
          : 'MIC UNMUTED',
    );
  }

  // ============================================================
  // SPEAKER
  // ============================================================

  void setSpeaker(
      bool value,
      ) {
    try {
      webrtc.Helper.setSpeakerphoneOn(
        value,
      );

      debugPrint(
        value
            ? 'SPEAKER ON'
            : 'SPEAKER OFF',
      );
    } catch (e) {
      debugPrint(
        'SPEAKER ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE HISTORY FOR ONE USER
  // ============================================================

  Future<void> saveCallHistoryForUser({
    required String userId,
    required Map<String, dynamic> callData,
  }) async {
    if (userId.isEmpty) {
      debugPrint(
        'HISTORY USER ID EMPTY',
      );

      return;
    }

    final String callId =
        callData['callId']?.toString() ??
            '';

    if (callId.isEmpty) {
      debugPrint(
        'HISTORY CALL ID EMPTY',
      );

      return;
    }

    try {
      await firestore
          .collection('users')
          .doc(userId)
          .collection('callHistory')
          .doc(callId)
          .set(
        {
          ...callData,
          'historyCreatedAt':
          FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'HISTORY SAVED: '
            'users/$userId/callHistory/$callId',
      );
    } catch (e) {
      debugPrint(
        'SAVE HISTORY ERROR: $e',
      );
    }
  }

  // ============================================================
  // SAVE HISTORY FOR BOTH USERS
  // ============================================================

  Future<void> saveCallHistoryForBothUsers({
    required Map<String, dynamic> callData,
  }) async {
    final String callerId =
        callData['callerId']?.toString() ??
            '';

    final String receiverId =
        callData['receiverId']?.toString() ??
            '';

    debugPrint(
      'CALLER: $callerId',
    );

    debugPrint(
      'RECEIVER: $receiverId',
    );

    if (callerId.isEmpty ||
        receiverId.isEmpty) {
      debugPrint(
        'CANNOT SAVE HISTORY',
      );

      return;
    }

    await saveCallHistoryForUser(
      userId: callerId,
      callData: callData,
    );

    await saveCallHistoryForUser(
      userId: receiverId,
      callData: callData,
    );

    debugPrint(
      'HISTORY SAVED FOR BOTH USERS',
    );
  }

  // ============================================================
  // CLOSE CONNECTION
  // ============================================================

  Future<void> closeConnection() async {
    try {
      if (localStream != null) {
        for (final webrtc.MediaStreamTrack
        track in localStream!.getTracks()) {
          track.stop();
        }

        await localStream!.dispose();
      }

      if (peerConnection != null) {
        await peerConnection!.close();
      }
    } catch (e) {
      debugPrint(
        'CLOSE CONNECTION ERROR: $e',
      );
    }

    pendingCandidates.clear();

    remoteDescriptionSet = false;

    localStream = null;

    peerConnection = null;

    onConnectionStateChanged = null;

    onIceConnectionStateChanged = null;

    debugPrint(
      'CALL CONNECTION CLOSED',
    );
  }
}