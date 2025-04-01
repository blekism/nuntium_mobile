const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnNewArticle = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const snapshot = event.data;

    if (!snapshot) {
      logger.log("No data associated with the event");
      return null;
    }

    const articleData = snapshot.data();

    // Fetch all user FCM tokens (assume stored in Firestore under 'users' collection)
    const tokensSnapshot = await admin.firestore().collection("users").get();
    const tokens = tokensSnapshot.docs
      .map((doc) => doc.data().fcmToken)
      .filter(Boolean);

    if (tokens.length === 0) {
      logger.log("No FCM tokens available.");
      return null;
    }

    // Define notification payload
    const message = {
      notification: {
        title: "New Article Posted!",
        body:
          articleData.title ||
          "A new article has been published. Check it out!",
      },
      tokens: tokens, // Send to multiple users
    };

    // Send notification
    return admin
      .messaging()
      .sendEachForMulticast(message)
      .then((response) => {
        logger.log("Notifications sent successfully:", response.successCount);
        if (response.failureCount > 0) {
          const failedTokens = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              failedTokens.push(tokens[idx]);
            }
          });
          logger.log("Failed tokens:", failedTokens);
        }
      })
      .catch((error) => {
        logger.error("Error sending notifications:", error);
      });
  }
);

exports.cleanInput = onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    if (!req.body || !req.body.text) {
      res.status(400).send("Missing text in request body");
      return;
    }

    const text = req.body.text;
    const apiKey = "AIzaSyAs80PkwTQR_eXyefC_6GaIh4a19kL4eng"; // Securely load API key

    if (!apiKey) {
      res.status(500).send("Missing GOOGLE_API_KEY environment variable");
      return;
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-1.5-flash-latest",
    });

    const prompt = `Correct the spelling, grammar, and remove any profanity from the following text: ${text}. Return only the corrected text.`;

    const result = await model.generateContent(prompt);
    const response = await result.response;
    const cleanedText = response.text().trim();

    res.status(200).json({ cleanedText });
  } catch (error) {
    logger.error("Error cleaning input:", error);
    res.status(500).send("Error cleaning input");
  }
});
