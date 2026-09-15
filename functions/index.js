const functions = require("firebase-functions");
const {onDocumentCreated, onDocumentWritten} =
require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, onRequest, HttpsError} =
require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {fal} = require("@fal-ai/client");
const {geohashQueryBounds, distanceBetween, geohashForLocation} =
require("geofire-common");
const admin = require("firebase-admin");
const {S3Client, GetObjectCommand, PutObjectCommand,
  DeleteObjectCommand, DeleteObjectsCommand} =
require("@aws-sdk/client-s3");
const {getSignedUrl} = require("@aws-sdk/s3-request-presigner");
const sharp = require("sharp");
const {randomUUID} = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// virtual tryon call function
// const SEGMIND_API_KEY = defineSecret("SEGMIND_API_KEY");
const FAL_API_KEY = defineSecret("FAL_API_KEY");

// --- Secrets (same pattern as your existing fal.ai key) ---
const b2KeyId = defineSecret("B2_KEY_ID");
const b2AppKey = defineSecret("B2_APP_KEY");


// This function sends a notification to a specific
// device using its FCM token.
// It expects a POST request with JSON body:
// { "token": "device_token", "title": "Hello", "body": "World" }
exports.sendNotification =
functions.https.onRequest(async (req, res) => {
  // CORS: allow the browser to call this from your web admin.
  // Restrict this to your actual domain(s) in production instead of "*".
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Browsers send a preflight OPTIONS request before the real POST
  // whenever a custom header (like Authorization) is involved. It expects
  // a 204 with the CORS headers above and no body.
  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).send("Method Not Allowed");
  }

  // Get the ID token from the Authorization header
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).send("Unauthorized");
  }
  const idToken = authHeader.split("Bearer ")[1];

  try {
    // Verify the token
    await admin.auth().verifyIdToken(idToken);
    // Optional: check if the user has a specific role
    // if (!decodedToken.admin) return res.status(403).send("Forbidden");

    // Now proceed with sending notification
    const {token, title, body, data} = req.body;
    if (!token || !title || !body) {
      return res.status(400).send("Missing fields");
    }

    const message = {
      notification: {title, body},
      data: {
        type: req.body.type || "chat",
        chatId: req.body.chatId || "",
      },
      token,
      // ✅ iOS sound config
      apns: {
        payload: {
          aps: {
            "sound": "default",
          },
        },
        headers: {
          "apns-priority": "10",
          "apns-push-type": "alert",
        },
      },
    };

    // Add data payload if provided
    if (data && typeof data === "object") {
      message.data = data;
    }

    const response = await admin.messaging().send(message);
    res.status(200).json({success: true, messageId: response});
  } catch (error) {
    console.error(error);
    res.status(401).send("Unauthorized");
  }
});

exports.sendBroadcastNotification =
  functions.https.onRequest(async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

    if (req.method === "OPTIONS") {
      return res.status(204).send("");
    }
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).send("Unauthorized");
    }
    const idToken = authHeader.split("Bearer ")[1];

    try {
      await admin.auth().verifyIdToken(idToken);

      const {title, body, audience} = req.body;
      if (!title || !body || !audience) {
        return res.status(400).send("Missing fields");
      }
      if (!["all", "android", "ios"].includes(audience)) {
        return res.status(400).send("Invalid audience");
      }

      let query = admin.firestore().collection("users");
      if (audience === "android") {
        query = query.where("deviceInfo.deviceType", "==", "Android");
      } else if (audience === "ios") {
        query = query.where("deviceInfo.deviceType", "==", "iOS");
      }

      const snapshot = await query.get();
      const tokens = snapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((t) => typeof t === "string" && t.length > 0);

      if (tokens.length === 0) {
        return res.status(200).json(
            {success: true, totalTokens: 0, successCount: 0, failureCount: 0});
      }

      // FCM allows max 500 tokens per multicast request.
      const chunkSize = 500;
      let successCount = 0;
      let failureCount = 0;

      for (let i = 0; i < tokens.length; i += chunkSize) {
        const chunk = tokens.slice(i, i + chunkSize);
        const message = {
          notification: {title, body},
          tokens: chunk,
          apns: {
            payload: {aps: {"sound": "default"}},
            headers: {"apns-priority": "10", "apns-push-type": "alert"},
          },
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        successCount += response.successCount;
        failureCount += response.failureCount;
      }

      res.status(200).json({
        success: true,
        totalTokens: tokens.length,
        successCount,
        failureCount,
      });
    } catch (error) {
      console.error(error);
      res.status(401).send("Unauthorized");
    }
  });


// Schedule this function to run every 10 minutes
// and change status if conditions are met
exports.myScheduledFunction = onSchedule("every 10 minutes", async (event) => {
  const now = admin.firestore.Timestamp.now();

  // Query all confirmed bookings where bookingDateTime <= now
  const snapshot = await db
      .collection("appointments")
      .where("status", "==", "confirmed")
      .where("appointmentDate", "<=", now)
      .get();

  if (snapshot.empty) {
    console.log("No past confirmed appointments found.");
    return null;
  }

  // Update each document in a batch to avoid too many individual writes
  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, {status: "completed"});
  });

  await batch.commit();
  console.log(`Updated ${snapshot.size} bookings to completed.`);
  return null;
});


