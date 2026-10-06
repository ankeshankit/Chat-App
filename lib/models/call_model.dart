import 'package:cloud_firestore/cloud_firestore.dart';

class CallModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final String type;
  final String status;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? endedAt;
  final String endedBy;
  final int duration;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    required this.type,
    required this.status,
    this.createdAt,
    this.acceptedAt,
    this.endedAt,
    this.endedBy = '',
    this.duration = 0,
  });

  factory CallModel.fromMap(
      Map<String, dynamic> map,
      String documentId,
      ) {
    return CallModel(
      callId:
      map['callId']?.toString() ??
          documentId,

      callerId:
      map['callerId']?.toString() ??
          '',

      receiverId:
      map['receiverId']?.toString() ??
          '',

      callerName:
      map['callerName']?.toString() ??
          '',

      receiverName:
      map['receiverName']?.toString() ??
          '',

      type:
      map['type']?.toString() ??
          'voice',

      status:
      map['status']?.toString() ??
          '',

      createdAt:
      map['createdAt'] is Timestamp
          ? (map['createdAt']
      as Timestamp)
          .toDate()
          : null,

      acceptedAt:
      map['acceptedAt'] is Timestamp
          ? (map['acceptedAt']
      as Timestamp)
          .toDate()
          : null,

      endedAt:
      map['endedAt'] is Timestamp
          ? (map['endedAt']
      as Timestamp)
          .toDate()
          : null,

      endedBy:
      map['endedBy']?.toString() ??
          '',

      duration:
      map['duration'] is int
          ? map['duration'] as int
          : int.tryParse(
        '${map['duration'] ?? 0}',
      ) ??
          0,
    );
  }
}