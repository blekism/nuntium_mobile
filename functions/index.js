const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const { GoogleGenerativeAI } = require("@google/generative-ai");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");

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

exports.createSubtasksOnApproval = onDocumentUpdated(
  "tasks/{taskId}",
  async (event) => {
    const previous = event.data.before.data();
    const current = event.data.after.data(); 
    const now = admin.firestore.Timestamp.now();
    const nowMillis = now.toMillis();
    const threeHrsMillis = 3 * 60 * 60 * 1000;
    const deadlineMillis = nowMillis + threeHrsMillis;
    const deadlineTimestamp = admin.firestore.Timestamp.fromMillis(deadlineMillis);

    if (previous.status !== "doing" && current.status === "doing" && current.eicApproved) {
      const taskId = event.params.taskId;
      const subcollectionRef = admin.firestore().collection(`tasks/${taskId}/assigned_tasks`);
      const parentref = admin.firestore().collection(`tasks`).doc(taskId);

      try {
        // Query for an available writer in the task's section
        const writeAssignSnapshot = await admin.firestore().collection("users")
          .where("isAvailable", "==", true)
          .where("section", "==", current.section)
          .where("role", "!=", "section_editors")
          .orderBy("assignedCount", "asc")
          .limit(1)
          .get();

        let writerAssigneeId = "";
        if (!writeAssignSnapshot.empty) {
          const writerDoc = writeAssignSnapshot.docs[0];
          writerAssigneeId = writerDoc.id;
          // Increment the assigned count for the writer
          await writerDoc.ref.update({ assignedCount: admin.firestore.FieldValue.increment(1) });
        } else {
          logger.warn(`No available writer found for section: ${current.section}`);
          // Optionally handle the case where no writer is available
        }

        // Query for an available pubmat creator in the "AhIBjLyTec3anoj3mYkz" section
        const pubAssignSnapshot = await admin.firestore().collection("users")
          .where("isAvailable", "==", true)
          .where("section", "==", "AhIBjLyTec3anoj3mYkz")
          .where("role", "!=", "section_editors")
          .orderBy("assignedCount", "asc")
          .limit(1)
          .get();

        let pubAssigneeId = "";
        if (!pubAssignSnapshot.empty) {
          const pubDoc = pubAssignSnapshot.docs[0];
          pubAssigneeId = pubDoc.id;
          // Increment the assigned count for the pubmat creator
          await pubDoc.ref.update({ assignedCount: admin.firestore.FieldValue.increment(1) });
        } else {
          logger.warn(`No available pubmat creator found for section: AhIBjLyTec3anoj3mYkz`);
          // Optionally handle the case where no pubmat creator is available
        }

        await subcollectionRef.add({
          taskname: "Create a Pubmat for" + " " + previous.title,
          task_type: "Pubmat",
          deadline: deadlineTimestamp,
          created_at: now,
          status: "To Do",
          assignee_id: pubAssigneeId,
        });

        await subcollectionRef.add({
          taskname: "Create the Content for" + " " + previous.title,
          task_type: "Writing",
          deadline: deadlineTimestamp,
          created_at: now,
          status: "To Do",
          assignee_id: writerAssigneeId,
        });

        await parentref.update({ total_subtask: 2, projectStep: FieldValue.increment(1) });

        logger.log(`Subtasks created for post ${taskId}`);
      } catch (error) {
        logger.error("Error creating subtasks:", error);
      }
    }
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
    const apiKey = "AIzaSyAs80PkwTQR_eXyefC_6GaIh4a19kL4eng";

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