// Scheduled function: runs every 5 minutes
// Sends notification 1 hour to booking time
exports.sendAppointmentReminders =
onSchedule("every 5 minutes", async () => {
  const now = admin.firestore.Timestamp.now();
  // Calculate timestamps for 55 and 65 minutes from now
  const fiftyFiveMinutesLater =
new Date(now.toDate().getTime() + 55 * 60 * 1000);
  const sixtyFiveMinutesLater =
new Date(now.toDate().getTime() + 65 * 60 * 1000);
  const fiftyFiveMinutesLaterTimestamp =
admin.firestore.Timestamp.fromDate(fiftyFiveMinutesLater);
  const sixtyFiveMinutesLaterTimestamp =
admin.firestore.Timestamp.fromDate(sixtyFiveMinutesLater);

  console.log(`Checking appointments between ${fiftyFiveMinutesLater}
  and ${sixtyFiveMinutesLater}`);

  // Query confirmed appointments in the next hour
  // that haven"t received a reminder yet
  const snapshot = await db.collection("appointments")
      .where("status", "==", "confirmed")
      .where("appointmentDate", ">=", fiftyFiveMinutesLaterTimestamp)
      .where("appointmentDate", "<=", sixtyFiveMinutesLaterTimestamp)
      .where("reminderSent", "==", false) // only unsent
      .get();

  if (snapshot.empty) {
    console.log("No new reminders to send.");
    return null;
  }

  const promises = [];
  snapshot.forEach((doc) => {
    const booking = doc.data();
    const userId = booking.userId;
    const bookingId = doc.id;
    const sName = booking.serviceName;

    // Fetch the user"s FCM token
    const userPromise = db.collection("users").doc(userId).get()
        .then(async (userDoc) => {
          if (!userDoc.exists) {
            console.log(`User ${userId} not found`);
            return;
          }
          const userData = userDoc.data();
          const fcmToken = userData ? userData.fcmToken : null;
          if (!fcmToken) {
            console.log(`No FCM token for user ${userId}`);
            return;
          }

          // Construct notification message
          const message = {
            token: fcmToken,
            notification: {
              title: "Appointment Reminder",
              body: `You have an appointment in about 1 hour: ${sName}.`,
            },
            data: {
              bookingId: bookingId,
              type: "appointment_reminder",
            },
          };

          // Send the notification
          try {
            await admin.messaging().send(message);
            console.log(`Reminder sent for booking ${bookingId}`);

            // Mark reminder as sent
            await db.collection("appointments").doc(bookingId).update({
              reminderSent: true,
              reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          } catch (error) {
            console.error(`Failed to send reminder for booking
              ${bookingId}:`, error);
          }
        })
        .catch((error) => {
          console.error(`Error processing user ${userId}:`, error);
        });

    promises.push(userPromise);
  });

  await Promise.allSettled(promises);
  console.log("Reminder function finished.");
  return null;
});


// ─────────────────────────────────────────────────────────────────────────
// GEOHASH-BASED SEARCH
//
// Every services/{serviceId} document is expected to carry a `geohash`
// field (kept in sync automatically by syncProviderGeohash below). Search
// queries use geohashQueryBounds to run a small set of range queries that
// only read documents in the geographically relevant area, instead of
// reading the entire "services" collection on every search.
// ─────────────────────────────────────────────────────────────────────────

/**
 * Firestore trigger: keeps `geohash` in sync automatically on every create
 * or update to a services/{serviceId} document, regardless of which client
 * code path wrote it (app, admin panel, bulk import, etc). This is the
 * safety net for new data — no write path has to remember to compute the
 * geohash itself.
 *
 * The equality check before writing prevents an infinite loop: updating
 * `after.ref` inside this function would otherwise re-trigger itself.
 */
exports.syncProviderGeohash =
onDocumentWritten("services/{serviceId}", async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return; // document deleted, nothing to sync

  const data = after.data();
  if (data.latitude == null || data.longitude == null) return;

  const correctGeohash = geohashForLocation([data.latitude, data.longitude]);
  if (data.geohash !== correctGeohash) {
    await after.ref.update({geohash: correctGeohash});
  }
});

/**
 * Ensures every service document has a `randomValue` field, setting one
 * whenever a document is created or updated without it. Runs on every
 * write (create/update/delete), so it also backfills docs that get
 * touched by unrelated updates after this function is deployed — but it
 * will NOT retroactively touch untouched existing docs; run the one-time
 * backfill script for those.
 *
 * @param {import("firebase-functions/v2/firestore").FirestoreEvent} event
 *   The Firestore write event.
 * @return {Promise<void>}
 */
exports.syncRandomValueOnCreate = onDocumentWritten(
    {document: "services/{serviceId}", region: "us-central1"},
    async (event) => {
      const change = event.data;
      if (!change) return;

      // Document was deleted — nothing to do.
      if (!change.after.exists) return;

      // Guard against re-triggering / overwriting a value that's
      // already set, and against looping on our own update() call.
      if (change.after.data().randomValue !== undefined) return;

      await change.after.ref.update({
        randomValue: Math.random(),
        isExclusive: false,
      });
    },
);


exports.syncUserData = onDocumentWritten("users/{userId}", async (event) => {
  const after = event.data?.after;
  if (!after || !after.exists) return; // document deleted, nothing to sync

  const data = after.data();
  const userId = after.id;

  // If the user is a provider, update their services with the new name
  if (data.isProvider === null || data.isProvider === undefined) {
    const usersSnapshot = await db.collection("users")
        .where("id", "==", userId)
        .get();

    const batch = db.batch();
    usersSnapshot.forEach((usereDoc) => {
      batch.update(usereDoc.ref, {isProvider: false});
    });
    await batch.commit();
  }
});

/**
 * Searches approved providers within a radius of the user's location,
 * optionally filtered by region/district and a free-text query.
 */
exports.searchProviders = onCall(async (request) => {
  const {
    query = "",
    region,
    district,
    userLat,
    userLng,
    sortBy = "distance",
    page = 1,
    pageSize = 20,
  } = request.data;

  if (userLat == null || userLng == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "User location is required.",
    );
  }

  const center = [userLat, userLng];

  let snapshot;
  try {
    let q = db.collection("services").where("status", "==", "approved");

    if (region && region.trim() !== "") {
      q = q.where("region", "==", region);
      if (district && district.trim() !== "") {
        q = q.where("district", "==", district);
      }
    }

    snapshot = await q.get();
  } catch (err) {
    console.error("Firestore query failed:", err);
    throw new functions.https.HttpsError(
        "internal",
        "Search failed. Please try again.",
    );
  }

  const queryLower = query.toLowerCase().trim();
  const queryTokens = queryLower.split(/\s+/).filter(Boolean);
  const allResults = [];

  snapshot.forEach((doc) => {
    const provider = doc.data();
    if (provider.latitude == null || provider.longitude == null) return;

    const distanceKm =
      distanceBetween(center, [provider.latitude, provider.longitude]);

    if (queryTokens.length > 0) {
      const name = (provider.name || "").toLowerCase();
      const category = (provider.category || "").toLowerCase();
      const serviceNames = Array.isArray(provider.services) ?
        provider.services
            .map((s) => (s && s.name ? String(s.name).toLowerCase() : ""))
            .filter(Boolean) :
        [];
      const haystack = `${name} ${category} ${serviceNames.join(" ")}`;
      const matchesAllTokens = queryTokens.every((t) => haystack.includes(t));
      if (!matchesAllTokens) return;
    }

    allResults.push({
      id: doc.id,
      ...provider,
      distance: distanceKm,
      distanceText: `${distanceKm.toFixed(1)} km`,
    });
  });

  if (sortBy === "distance") {
    allResults.sort((a, b) => a.distance - b.distance);
  } else if (sortBy === "rating") {
    allResults.sort((a, b) => (b.rating || 0) - (a.rating || 0));
  }

  const validPage = Math.max(1, page);
  const validPageSize = Math.min(50, Math.max(1, pageSize));
  const startIndex = (validPage - 1) * validPageSize;
  const paginatedResults =
    allResults.slice(startIndex, startIndex + validPageSize);

  return {
    providers: paginatedResults,
    totalCount: allResults.length,
    page: validPage,
    pageSize: validPageSize,
    hasMore: startIndex + validPageSize < allResults.length,
  };
});

