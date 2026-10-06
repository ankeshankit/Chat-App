// /**
// * Import function triggers from their respective submodules:
// *
// * const {onCall} = require("firebase-functions/v2/https");
// * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
// *
// * See a full list of supported triggers at https://firebase.google.com/docs/functions
// */
//
// const {setGlobalOptions} = require("firebase-functions");
// const {onRequest} = require("firebase-functions/https");
// const logger = require("firebase-functions/logger");
//
// // For cost control, you can set the maximum number of containers that can be
// // running at the same time. This helps mitigate the impact of unexpected
// // traffic spikes by instead downgrading performance. This limit is a
// // per-function limit. You can override the limit for each function using the
// // `maxInstances` option in the function's options, e.g.
// // `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// // NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// // functions should each use functions.runWith({ maxInstances: 10 }) instead.
// // In the v1 API, each function can only serve one request per container, so
// // this will be the maximum concurrent request count.
// setGlobalOptions({ maxInstances: 10 });
//
// // Create and deploy your first functions
// // https://firebase.google.com/docs/functions/get-started
//
// // exports.helloWorld = onRequest((request, response) => {
// //   logger.info("Hello logs!", {structuredData: true});
// //   response.send("Hello from Firebase!");
// // });

const {
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");

const {
  setGlobalOptions,
} = require("firebase-functions");

const {
  getMessaging,
} = require("firebase-admin/messaging");

const {
  getFirestore,
} = require("firebase-admin/firestore");

const {
  initializeApp,
} = require("firebase-admin/app");

const logger =
  require("firebase-functions/logger");


// ==========================================
// INITIALIZE FIREBASE ADMIN
// ==========================================

initializeApp();

const db = getFirestore();


// ==========================================
// GLOBAL OPTIONS
// ==========================================

setGlobalOptions({
  region: "asia-south1",
  maxInstances: 10,
});


// ==========================================
// MESSAGE NOTIFICATION
// ==========================================

exports.sendMessageNotification =
  onDocumentCreated(
      "chatRooms/{chatRoomId}/messages/{messageId}",
      async (event) => {
        try {
          const snapshot = event.data;

          if (!snapshot) {
            logger.log(
                "Message document does not exist.",
            );
            return;
          }

          const messageData = snapshot.data();

          if (!messageData) {
            return;
          }

          const senderId =
          messageData.senderId?.toString() ?? "";

          const receiverId =
          messageData.receiverId?.toString() ?? "";

          const message =
          messageData.message?.toString() ?? "";

          const chatRoomId =
          event.params.chatRoomId;

          if (!senderId || !receiverId) {
            logger.log(
                "Sender or receiver ID missing.",
            );
            return;
          }

          // Get sender information
          const senderSnapshot =
          await db
              .collection("users")
              .doc(senderId)
              .get();

          const senderData =
          senderSnapshot.data() || {};

          const senderName =
          senderData.name?.toString() ??
          "New Message";


          // Get receiver information
          const receiverSnapshot =
          await db
              .collection("users")
              .doc(receiverId)
              .get();

          if (!receiverSnapshot.exists) {
            logger.log(
                "Receiver user not found.",
            );
            return;
          }

          const receiverData =
          receiverSnapshot.data() || {};

          const fcmToken =
          receiverData.fcmToken?.toString() ?? "";

          if (!fcmToken) {
            logger.log(
                "Receiver FCM token not found.",
            );
            return;
          }


          // Send message notification
          await getMessaging().send({
            token: fcmToken,

            notification: {
              title: senderName,
              body: message || "New message",
            },

            data: {
              type: "message",
              chatRoomId: chatRoomId,
              messageId: event.params.messageId,
              senderId: senderId,
              receiverId: receiverId,
            },

            android: {
              priority: "high",

              notification: {
                channelId: "chat_messages",
                sound: "default",
              },
            },

            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          });

          logger.log(
              "Message notification sent successfully.",
          );
        } catch (error) {
          logger.error(
              "Message notification error:",
              error,
          );
        }
      },
  );


// ==========================================
// CALL NOTIFICATION
// ==========================================

exports.sendCallNotification =
  onDocumentCreated(
      "calls/{callId}",
      async (event) => {
        try {
          const snapshot = event.data;

          if (!snapshot) {
            return;
          }

          const callData = snapshot.data();

          if (!callData) {
            return;
          }

          const status =
          callData.status?.toString() ?? "";

          // Only send notification
          // for a new calling state.
          if (status !== "calling") {
            return;
          }

          const callerId =
          callData.callerId?.toString() ?? "";

          const receiverId =
          callData.receiverId?.toString() ?? "";

          const callerName =
          callData.callerName?.toString() ??
          "Someone";

          const callId =
          event.params.callId;

          if (!callerId || !receiverId) {
            logger.log(
                "Caller or receiver ID missing.",
            );
            return;
          }


          // Get receiver information
          const receiverSnapshot =
          await db
              .collection("users")
              .doc(receiverId)
              .get();

          if (!receiverSnapshot.exists) {
            logger.log(
                "Receiver user not found.",
            );
            return;
          }

          const receiverData =
          receiverSnapshot.data() || {};

          const fcmToken =
          receiverData.fcmToken?.toString() ?? "";

          if (!fcmToken) {
            logger.log(
                "Receiver FCM token not found.",
            );
            return;
          }


          // Send call notification
          await getMessaging().send({
            token: fcmToken,

            notification: {
              title: "Incoming Voice Call",
              body: `${callerName} is calling you`,
            },

            data: {
              type: "call",
              callId: callId,
              callerId: callerId,
              receiverId: receiverId,
              callerName: callerName,
              receiverName:
              callData.receiverName
                  ?.toString() ?? "",
            },

            android: {
              priority: "high",

              notification: {
                channelId: "incoming_calls",
                sound: "default",
              },
            },

            apns: {
              payload: {
                aps: {
                  sound: "default",
                  contentAvailable: true,
                },
              },
            },
          });

          logger.log(
              "Call notification sent successfully.",
          );
        } catch (error) {
          logger.error(
              "Call notification error:",
              error,
          );
        }
      },
  );
