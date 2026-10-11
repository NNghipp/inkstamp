import { randomUUID } from "node:crypto";
import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { enforceAppCheck } from "../../config/callable-security.js";
import { maxDailyStamps, region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { friendshipId } from "../../shared/firestore/ids.js";
import { consumeDailyQuota } from "../../shared/rate-limit/rate-limit.js";
import { publishStampSchema } from "../../shared/validation/schemas.js";
import { sendStampNotifications } from "../notifications/send-notifications.js";
import { resolveAudience } from "./audience-resolver.js";

export const publishStamp = onCall(
  { region, enforceAppCheck, timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    try {
      const senderId = await requireAuth(request);
      const input = publishStampSchema.parse(request.data);
      const requestReference = firestore.doc(`users/${senderId}/publishRequests/${input.requestId}`);
      // Retry after revocation must never re-deliver content.
      const previous = await requestReference.get();
      if (previous.exists) return { stampId: previous.get("stampId") as string, duplicate: true };
      if (!input.cloudinaryPublicId.startsWith(`inkstamp/${senderId}/stamp/`) ||
          !input.cloudinaryThumbnailPublicId.startsWith(`inkstamp/${senderId}/thumbnail/`)) {
        throw new HttpsError("invalid-argument", "Media must belong to the sender.");
      }
      await consumeDailyQuota(senderId, "stamps", maxDailyStamps, input.requestId);
      const recipientIds = await resolveAudience(senderId, input);
      const profile = await firestore.doc(`users/${senderId}`).get();
      const senderName = (profile.get("displayName") as string | undefined) ?? "Bạn bè";
      const stampId = randomUUID();
      const stampReference = firestore.doc(`stamps/${stampId}`);
      const result = await firestore.runTransaction(async (transaction) => {
        const prior = await transaction.get(requestReference);
        if (prior.exists) return { stampId: prior.get("stampId") as string, duplicate: true };
        // Lock accepted friendship versions to prevent concurrent block races.
        const relationships = await transaction.getAll(...recipientIds.map((id) =>
          firestore.doc(`friendships/${friendshipId(senderId, id)}`)));
        if (relationships.some((doc) => doc.get("status") !== "accepted")) {
          throw new HttpsError("permission-denied", "Every recipient must be an accepted friend.");
        }
        const media = {
          senderId, senderName,
          cloudinaryPublicId: input.cloudinaryPublicId,
          cloudinaryThumbnailPublicId: input.cloudinaryThumbnailPublicId,
          frameStyle: input.frameStyle, paperTone: input.paperTone,
          replyToStampId: input.replyToStampId ?? null,
          createdAt: FieldValue.serverTimestamp(),
        };
        transaction.create(stampReference, {
          ...media, audience: input.audience, recipientIds,
          recipientCount: recipientIds.length, status: "active",
          captureLocalDate: input.captureLocalDate,
          timezoneOffsetMinutes: input.timezoneOffsetMinutes,
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.create(requestReference, { stampId, createdAt: FieldValue.serverTimestamp() });
        for (const id of recipientIds) {
          transaction.create(firestore.doc(`users/${id}/deliveries/${stampId}`), {
            ...media, stampId, status: "available", isSeen: false, reaction: null,
          });
        }
        return { stampId, duplicate: false };
      });
      if (!result.duplicate) {
        try {
          await sendStampNotifications(recipientIds, result.stampId, senderName);
        } catch {
          // Never delete an already committed stamp when push fails.
          logger.warn("Stamp committed; notification unavailable", { stampId: result.stampId });
        }
      }
      return result;
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
