const functions = require("firebase-functions");
const {onDocumentCreated, onDocumentWritten} =
require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const {fal} = require("@fal-ai/client");
const {geohashQueryBounds, distanceBetween, geohashForLocation} =
require("geofire-common");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();


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
    maxDistanceKm = 20,
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
      let q = db.collection("services")
          .where("status", "==", "approved");

      if (region && region.trim() !== "") {
        q = q.where("region", "==", region);
        if (district && district.trim() !== "") {
          q = q.where("district", "==", district);
        }
      }

      q = q.orderBy("geohash").startAt(start).endAt(end);
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

  const queryLower = query.toLowerCase().trim();
  const queryTokens = queryLower.split(/\s+/).filter(Boolean);
  const seen = new Set();
  const allResults = [];

  for (const snapshot of snapshots) {
    snapshot.forEach((doc) => {
      if (seen.has(doc.id)) return; // overlapping geohash bounds return dupes
      seen.add(doc.id);

      const provider = doc.data();
      if (provider.latitude == null || provider.longitude == null) return;

      // The geohash box is a square; trim it down to an actual circle.
      const distanceKm =
      distanceBetween(center, [provider.latitude, provider.longitude]);
      if (distanceKm > maxDistanceKm) return;

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

/**
 * Searches approved providers of a specific category within a radius of
 * the user's location. Same geohash-bounded approach as searchProviders.
 */
exports.searchByCategory = onCall(async (request) => {
  const {
    category,
    userLat,
    userLng,
    maxDistanceKm = 20,
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


// virtual tryon call function
const FAL_API_KEY = defineSecret("FAL_API_KEY");

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
