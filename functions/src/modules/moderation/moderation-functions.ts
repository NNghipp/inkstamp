import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  maxDailyReports,
  region,
} from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { friendshipId } from "../../shared/firestore/ids.js";
import { consumeDailyQuota } from "../../shared/rate-limit/rate-limit.js";
import {
  reportContentSchema,
  userIdSchema,
} from "../../shared/validation/schemas.js";

export const reportContent = onCall(
  { region, enforceAppCheck },
  async (request) => {
    try {
      const reporterId = await requireAuth(request);
      const input = reportContentSchema.parse(request.data);
      await consumeDailyQuota(reporterId, "reports", maxDailyReports);
      const delivery = await firestore
        .doc(`users/${reporterId}/deliveries/${input.stampId}`)
        .get();
      if (!delivery.exists) {
        throw new HttpsError(
          "permission-denied",
          "You can only report a stamp delivered to you.",
        );
      }
      const reportedUserId = delivery.get("senderId") as string;
      const thumbnailPath = delivery.get("thumbnailPath") as string;
      const reportReference = firestore.collection("reports").doc();
      await reportReference.set({
        reporterId,
        reportedUserId,
        stampId: input.stampId,
        reason: input.reason,
        details: input.details ?? null,
        thumbnailPath,
        status: "open",
        createdAt: FieldValue.serverTimestamp(),
      });
      return { reportId: reportReference.id };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const blockUser = onCall(
  { region, enforceAppCheck },
  async (request) => {
    try {
      const userId = await requireAuth(request);
      const input = userIdSchema.parse(request.data);
      if (input.userId === userId) {
        throw new HttpsError(
          "invalid-argument",
          "You cannot block yourself.",
        );
      }
      const pairId = friendshipId(userId, input.userId);
      const [userProfile, targetProfile] = await Promise.all([
        firestore.doc(`users/${userId}`).get(),
        firestore.doc(`users/${input.userId}`).get(),
      ]);
      await firestore.runTransaction(async (transaction) => {
        const reference = firestore.doc(`friendships/${pairId}`);
        const current = await transaction.get(reference);
        if (current.get("status") === "blocked" && current.get("blockedBy") !== userId) {
          throw new HttpsError("permission-denied", "This connection is already unavailable.");
        }
        transaction.set(
        reference,
        {
          members: [userId, input.userId].sort(),
          status: "blocked",
          blockedBy: userId,
          memberProfiles: {
            [userId]: {
              username: userProfile.get("username") as string,
              displayName: userProfile.get("displayName") as string,
            },
            [input.userId]: {
              username: targetProfile.get("username") as string,
              displayName: targetProfile.get("displayName") as string,
            },
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      transaction.delete(
        firestore.doc(`users/${userId}/closeFriends/${input.userId}`),
      );
      transaction.delete(
        firestore.doc(`users/${input.userId}/closeFriends/${userId}`),
      );
      });

      await revokeDeliveries(userId, input.userId);
      await revokeDeliveries(input.userId, userId);
      return { blocked: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const unblockUser = onCall(
  { region, enforceAppCheck },
  async (request) => {
    try {
      const userId = await requireAuth(request);
      const input = userIdSchema.parse(request.data);
      const reference = firestore.doc(
        `friendships/${friendshipId(userId, input.userId)}`,
      );
      await firestore.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        if (snapshot.exists && snapshot.get("status") === "blocked" &&
            snapshot.get("blockedBy") === userId) transaction.delete(reference);
      });
      return { unblocked: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

async function revokeDeliveries(
  recipientId: string,
  senderId: string,
): Promise<void> {
  while (true) {
    const deliveries = await firestore
      .collection(`users/${recipientId}/deliveries`)
      .where("senderId", "==", senderId)
      .where("status", "==", "available")
      .limit(200)
      .get();
    if (deliveries.empty) {
      return;
    }
    const batch = firestore.batch();
    for (const delivery of deliveries.docs) {
      batch.update(delivery.ref, {
        status: "revoked",
        revokedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
import { enforceAppCheck } from "../../config/callable-security.js";
