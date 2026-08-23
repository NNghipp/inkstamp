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
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const reporterId = requireAuth(request);
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
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = userIdSchema.parse(request.data);
      if (input.userId === userId) {
        throw new HttpsError(
          "invalid-argument",
          "You cannot block yourself.",
        );
      }
      const pairId = friendshipId(userId, input.userId);
      const batch = firestore.batch();
      batch.set(firestore.doc(`friendships/${pairId}`), {
        members: [userId, input.userId].sort(),
        status: "blocked",
        blockedBy: userId,
        updatedAt: FieldValue.serverTimestamp(),
      });
      batch.delete(
        firestore.doc(`users/${userId}/closeFriends/${input.userId}`),
      );
      batch.delete(
        firestore.doc(`users/${input.userId}/closeFriends/${userId}`),
      );
      await batch.commit();

      await revokeDeliveries(userId, input.userId);
      await revokeDeliveries(input.userId, userId);
      return { blocked: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const unblockUser = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = userIdSchema.parse(request.data);
      const reference = firestore.doc(
        `friendships/${friendshipId(userId, input.userId)}`,
      );
      const snapshot = await reference.get();
      if (
        snapshot.exists &&
        snapshot.get("status") === "blocked" &&
        snapshot.get("blockedBy") === userId
      ) {
        await reference.delete();
      }
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