/**
 * Searches approved providers of a specific category within a radius of
 * the user's location. Same geohash-bounded approach as searchProviders.
 */
exports.searchByCategory = onCall(async (request) => {
  const {
    category,
    userLat,
    userLng,
    maxDistanceKm = 50,
    sortBy = "distance",
    page = 1,
    pageSize = 20,
  } = request.data;

  if (!category || typeof category !== "string") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "category is required.",
    );
  }
  if (userLat == null || userLng == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "User location is required.",
    );
  }
  if (typeof maxDistanceKm !== "number" || maxDistanceKm <= 0) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "maxDistanceKm must be a positive number.",
    );
  }

  const center = [userLat, userLng];
  const radiusMeters = maxDistanceKm * 1000;
  const bounds = geohashQueryBounds(center, radiusMeters);

  let snapshots;
  try {
    const queryPromises = bounds.map(([start, end]) => {
      const q = db.collection("services")
          .where("status", "==", "approved")
          .where("category", "==", category)
          .orderBy("geohash")
          .startAt(start)
          .endAt(end);
      return q.get();
    });
    snapshots = await Promise.all(queryPromises);
  } catch (err) {
    console.error("Firestore geo query failed:", err);
    throw new functions.https.HttpsError(
        "internal",
        "Search failed. Please try again.",
    );
  }

  const seen = new Set();
  const allResults = [];

  for (const snapshot of snapshots) {
    snapshot.forEach((doc) => {
      if (seen.has(doc.id)) return;
      seen.add(doc.id);

      const provider = doc.data();
      if (provider.latitude == null || provider.longitude == null) return;

      const distanceKm =
      distanceBetween(center, [provider.latitude, provider.longitude]);
      if (distanceKm > maxDistanceKm) return;

      allResults.push({
        id: doc.id,
        ...provider,
        distance: distanceKm,
        distanceText: `${distanceKm.toFixed(1)} km`,
      });
    });
  }

  if (sortBy === "distance") {
    allResults.sort((a, b) => a.distance - b.distance);
  } else if (sortBy === "rating") {
    allResults.sort((a, b) => (b.rating || 0) - (a.rating || 0));
  }

  const validPage = Math.max(1, page);
  const validPageSize = Math.min(50, Math.max(1, pageSize));
  const startIndex = (validPage - 1) * validPageSize;
  const paginatedResults =
  allResults.slice(startIndex, startIndex + validPageSize);

  return {
    providers: paginatedResults,
    totalCount: allResults.length,
    page: validPage,
    pageSize: validPageSize,
    hasMore: startIndex + validPageSize < allResults.length,
  };
});


// function to delete user account on request
exports.deleteUser = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }
  const uid = request.auth.uid;

  const batch = db.batch();

  // Delete user document
  const userRef = db.collection("users").doc(uid);
  batch.delete(userRef);

  // Delete user"s services (if provider)
  const servicesQuery = db.collection("services")
      .where("providerId", "==", uid);
  const servicesSnap = await servicesQuery.get();
  servicesSnap.forEach((doc) => batch.delete(doc.ref));

  // Delete user"s bookings (participants array contains uid)
  const bookingsQuery = db.collection("appointments")
      .where("participants", "array-contains", uid);
  const bookingsSnap = await bookingsQuery.get();
  bookingsSnap.forEach((doc) => batch.delete(doc.ref));

  // Delete user"s favorites (subcollection)
  const favQuery = db.collection("users").doc(uid).collection("favorites");
  const favSnap = await favQuery.get();
  favSnap.forEach((doc) => batch.delete(doc.ref));

  // Commit all deletions
  await batch.commit();

  // Finally, delete the Firebase Auth user
  await admin.auth().deleteUser(uid);

  return {success: true};
});


