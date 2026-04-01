const admin = require('firebase-admin');

let isFirebaseInitialized = false;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    isFirebaseInitialized = true;
    console.log("Firebase Admin Initialized");
  } catch (error) {
    console.error("Firebase Init Error:", error.message);
  }
}

module.exports = { admin, isFirebaseInitialized };
