/* eslint-disable quotes */
/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// eslint-disable-next-line object-curly-spacing
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();


const db = admin.firestore();
const messaging = admin.messaging();

exports.sendFollowNotification = onDocumentCreated("users/{userId}/followers/{followerId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("Keine Daten im Event gefunden für sendFollowNotification.");
    return null;
  }

  const recipientId = event.params.userId;
  const actorId = event.params.followerId;

  console.log(`V2 Trigger: ${actorId} folgt ${recipientId}`);

  try {
    const actorDoc = await db.collection("users").doc(actorId).get();
    if (!actorDoc.exists) {
      console.error("V2: Follower-Dokument nicht gefunden:", actorId);
      return null;
    }
    const actorData = actorDoc.data();
    const actorName = (actorData && actorData.name) ? actorData.name : "Ein Nutzer";

    const recipientDoc = await db.collection("users").doc(recipientId).get();
    if (!recipientDoc.exists) {
      console.error("V2: Empfänger-Dokument nicht gefunden:", recipientId);
      return null;
    }
    const recipientData = recipientDoc.data();
    const recipientToken = (recipientData && recipientData.notificationToken) ? recipientData.notificationToken : null;

    const recipientEnabled = (recipientData && typeof recipientData.userNotificationsEnabled === 'boolean') ? recipientData.userNotificationsEnabled : true;

    if (recipientEnabled && recipientToken) {
      console.log(`V2: Sende Follow-Benachrichtigung an Token: ${recipientToken}`);
      /* const payload = {
        notification: {
          title: "Neuer Follower!",
          body: `${followerName} folgt dir jetzt.`,
        },
      };

      await messaging.send(recipientToken, payload);*/

      const message = {
        notification: {
          title: "Neuer Follower!",
          body: `${actorName} folgt dir jetzt.`,
        },
        token: recipientToken,
        data: {
          type: 'follow',
          screen: 'notificationsScreen',
        },
      };

      try {
        const response = await messaging.send(message);
        console.log("V2: Follow-Benachrichtigung erfolgreich gesendet:", response);
      } catch (error) {
        console.error("V2: Fehler beim Senden der Follow-Benachrichtigung:", error);
        if (error.code === 'messaging/registration-token-not-registered') {
          try {
            await db.collection("users").doc(recipientId).update({notificationToken: admin.firestore.FieldValue.delete()});
          } catch (cleanupError) {
            console.error("V2: Fehler beim Bereinigen des Tokens:", cleanupError);
          }
        }
      }
    } else {
      console.log(`V2: Keine Benachrichtigung gesendet an ${recipientId} (Token: ${recipientToken}, Enabled: ${recipientEnabled})`);
    }
  } catch (error) {
    console.error("V2: Fehler in sendFollowNotification:", error);
  }
  return null;
});

exports.sendReviewNotification = onDocumentCreated("restaurantReviews/{reviewId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("Keine Daten im Event gefunden für sendReviewNotification.");
    return null;
  }

  const reviewData = snapshot.data();
  if (!reviewData) {
    console.error("Review-Daten nicht gefunden.");
    return null;
  }

  const reviewerId = reviewData.userId;
  const reviewerName = (reviewData && reviewData.userName) ? reviewData.userName : "Ein Nutzer";

  const restaurantName = (reviewData && reviewData.restaurantName) ? reviewData.restaurantName : "einem Restaurant";
  const rating = reviewData.rating;

  console.log(`Neues Review Trigger von ${reviewerId}`);

  try {
    const followersSnapshot = await db.collection("users").doc(reviewerId).collection("followers").get();

    if (followersSnapshot.empty) {
      console.log("Reviewer hat keine Follower.");
      return null;
    }

    /* const payload = {
      notification: {
        title: `Neue Bewertung von ${reviewerName}`,
        body: `${reviewerName} hat ${restaurantName} mit ${rating} ⭐ bewertet.`,
      },
    };*/

    const tokensToSend = [];

    for (const doc of followersSnapshot.docs) {
      const followerId = doc.id;
      try {
        const followerDoc = await db.collection("users").doc(followerId).get();
        if (followerDoc.exists) {
          const followerData = followerDoc.data();
          const followerToken = (followerData && followerData.notificationToken) ? followerData.notificationToken : null;
          const followerEnabled = (followerData && typeof followerData.userNotificationsEnabled === 'boolean') ? followerData.userNotificationsEnabled : true;

          if (followerEnabled && followerToken) {
            console.log(`Füge Token für Follower ${followerId} hinzu: ${followerToken}`);
            tokensToSend.push(followerToken);
          } else {
            console.log(`Keine Review-Benachrichtigung an Follower ${followerId} (Token: ${followerToken}, Enabled: ${followerEnabled})`);
          }
        }
      } catch (error) {
        console.error(`Fehler beim Holen des Follower-Dokuments ${followerId}:`, error);
      }
    }

    if (tokensToSend.length > 0) {
      console.log(`Sende Review-Benachrichtigung an ${tokensToSend.length} Tokens.`);
      const multicastMessage = {
        notification: {
          title: `Neue Bewertung von ${reviewerName}`,
          body: `${reviewerName} hat ${restaurantName} mit ${rating} ⭐ bewertet.`,
        },
        tokens: tokensToSend,
        data: {
          type: 'review',
          screen: 'homeScreen',
          restaurantId: reviewData.restaurantId || "",
        },
      };
      try {
        const response = await messaging.sendEachForMulticast(multicastMessage);
        console.log(`V2: Review-Benachrichtigung gesendet. Erfolgreich: ${response.successCount}, Fehler: ${response.failureCount}`);

        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              console.error(`Fehler beim Senden an Token ${tokensToSend[idx]}: ${resp.error.code}`);
              if (resp.error.code === 'messaging/registration-token-not-registered' ||
                  resp.error.code === 'messaging/invalid-registration-token') {
                failedTokens.push(tokensToSend[idx]);
              }
            }
          });
          console.warn("-> V2: Token Bereinigung für fehlgeschlagene Tokens wird empfohlen.");
        }
      } catch (error) {
        console.error("V2: Allgemeiner Fehler beim Senden von Multicast Review-Benachrichtigungen:", error);
      }
      // const response = await messaging.sendToDevice(tokensToSend, payload);
      /* console.log(`Review-Benachrichtigungen gesendet. Erfolgreich: ${response.successCount}, Fehler: ${response.failureCount}`);

      response.results.forEach(async (result, index) => {
        const error = result.error;
        if (error) {
          console.error(`Fehler beim Senden an Token ${tokensToSend[index]}:`, error);
          if (error.code === 'messaging/registration-token-not-registered' ||
              error.code === 'messaging/invalid-registration-token') {
            console.warn("-> Token Bereinigung wird empfohlen, ist aber hier nicht implementiert.");
          }
        }
      }); */
    } else {
      console.log("Keine gültigen Tokens zum Senden der Review-Benachrichtigung gefunden.");
    }
  } catch (error) {
    console.error("Fehler in sendReviewNotification:", error);
  }

  return null;
});


exports.checkUsernameExists =
functions.https.onCall(async (database, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Du musst eingeloggt sein.",
    );
  }

  const username = database.username;
  const usersRef = admin.firestore().collection("users");
  const snapshot = await usersRef.where("name", "==", username).get();

  return {exists: !snapshot.empty};
});