// scheduled function to change booking status
// when time expires.
exports.expirePendingAppointments = onSchedule(
    "every 60 minutes", async () => {
      const now = admin.firestore.Timestamp.now();

      // Calculate grace period: e.g., 1 hour after appointment time
      // We"ll consider appointments that have already passed
      // (appointmentDateTime <= now)
      // Optionally, you can add a grace period: appointmentDateTime
      // <= now - grace
      // For simplicity, we use exactly past time.
      const snapshot = await db.collection("appointments")
          .where("status", "==", "pending")
          .where("appointmentDate", "<=", now)
          .get();

      if (snapshot.empty) {
        console.log("No expired pending appointments found.");
        return null;
      }

      const batch = db.batch();
      const tokensToSend = [];

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const appointmentId = doc.id;

        // Update status to cancelled
        batch.update(doc.ref, {
          status: "cancelled",
          cancelReason: "appointment expired",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Collect user tokens for notifications
        const clientId = data.userId;
        const providerId = data.providerId;
        tokensToSend.push({clientId, providerId, appointmentId,
          serviceName: data.serviceName});
      }

      await batch.commit();

      // Send notifications
      for (const item of tokensToSend) {
        const [clientDoc, providerDoc] = await Promise.all([
          db.collection("users").doc(item.clientId).get(),
          db.collection("users").doc(item.providerId).get(),
        ]);

        const clientToken = clientDoc.exists ? clientDoc.data().fcmToken : null;
        const providerToken =
        providerDoc.exists ? providerDoc.data().fcmToken : null;

        const c1 = `Your appointment for ${item.serviceName} has been`;
        const c2 = "cancelled because the provider did not confirm it in time.";

        const clientMessage = {
          token: clientToken,
          notification: {
            title: "Booking Expired",
            body: `${c1} ${c2}`,
          },
          data: {
            type: "appointment_expired",
            appointmentId: item.appointmentId,
          },
        };

        const p1 = "You did not confirm the appointment for";
        const p2 = `${item.serviceName}. It has been automatically cancelled.`;

        const providerMessage = {
          token: providerToken,
          notification: {
            title: "Booking Expired – No Confirmation",
            body: `${p1} ${p2}`,
          },
          data: {
            type: "appointment_expired",
            appointmentId: item.appointmentId,
          },
        };

        // Send if token exists
        if (clientToken) {
          try {
            await admin.messaging().send(clientMessage);
          } catch (e) {
            console.error(
                `Failed to send client notification for
                ${item.clientId}:`, e);
          }
        }
        if (providerToken) {
          try {
            await admin.messaging().send(providerMessage);
          } catch (e) {
            console.error(
                `Failed to send provider notification for
                ${item.providerId}:`, e);
          }
        }
      }

      console.log(`Cancelled ${snapshot.size} expired pending appointments.`);
      return null;
    });


exports.computeServicePairs =
  onSchedule("0 2 * * *", async () => {
    const snapshot = await db.collection("appointments")
        .where("status", "in", ["confirmed", "completed"])
        .get();

    // Group services by userId
    const userServices = {};
    snapshot.forEach((doc) => {
      const data = doc.data();
      const userId = data.userId;
      const serviceId = data.serviceId; // adjust field name if different
      if (!userId || !serviceId) return;
      if (!userServices[userId]) userServices[userId] = new Set();
      userServices[userId].add(serviceId);
    });

    // Count co‑occurrences
    const pairCount = {};
    for (const userId in userServices) {
      if (Object.prototype.hasOwnProperty.call(userServices, userId)) {
        const services = Array.from(userServices[userId]);
        for (let i = 0; i < services.length; i++) {
          for (let j = i + 1; j < services.length; j++) {
            const pair = [services[i], services[j]].sort();
            const key = `${pair[0]}|${pair[1]}`;
            pairCount[key] = (pairCount[key] || 0) + 1;
          }
        }
      }
    }

    // For each service, collect top recommendations
    const serviceToRecommendations = {};
    for (const [pair, count] of Object.entries(pairCount)) {
      const [serviceA, serviceB] = pair.split("|");
      if (!serviceToRecommendations[serviceA]) {
        serviceToRecommendations[serviceA] = [];
      }
      if (!serviceToRecommendations[serviceB]) {
        serviceToRecommendations[serviceB] = [];
      }
      serviceToRecommendations[serviceA].push({serviceId: serviceB, count});
      serviceToRecommendations[serviceB].push({serviceId: serviceA, count});
    }

    // Sort and keep top 5 per service
    const batch = db.batch();
    for (const serviceId in serviceToRecommendations) {
      if (Object.prototype.hasOwnProperty.call(
          serviceToRecommendations, serviceId)) {
        const recommendations = serviceToRecommendations[serviceId]
            .sort((a, b) => b.count - a.count)
            .slice(0, 5)
            .map((r) => r.serviceId);
        const docRef = db.collection("serviceRecommendations").doc(serviceId);
        batch.set(docRef, {recommendedServiceIds: recommendations},
            {merge: true});
      }
    }

    await batch.commit();
    console.log("Service pair recommendations updated.");
    return null;
  });


exports.virtualHairstyleTryOn = onCall(
    {
      secrets: [FAL_API_KEY],
      timeoutSeconds: 120,
      memory: "512MiB",
    },
    async (request) => {
      // ── Auth check ──────────────────────────────
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
      }

      const uid = request.auth.uid;
      const {imageBase64, hairstylePrompt, hairColor} = request.data;

      if (!imageBase64 || !hairstylePrompt) {
        throw new HttpsError(
            "invalid-argument",
            "imageBase64 and hairstylePrompt are required.",
        );
      }

      // ── Daily usage check ────────────────────────
      const DAILY_LIMIT = 3;
      const today = new Date().toISOString().split("T")[0];
      const usageRef = db
          .collection("tryOnUsage")
          .doc(uid)
          .collection("daily")
          .doc(today);

      const usageSnap = await usageRef.get();
      const currentCount = usageSnap.exists ? usageSnap.data().count : 0;

      if (currentCount >= DAILY_LIMIT) {
        throw new HttpsError(
            "resource-exhausted",
            "Daily limit reached for today. Come back tomorrow!",
        );
      }

      // ── Increment usage count immediately ────────
      await usageRef.set(
          {
            count: admin.firestore.FieldValue.increment(1),
            lastUsed: admin.firestore.FieldValue.serverTimestamp(),
            uid: uid,
            date: today,
          },
          {merge: true},
      );

      const apiKey = FAL_API_KEY.value();
      if (!apiKey) {
        throw new HttpsError(
            "failed-precondition",
            "FAL_API_KEY is not configured.",
        );
      }

      fal.config({credentials: apiKey});

      try {
        // Step 1: Upload image to fal storage first for better quality
        const imageBuffer = Buffer.from(imageBase64, "base64");
        const imageFile = new File([imageBuffer], "upload.jpg", {
          type: "image/jpeg",
        });
        const uploadedUrl = await fal.storage.upload(imageFile);
        console.log("Uploaded image URL:", uploadedUrl);

        // Step 2: Switch to image-apps-v2 to prevent face alteration
        const result = await fal.subscribe("fal-ai/image-apps-v2/hair-change", {
          input: {
            image_url: uploadedUrl,
            target_hairstyle: hairstylePrompt,
            hair_color: hairColor || "natural",
            output_format: "jpeg",
          },
          logs: true,
          onQueueUpdate: (update) => {
            console.log("fal.ai queue status:", update.status);
          },
        });


        console.log("fal.ai result:", JSON.stringify(result.data));

        const output = result.data;
        const outputImageUrl =
          (output && output.images && output.images[0] &&
            output.images[0].url) ||
          (output && output.image && output.image.url) ||
          null;

        if (!outputImageUrl) {
          // ── Refund the count if generation failed ──
          await usageRef.set(
              {count: admin.firestore.FieldValue.increment(-1)},
              {merge: true},
          );
          throw new HttpsError(
              "internal",
              "No image URL in response: " + JSON.stringify(output),
          );
        }

        return {
          success: true,
          outputImageUrl,
          requestId: result.requestId,
          usageToday: currentCount + 1,
          remainingToday: DAILY_LIMIT - (currentCount + 1),
        };
      } catch (error) {
        // Refund count if it was a fal.ai generation error
        if (!(error.code && error.httpErrorCode)) {
          try {
            await usageRef.set(
                {count: admin.firestore.FieldValue.increment(-1)},
                {merge: true},
            );
          } catch (refundErr) {
            console.error("Failed to refund usage count:", refundErr);
          }
        }

        // Log everything we can about the error
        console.error("virtualHairstyleTryOn full error:", JSON.stringify({
          message: error.message || "no message",
          body: error.body || "no body",
          status: error.status || "no status",
          cause: error.cause || "no cause",
          stack: error.stack || "no stack",
        }));

        // If it's already an HttpsError (auth/limit), rethrow directly
        if (error.code && error.httpErrorCode) {
          throw error;
        }

        // Extract the most useful detail from fal.ai error
        let detail = "Try-on failed";
        if (error.body) {
          if (typeof error.body === "string") {
            detail = error.body;
          } else if (error.body.detail) {
            detail = typeof error.body.detail === "string" ?
            error.body.detail :
            JSON.stringify(error.body.detail);
          } else {
            detail = JSON.stringify(error.body);
          }
        } else if (error.message) {
          detail = String(error.message);
        }

        throw new HttpsError("internal", detail);
      }
    });


