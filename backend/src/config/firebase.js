const admin = require("firebase-admin");

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;

  if (!serviceAccountPath) {
    console.warn(
      "FIREBASE_SERVICE_ACCOUNT_PATH is missing. Firebase Admin is not initialized."
    );
    return null;
  }

  try {
    const serviceAccount = require(serviceAccountPath);
    return admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  } catch (error) {
    console.warn(
      `Unable to initialize Firebase Admin with path "${serviceAccountPath}".`
    );
    console.warn(error.message);
    return null;
  }
}

module.exports = {
  initializeFirebaseAdmin,
};
