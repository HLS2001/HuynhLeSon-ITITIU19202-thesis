const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
exports.updateUserRole = functions.auth.user().onCreate((user) => {
  const email = user.email;
  let role = "user";
  // Check email domain or other conditions to determine role
  if (email && email.endsWith("@example.com")) {
    role = "admin";
  }
  // Update user document in Firestore with role
  return admin.firestore().collection("users").doc(user.uid).set({
    email: email,
    role: role,
  });
});