exports.updateServiceRating =
      onDocumentCreated("reviews/{reviewId}", async (event) => {
        const review = event.data.data();
        const serviceId = review.serviceId;
        const rating = review.rating;

        if (!serviceId) {
          console.warn("Review missing serviceId, skipping update");
          return null;
        }

        const serviceRef = admin.firestore().doc(`services/${serviceId}`);

        try {
          await admin.firestore().runTransaction(async (transaction) => {
            const serviceDoc = await transaction.get(serviceRef);
            const data = serviceDoc.data();

            // Initialize fields if they don't exist (for old documents)
            const currentSum = data.ratingSum ?? 0;
            const currentCount = data.totalReviews ?? 0;

            // Increment by the new review's rating
            const newSum = currentSum + rating;
            const newCount = currentCount + 1;
            const newAverage = newSum / newCount;

            transaction.update(serviceRef, {
              ratingSum: newSum,
              totalReviews: newCount,
              rating: newAverage,
              lastReviewUpdate: admin.firestore.FieldValue.serverTimestamp(),
            });
            console.log(`Updated service ${serviceId}:
            new avg=${(data.ratingSum + rating)/(data.totalReviews+1)},
            count=${data.totalReviews+1}`);
          });
          return null;
        } catch (error) {
          console.error("Transaction failed for service", serviceId, error);
          // Optionally throw to trigger a retry (if failurePolicy is enabled)
          throw error;
        }
      });


exports.sendWeeklyFridayPromo =
onSchedule({
  schedule: "every friday 09:00",
  timeZone: "Africa/Accra",
}, async () => {
  console.log("Running weekly Friday promo notification");

  // Pull users who've opted into notifications
  const snapshot = await db.collection("users")
      .get();

  if (snapshot.empty) {
    console.log("No eligible users found.");
    return null;
  }

  const promises = [];
  snapshot.forEach((doc) => {
    const userData = doc.data();
    const userId = doc.id;
    const fcmToken = userData ? userData.fcmToken : null;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: "Weekend slots are filling up 💇",
        body: "Your favorite provider's weekend slots are filling fast.",
      },
      data: {
        type: "weekly_promo",
      },
    };

    const sendPromise = admin.messaging().send(message)
        .then(() => {
          console.log(`Promo sent to user ${userId}`);
        })
        .catch((error) => {
          console.error(`Failed to send promo to user ${userId}:`, error);
          // Clean up dead tokens so you're not sending to them forever
          if (error.code === "messaging/registration-token-not-registered") {
            return db.collection("users").doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
          }
        });

    promises.push(sendPromise);
  });

  await Promise.allSettled(promises);
  console.log("Weekly Friday promo function finished.");
  return null;
});

exports.sendSundayPlanningReminder =
onSchedule({
  schedule: "every sunday 18:00",
  timeZone: "Africa/Accra",
}, async () => {
  console.log("Running Sunday planning reminder");

  const snapshot = await db.collection("users").get();

  if (snapshot.empty) {
    console.log("No users found.");
    return null;
  }

  const promises = [];
  snapshot.forEach((doc) => {
    const userData = doc.data();
    const userId = doc.id;
    const fcmToken = userData ? userData.fcmToken : null;

    if (!fcmToken) {
      console.log(`No FCM token for user ${userId}`);
      return;
    }

    const message = {
      token: fcmToken,
      notification: {
        title: "New week, new look 💫",
        body: "Beat the rush — book your slot for the week ahead now.",
      },
      data: {
        type: "weekly_planning_reminder",
      },
    };

    const sendPromise = admin.messaging().send(message)
        .then(() => {
          console.log(`Planning reminder sent to user ${userId}`);
        })
        .catch((error) => {
          console.error(`Failed to send to user ${userId}:`, error);
          if (error.code === "messaging/registration-token-not-registered") {
            return db.collection("users").doc(userId).update({
              fcmToken: admin.firestore.FieldValue.delete(),
            });
          }
        });

    promises.push(sendPromise);
  });

  await Promise.allSettled(promises);
  console.log("Sunday planning reminder finished.");
  return null;
});


const MAX_PAGE_LIMIT = 50;

/**
 * Builds the base Firestore query for approved, exclusive services.
 * @return {FirebaseFirestore.Query} The base query.
 */
function baseQuery() {
  return db
      .collection("services")
      .where("status", "==", "approved")
      .where("isExclusive", "==", true);
}

/**
 * Callable function that returns a randomized, paginated page of
 * approved & exclusive services using a stored `randomValue` field
 * for efficient, stable random pagination.
 *
 * Request data:
 * - anchor {number} Random value (0-1) fixed for the whole session.
 * - wrapped {boolean} Whether this session has already crossed the
 *   wrap boundary (i.e. started reading values below the anchor).
 * - lastRandomValue {number|null} Cursor from the previous page.
 * - limit {number} Number of docs to return.
 *
 * @param {import("firebase-functions/v2/https").CallableRequest} request
 *   The callable request.
 * @return {Promise<{
 *   items: Array<Object>,
 *   hasMore: boolean,
 *   wrapped: boolean,
 *   lastRandomValue: number|null,
 * }>} The page of results plus pagination cursors.
 */

