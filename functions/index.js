const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

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

