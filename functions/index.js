const functions = require("firebase-functions");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onCall} = require("firebase-functions/v2/https");
const crypto = require("crypto");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();


// This function sends a notification to a specific
// device using its FCM token.
// It expects a POST request with JSON body:
// { "token": "device_token", "title": "Hello", "body": "World" }
exports.sendNotification =
functions.https.onRequest(async (req, res) => {
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
    const {token, title, body} = req.body;
    if (!token || !title || !body) {
      return res.status(400).send("Missing fields");
    }

    const message = {
      notification: {title, body},
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
    const response = await admin.messaging().send(message);
    res.status(200).json({success: true, messageId: response});
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


// Simple in‑memory cache (per function instance)
// Note: This cache is not shared across
// instances, but helps for repeated calls to the same instance.
const cache = new Map();
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

// Haversine distance function (same as before)
/**
 * Calculates the distance between two geographic
 * coordinates using the Haversine formula.
 * @param {number} lat1 - Latitude of the first point in degrees.
 * @param {number} lon1 - Longitude of the first point in degrees.
 * @param {number} lat2 - Latitude of the second point in degrees.
 * @param {number} lon2 - Longitude of the second point in degrees.
 * @return {number} Distance in kilometers.
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
    Math.cos(lat2 * (Math.PI / 180)) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Generate a cache key from all search parameters
/**
 * Generates an MD5 hash key from the provided parameters object for caching.
 * @param {Object} params - The parameters to hash.
 * @return {string} A hex string representing the hash.
 */
function generateCacheKey(params) {
  const hash = crypto.createHash("md5");
  hash.update(JSON.stringify(params));
  return hash.digest("hex");
}

exports.searchProviders = onCall(async (request) => {
  const {
    query = "",
    region,
    district,
    userLat,
    userLng,
    maxDistanceKm = 20,
    sortBy = "distance",
    page = 1, // default page 1
    pageSize = 20, // default page size
  } = request.data;

  if (userLat == null || userLng == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "User location is required.",
    );
  }

  // Validate pagination parameters
  const validPage = Math.max(1, page);
  const validPageSize = Math.min(50, Math.max(1, pageSize));
  // limit to 50

  // Build cache key from all inputs
  const cacheKey = generateCacheKey({
    query,
    region,
    district,
    userLat,
    userLng,
    maxDistanceKm,
    sortBy,
    page: validPage,
    pageSize: validPageSize,
  });

  // Check cache
  const cached = cache.get(cacheKey);
  if (cached && (Date.now() - cached.timestamp) < CACHE_TTL_MS) {
    console.log("Cache hit");
    return cached.data;
  }

  console.log("Cache miss – executing query");

  // Build Firestore query
  let firestoreQuery = db.collection("services");

  firestoreQuery = firestoreQuery.where("status", "==", "approved");

  if (region !== "Ghana") {
    firestoreQuery = firestoreQuery.where("region", "==", region);
    if (district && district.trim() !== "") {
      firestoreQuery = firestoreQuery.where("district", "==", district);
    }
  }

  // Execute the query (fetch all matching documents)
  const snapshot = await firestoreQuery.get();
  const allResults = [];

  snapshot.forEach((doc) => {
    const provider = doc.data();
    const providerLat = provider.latitude;
    const providerLng = provider.longitude;

    const name = (provider.name || "").toLowerCase();
    const category = (provider.category || "").toLowerCase();
    const serviceNames = Array.isArray(provider.services) ?
    provider.services
        .map((s) => s.name)
        .filter((name) => name != null)
        .map((name) => String(name).toLowerCase()) :
          [];
    const queryLower = query.toLowerCase();

    const matchesQuery =
      query === "" ||
      name.includes(queryLower) ||
      category.includes(queryLower) ||
      serviceNames.some((s) => s.includes(queryLower));

    if (!matchesQuery) return;

    // Distance handling – include even if coordinates missing
    let distance = null;

    if (providerLat != null && providerLng != null) {
      distance = calculateDistance(
          userLat, userLng, providerLat, providerLng);
      if (distance > maxDistanceKm) return; // skip if too far
    }

    allResults.push({
      id: doc.id,
      ...provider,
      distance: distance,
      distanceText:
      distance !== null ? `${distance.toFixed(1)} km`:"Location unavailable",
    });
  });

  // Sort results – put providers without coordinates
  // at the end when sorting by distance
  if (sortBy === "distance") {
    allResults.sort((a, b) => {
      if (
        a.distance != null && b.distance != null) {
        return a.distance - b.distance;
      }
      if (a.distance == null) return 1;
      if (b.distance == null) return -1;
      return 0;
    });
  } else if (sortBy === "rating") {
    allResults.sort((a, b) => (b.rating || 0) - (a.rating || 0));
  }

  // Paginate
  const totalCount = allResults.length;
  const startIndex = (validPage - 1) * validPageSize;
  const paginatedResults =
  allResults.slice(startIndex, startIndex + validPageSize);

  const responseData = {
    providers: paginatedResults,
    totalCount,
    page: validPage,
    pageSize: validPageSize,
    hasMore: startIndex + validPageSize < totalCount,
  };

  // Store in cache
  cache.set(cacheKey, {
    timestamp: Date.now(),
    data: responseData,
  });

  return responseData;
});


exports.searchByCategory = onCall(async (request) => {
  const {
    category,
    userLat,
    userLng,
    maxDistanceKm = 20,
    sortBy = "distance",
    page = 1, // default page 1
    pageSize = 20, // default page size
  } = request.data;

  if (userLat == null || userLng == null) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "User location is required.",
    );
  }

  // Validate pagination parameters
  const validPage = Math.max(1, page);
  const validPageSize = Math.min(50, Math.max(1, pageSize));
  // limit to 50

  // Build cache key from all inputs
  const cacheKey = generateCacheKey({
    category,
    userLat,
    userLng,
    maxDistanceKm,
    sortBy,
    page: validPage,
    pageSize: validPageSize,
  });

  // Check cache
  const cached = cache.get(cacheKey);
  if (cached && (Date.now() - cached.timestamp) < CACHE_TTL_MS) {
    console.log("Cache hit");
    return cached.data;
  }

  console.log("Cache miss – executing category");

  // Build Firestore query
  let firestoreQuery = db.collection("services");

  firestoreQuery = firestoreQuery.where("category", "==", category);

  firestoreQuery = firestoreQuery.where("status", "==", "approved");


  // Execute the query (fetch all matching documents)
  const snapshot = await firestoreQuery.get();
  const allResults = [];

  snapshot.forEach((doc) => {
    const provider = doc.data();
    const providerLat = provider.latitude;
    const providerLng = provider.longitude;

    if (providerLat == null || providerLng == null) return;

    const distance =
    calculateDistance(userLat, userLng, providerLat, providerLng);
    if (distance > maxDistanceKm) return;


    allResults.push({
      id: doc.id,
      ...provider,
      distance: distance,
      distanceText: `${distance.toFixed(1)} km`,
    });
  });

  // Sort all results
  if (sortBy === "distance") {
    allResults.sort((a, b) => a.distance - b.distance);
  } else if (sortBy === "rating") {
    allResults.sort((a, b) => (b.rating || 0) - (a.rating || 0));
  }

  // Paginate
  const totalCount = allResults.length;
  const startIndex = (validPage - 1) * validPageSize;
  const paginatedResults =
  allResults.slice(startIndex, startIndex + validPageSize);

  const responseData = {
    providers: paginatedResults,
    totalCount,
    page: validPage,
    pageSize: validPageSize,
    hasMore: startIndex + validPageSize < totalCount,
  };

  // Store in cache
  cache.set(cacheKey, {
    timestamp: Date.now(),
    data: responseData,
  });

  return responseData;
});


// function to delete user account on request
exports.deleteUser = functions.https.onCall(async (context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated", "User must be authenticated");
  }
  const uid = context.auth.uid;

  const db = admin.firestore();
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