exports.getServicesPage = onCall(
    {region: "us-central1"},
    async (request) => {
      const {anchor, wrapped, lastRandomValue, limit} = request.data ?? {};

      if (
        typeof anchor !== "number" || anchor < 0 || anchor > 1 ||
        typeof wrapped !== "boolean" ||
        (lastRandomValue !== null && lastRandomValue !== undefined &&
          typeof lastRandomValue !== "number") ||
        typeof limit !== "number" || limit <= 0 || limit > MAX_PAGE_LIMIT
      ) {
        throw new HttpsError("invalid-argument", "Invalid request params.");
      }

      try {
        const items = [];
        let cursor = lastRandomValue ?? null;

        // Phase 1: still in the "ahead of anchor" range.
        if (!wrapped) {
          let q = baseQuery()
              .where("randomValue", ">=", anchor)
              .orderBy("randomValue", "asc")
              .orderBy("__name__", "asc") // tiebreaker for stable cursors
              .limit(limit);

          if (cursor !== null) {
            q = q.startAfter(cursor);
          }

          const snap = await q.get();
          snap.docs.forEach((d) => items.push({id: d.id, ...d.data()}));

          if (items.length > 0) {
            cursor = items[items.length - 1].randomValue;
          }

          // Ran out before filling the page -> wrap and fill the rest.
          if (items.length < limit) {
            const remaining = limit - items.length;

            const wrapSnap = await baseQuery()
                .where("randomValue", "<", anchor)
                .orderBy("randomValue", "asc")
                .orderBy("__name__", "asc")
                .limit(remaining)
                .get();

            wrapSnap.docs.forEach((d) => items.push({id: d.id, ...d.data()}));
            if (wrapSnap.docs.length > 0) {
              cursor = items[items.length - 1].randomValue;
            }

            // If the wrap query also came up short, we've read everything.
            const hasMore = wrapSnap.docs.length === remaining;
            return {items, hasMore, wrapped: true, lastRandomValue: cursor};
          }

          return {items, hasMore: true,
            wrapped: false, lastRandomValue: cursor};
        }

        // Phase 2: already wrapped, just keep paging through "< anchor".
        let q = baseQuery()
            .where("randomValue", "<", anchor)
            .orderBy("randomValue", "asc")
            .orderBy("__name__", "asc")
            .limit(limit);

        if (cursor !== null) {
          q = q.startAfter(cursor);
        }

        const snap = await q.get();
        snap.docs.forEach((d) => items.push({id: d.id, ...d.data()}));
        if (items.length > 0) {
          cursor = items[items.length - 1].randomValue;
        }

        return {
          items,
          hasMore: items.length === limit,
          wrapped: true,
          lastRandomValue: cursor,
        };
      } catch (e) {
        console.error("getServicesPage error:", e);
        throw new HttpsError("internal", "Failed to fetch service data.");
      }
    },
);

const HAIR_SWAP_PROMPT =
  "Using image 1 as the base image, give the person the exact hairstyle " +
  "from image 2. Keep the face, skin tone, expression, pose, clothing, " +
  "and background from image 1 completely unchanged.";


exports.virtualHairstyleFalSegmindTryOn = onCall(
    {
      secrets: [FAL_API_KEY],
      timeoutSeconds: 60,
      memory: "512MiB",
    },
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
      }

      const uid = request.auth.uid;
      const {userImageBase64, hairstyleImageBase64, styleName, category} =
      request.data;

      if (!userImageBase64 || !hairstyleImageBase64) {
        throw new HttpsError(
            "invalid-argument",
            "Both userImageBase64 and hairstyleImageBase64 are required.",
        );
      }

      // ── Usage Limit Check (3 Free Per Day) ──────────────────
      const DAILY_LIMIT = 3;
      const today = new Date().toISOString().split("T")[0];
      const usageRef = admin
          .firestore()
          .collection("tryOnUsage")
          .doc(uid)
          .collection("daily")
          .doc(today);

      const usageSnap = await usageRef.get();
      const currentCount = usageSnap.exists ? usageSnap.data().count : 0;

      if (currentCount >= DAILY_LIMIT) {
        throw new HttpsError(
            "resource-exhausted",
            "Daily limit reached for today.",
        );
      }

      // Increment daily usage count
      await usageRef.set(
          {
            count: admin.firestore.FieldValue.increment(1),
            lastUsed: admin.firestore.FieldValue.serverTimestamp(),
            uid: uid,
            date: today,
          },
          {merge: true},
      );

      const apiKey = FAL_API_KEY.value();
      fal.config({credentials: apiKey});

      try {
      // Upload Base64 images to Fal storage
        const userBuffer = Buffer.from(userImageBase64, "base64");
        const userFile = new File([userBuffer], "user.jpg",
            {type: "image/jpeg"});
        const userUrl = await fal.storage.upload(userFile);

        const hairBuffer = Buffer.from(hairstyleImageBase64, "base64");
        const hairFile = new File([hairBuffer], "hair.jpg",
            {type: "image/jpeg"});
        const hairUrl = await fal.storage.upload(hairFile);

        // Construct your deployed falWebhook URL
        const webhookUrl =
      `https://us-central1-booking-cd20f.cloudfunctions.net/falWebhook`;

        // Submit request to fal.ai Queue with webhook URL attached
        const result = await fal.queue.submit("fal-ai/hy-wu-edit", {
          input: {
            prompt: HAIR_SWAP_PROMPT,
            image_urls: [userUrl, hairUrl],
            image_size: "auto",
            num_images: 1,
            output_format: "png",
            enable_thinking: false,
            num_inference_steps: 25,
          },
          webhookUrl: webhookUrl,
        });

        await admin.firestore().collection("users").doc(uid)
            .collection("pendingTryOns").doc(result.request_id).set({
              status: "PROCESSING",
              requestId: result.request_id,
              styleName: styleName || "Custom Style",
              category: category || "Custom",
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });

        // Return immediately to React Native (under 3 seconds execution time)
        return {
          success: true,
          status: "PROCESSING",
          requestId: result.request_id,
          remainingToday: DAILY_LIMIT - (currentCount + 1),
        };
      } catch (error) {
      // Rollback usage limit increment if submit fails
        await usageRef.set(
            {count: admin.firestore.FieldValue.increment(-1)},
            {merge: true},
        );
        console.error("Submit Queue Error:", error);
        throw new HttpsError("internal", error.message ||
          "Failed to start try-on processing");
      }
    },
);

