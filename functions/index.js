const admin = require("firebase-admin");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");

admin.initializeApp();

exports.sendFeesAlert = onDocumentCreated(
  "fees/{feeId}",
  async (event) => {

    const data = event.data.data();

    const studentId = data.studentId;

    if (!studentId) return;

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(studentId)
      .get();

    const token = userDoc.data()?.fcmToken;

    if (!token) return;

    await admin.messaging().send({
      notification: {
        title: "Fees Added",
        body: `₹${data.amount} fees added`,
      },
      token: token,
    });
  }
);