// 2. WEBHOOK FUNCTION (Called by fal.ai when generation finishes)
exports.falWebhook = onRequest(
    {
      secrets: [FAL_API_KEY],
      memory: "256MiB",
    },
    async (req, res) => {
      try {
        const {request_id: requestId, status, payload, error} = req.body;

        // Find pending task record across users using requestId
        const pendingSnap = await admin
            .firestore()
            .collectionGroup("pendingTryOns")
            .where("requestId", "==", requestId)
            .get();

        if (pendingSnap.empty) {
          console.warn(`No pending request found for ID: ${requestId}`);
          return res.status(200).send("No matching pending task found");
        }

        const pendingDoc = pendingSnap.docs[0];
        const pendingData = pendingDoc.data();
        const userRef = pendingDoc.ref.parent.parent;

        if (status === "OK" && payload?.images?.[0]?.url) {
          const outputImageUrl = payload.images[0].url;

          // Save generated image directly into user's Firestore tryOnHistory
          await userRef.collection("tryOnHistory").add({
            imageUrl: outputImageUrl,
            styleName: pendingData.styleName,
            category: pendingData.category,
            savedAt: admin.firestore.FieldValue.serverTimestamp(),
            requestId: requestId,
          });

          // Clean up pending document
          await pendingDoc.ref.delete();

          return res.status(200).send("Successfully saved try-on image");
        } else {
          console.error(`Fal execution failed for ${requestId}:`,
              error || "Unknown error");

          // Roll back usage count if fal generation failed
          const today = new Date().toISOString().split("T")[0];
          await admin
              .firestore()
              .collection("tryOnUsage")
              .doc(userRef.id)
              .collection("daily")
              .doc(today)
              .set({count: admin.firestore.FieldValue.increment(-1)},
                  {merge: true});

          await pendingDoc.ref.update({status: "FAILED",
            error: error || "Generation failed"});
          return res.status(200).send("Handled job failure");
        }
      } catch (err) {
        console.error("Webhook processing error:", err);
        return res.status(500).send("Internal Server Error");
      }
    },
);


// Non-secret config — plain values, no defineSecret needed
const B2_ENDPOINT = "s3.us-east-005.backblazeb2.com";
const B2_BUCKET = "timely-shop-products";
const SHOP_CDN_BASE_URL = "https://shop-images.timelygh.com";
const VALID_CATEGORIES = [
  "hair", "nails", "skincare", "makeup",
  "barbering", "tools", "fragrance", "bundles",
];

/**
 * Creates an S3-compatible client configured for Backblaze B2.
 * @return {S3Client} A configured S3 client instance.
 */
function getB2Client() {
  return new S3Client({
    endpoint: `https://${B2_ENDPOINT}`,
    region: "us-west-002",
    credentials: {
      accessKeyId: b2KeyId.value(),
      secretAccessKey: b2AppKey.value(),
    },
  });
}

// --- getUploadUrl ---
exports.getUploadUrl = onCall(
    {region: "us-central1", secrets: [b2KeyId, b2AppKey]},
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

      const {files} = request.data;
      if (!Array.isArray(files) || files.length < 1 || files.length > 5) {
        throw new HttpsError("invalid-argument", "Provide 1-5 files.");
      }

      const b2 = getB2Client();
      const allowedTypes = ["image/webp", "image/jpeg", "image/png"];

      const uploads = await Promise.all(files.map(async ({contentType}) => {
        if (!allowedTypes.includes(contentType)) {
          throw new
          HttpsError("invalid-argument", `Unsupported type: ${contentType}`);
        }
        const ext = contentType.split("/")[1];
        const key = `products/${uid}/${Date.now()}-${randomUUID()}.${ext}`;
        const command = new PutObjectCommand({
          Bucket: B2_BUCKET, Key: key, ContentType: contentType,
        });
        const uploadUrl = await getSignedUrl(b2, command, {expiresIn: 300});
        return {key, uploadUrl, contentType};
      }));

      return {uploads};
    },
);

// --- createProduct ---
exports.createProduct = onCall(
    {region: "us-central1", secrets: [b2KeyId, b2AppKey]},
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

      const {
        name, description, price, category, tags, sellerName,
        imageKeys, isDelivery, location, contact,
      } = request.data;

      if (!name || !price || !category ||
        !VALID_CATEGORIES.includes(category)) {
        throw new
        HttpsError("invalid-argument", "Missing or invalid product fields.");
      }
      if (!Array.isArray(imageKeys) || imageKeys.length < 1 ||
      imageKeys.length > 5) {
        throw new HttpsError("invalid-argument", "Provide 1-5 image keys.");
      }

      // stays predictable and a seller can't spam hundreds of tags.
      const normalizedTags = Array.isArray(tags) ?
        [...new Set(
            tags
                .filter((t) => typeof t === "string" && t.trim().length > 0)
                .map((t) => t.trim().toLowerCase())
                .slice(0, 15),
        )] :
        [];

      const b2 = getB2Client();
      const thumbnailKey = `thumbnails/${uid}/${Date.now()}.webp`;

      try {
        const original = await b2.send(new GetObjectCommand({
          Bucket: B2_BUCKET, Key: imageKeys[0],
        }));
        const buffer = Buffer.from(await original.Body.transformToByteArray());
        const thumbnail = await sharp(buffer)
            .resize(400, 400, {fit: "cover"})
            .webp({quality: 75})
            .toBuffer();

        await b2.send(new PutObjectCommand({
          Bucket: B2_BUCKET, Key: thumbnailKey,
          Body: thumbnail, ContentType: "image/webp",
        }));
      } catch (err) {
        console.error("Thumbnail generation failed:", err);
        throw new HttpsError("internal", "Could not process product images.");
      }

      const productRef = db.collection("products").doc();
      await productRef.set({
        productId: productRef.id,
        sellerId: uid,
        sellerName: sellerName,
        name,
        description: description || "",
        price,
        currency: "GHS",
        category,
        tags: normalizedTags,
        images: imageKeys.map((key) => `${SHOP_CDN_BASE_URL}/${key}`),
        thumbnailUrl: `${SHOP_CDN_BASE_URL}/${thumbnailKey}`,
        status: "pending",
        contact,
        isDelivery: isDelivery || false,
        location: location || null,
        viewCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        productId: productRef.id,
        thumbnailUrl: `${SHOP_CDN_BASE_URL}/${thumbnailKey}`,
      };
    },
);

/**
 * Strips the CDN base URL off a stored image/thumbnail URL to recover
 * the underlying B2 object key.
 * @param {string} url Full CDN URL, e.g. `${SHOP_CDN_BASE_URL}/products/...`
 * @return {string} The B2 object key.
 */
function keyFromCdnUrl(url) {
  return url.replace(`${SHOP_CDN_BASE_URL}/`, "");
}

// --- deleteProduct ---
exports.deleteProduct = onCall(
    {region: "us-central1", secrets: [b2KeyId, b2AppKey]},
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

      const {productId} = request.data;
      if (!productId || typeof productId !== "string") {
        throw new HttpsError("invalid-argument", "Missing productId.");
      }

      const productRef = db.collection("products").doc(productId);
      const snap = await productRef.get();
      if (!snap.exists) {
        throw new HttpsError("not-found", "Listing not found.");
      }

      const product = snap.data();
      if (product.sellerId !== uid) {
        throw new
        HttpsError("permision-denied", "You can only delete your own listings");
      }

      const keysToDelete = [
        ...(product.images || []).map(keyFromCdnUrl),
        ...(product.thumbnailUrl ? [keyFromCdnUrl(product.thumbnailUrl)] : []),
      ];

      if (keysToDelete.length > 0) {
        const b2 = getB2Client();
        try {
          await b2.send(new DeleteObjectsCommand({
            Bucket: B2_BUCKET,
            Delete: {Objects: keysToDelete.map((Key) => ({Key}))},
          }));
        } catch (err) {
          // Log but don't block the Firestore delete on a storage hiccup —
          // an orphaned B2 object is recoverable, a listing stuck in
          // Firestore forever is a worse user-facing failure.
          console.error("Failed to delete B2 objects for", productId, err);
        }
      }

      await productRef.delete();

      return {success: true};
    },
);

// --- updateProduct ---
exports.updateProduct = onCall(
    {region: "us-central1", secrets: [b2KeyId, b2AppKey]},
    async (request) => {
      const uid = request.auth && request.auth.uid;
      if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

      const {
        productId, name, description, price, category, tags,
        images, newImageKeys, isDelivery, location, contact,
      } = request.data;

      if (!productId || typeof productId !== "string") {
        throw new HttpsError("invalid-argument", "Missing productId.");
      }
      if (!name || !price || !category ||
        !VALID_CATEGORIES.includes(category)) {
        throw new
        HttpsError("invalid-argument", "Missing or invalid product fields.");
      }

      const productRef = db.collection("products").doc(productId);
      const snap = await productRef.get();
      if (!snap.exists) {
        throw new HttpsError("not-found", "Listing not found.");
      }

      const existing = snap.data();
      if (existing.sellerId !== uid) {
        throw new
        HttpsError("permission-denied", "You can only edit your own listings.");
      }

      const keptImages = Array.isArray(images) ? images : [];
      const newKeys = Array.isArray(newImageKeys) ? newImageKeys : [];
      const finalImages = [
        ...keptImages,
        ...newKeys.map((key) => `${SHOP_CDN_BASE_URL}/${key}`),
      ];

      if (finalImages.length < 1 || finalImages.length > 5) {
        throw new HttpsError("invalid-argument", "Provide 1-5 images.");
      }

      const normalizedTags = Array.isArray(tags) ?
        [...new Set(
            tags
                .filter((t) => typeof t === "string" && t.trim().length > 0)
                .map((t) => t.trim().toLowerCase())
                .slice(0, 15),
        )] :
        [];

      // Images that were on the product before but aren't in the kept list
      // anymore — safe to delete from B2.
      const removedImageKeys = (existing.images || [])
          .filter((url) => !keptImages.includes(url))
          .map(keyFromCdnUrl);

      const b2 = getB2Client();

      // Regenerate the thumbnail only if the first image actually changed —
      // avoids a pointless resize/upload on edits that don't touch photos.
      let thumbnailUrl = existing.thumbnailUrl;
      if (finalImages[0] !== existing.images?.[0]) {
        const firstKey = keyFromCdnUrl(finalImages[0]);
        const newThumbnailKey = `thumbnails/${uid}/${Date.now()}.webp`;

        try {
          const original = await b2.send(new GetObjectCommand({
            Bucket: B2_BUCKET, Key: firstKey,
          }));
          const buffer =
            Buffer.from(await original.Body.transformToByteArray());
          const thumbnail = await sharp(buffer)
              .resize(400, 400, {fit: "cover"})
              .webp({quality: 75})
              .toBuffer();

          await b2.send(new PutObjectCommand({
            Bucket: B2_BUCKET, Key: newThumbnailKey,
            Body: thumbnail, ContentType: "image/webp",
          }));

          if (existing.thumbnailUrl) {
            const oldThumbnailKey = keyFromCdnUrl(existing.thumbnailUrl);
            b2.send(new DeleteObjectCommand({
              Bucket: B2_BUCKET, Key: oldThumbnailKey,
            })).catch((err) =>
              console.error("Failed to delete old thumbnail:", err));
          }

          thumbnailUrl = `${SHOP_CDN_BASE_URL}/${newThumbnailKey}`;
        } catch (err) {
          console.error("Thumbnail regeneration failed:", err);
          throw new HttpsError("internal", "Could not process product images.");
        }
      }

      if (removedImageKeys.length > 0) {
        b2.send(new DeleteObjectsCommand({
          Bucket: B2_BUCKET,
          Delete: {Objects: removedImageKeys.map((Key) => ({Key}))},
        })).catch((err) =>
          console.error("Failed to delete removed B2 images:", err));
      }

      await productRef.update({
        name,
        description: description || "",
        price,
        category,
        tags: normalizedTags,
        images: finalImages,
        thumbnailUrl,
        contact: contact || "",
        isDelivery: isDelivery || false,
        location: location || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {productId, thumbnailUrl};
    },
);
