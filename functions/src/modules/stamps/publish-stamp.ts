import { randomUUID } from "node:crypto";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  maxDailyStamps,
  region,
} from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { consumeDailyQuota } from "../../shared/rate-limit/rate-limit.js";
import { publishStampSchema } from "../../shared/validation/schemas.js";
import { sendStampNotifications } from "../notifications/send-notifications.js";
import { resolveAudience } from "./audience-resolver.js";

export const publishStamp = onCall(
  {
    region,
    enforceAppCheck: true,
    timeoutSeconds: 120,
    memory: "512MiB",
  },
  async (request) => {
    try {
      const senderId = requireAuth(request);
      const input = publishStampSchema.parse(request.data);

      const requestReference = firestore.doc(
        `users/${senderId}/publishRequests/${input.requestId}`,
      );
      const previousRequest = await requestReference.get();
      if (previousRequest.exists) {
        const previousStampId = previousRequest.get("stampId") as string;
        const previousStamp = await firestore
          .doc(`stamps/${previousStampId}`)
          .get();
        if (previousStamp.get("status") !== "active") {
          throw new HttpsError(
            "aborted",
            "A previous publish attempt is still being resolved.",
          );
        }
        return {
          stampId: previousStampId,
          duplicate: true,
        };
      }
      await consumeDailyQuota(
        senderId,
        "stamps",
        maxDailyStamps,
        input.requestId,
      );

      const recipientIds = await resolveAudience(senderId, {
        audience: input.audience,
        selectedRecipientIds: input.selectedRecipientIds,
        replyToStampId: input.replyToStampId,
      });

      const expectedStampPrefix = `inkstamp/${senderId}/stamp/`;
      const expectedThumbnailPrefix = `inkstamp/${senderId}/thumbnail/`;

      if (
        !input.cloudinaryPublicId.startsWith(expectedStampPrefix) ||
        !input.cloudinaryThumbnailPublicId.startsWith(expectedThumbnailPrefix)
      ) {
        throw new HttpsError(
          "invalid-argument",
          "The Cloudinary public IDs must belong to the sender and have the correct media type.",
        );
      }

      const stampId = randomUUID();
      const stampReference = firestore.doc(`stamps/${stampId}`);
      const senderProfile = await firestore.doc(`users/${senderId}`).get();
      const senderName =
        (senderProfile.get("displayName") as string | undefined) ?? "Bạn bè";

      const created = await firestore.runTransaction(async (transaction) => {
        const requestSnapshot = await transaction.get(requestReference);
        if (requestSnapshot.exists) {
          return {
            stampId: requestSnapshot.get("stampId") as string,
            created: false,
          };
        }
        transaction.create(stampReference, {
          senderId,
          senderName,
          audience: input.audience,
          recipientIds,
          recipientCount: recipientIds.length,
          replyToStampId: input.replyToStampId ?? null,
          frameStyle: input.frameStyle,
          paperTone: input.paperTone,
          captureLocalDate: input.captureLocalDate,
          timezoneOffsetMinutes: input.timezoneOffsetMinutes,
          cloudinaryPublicId: input.cloudinaryPublicId,
          cloudinaryThumbnailPublicId: input.cloudinaryThumbnailPublicId,
          status: "publishing",
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        transaction.create(requestReference, {
          stampId,
          createdAt: FieldValue.serverTimestamp(),
        });
        return { stampId, created: true };
      });

      if (!created.created) {
        const existingStamp = await firestore
          .doc(`stamps/${created.stampId}`)
          .get();
        if (existingStamp.get("status") !== "active") {
          throw new HttpsError(
            "aborted",
            "A previous publish attempt is still being resolved.",
          );
        }
        return { stampId: created.stampId, duplicate: true };
      }

      try {
        const batch = firestore.batch();
        for (const recipientId of recipientIds) {
          batch.create(
            firestore.doc(`users/${recipientId}/deliveries/${stampId}`),
            {
              stampId,
              senderId,
              senderName,
              cloudinaryPublicId: input.cloudinaryPublicId,
              cloudinaryThumbnailPublicId: input.cloudinaryThumbnailPublicId,
              frameStyle: input.frameStyle,
              paperTone: input.paperTone,
              replyToStampId: input.replyToStampId ?? null,
              status: "available",
              isSeen: false,
              reaction: null,
              createdAt: FieldValue.serverTimestamp(),
            },
          );
        }
        batch.update(stampReference, {
          status: "active",
          updatedAt: FieldValue.serverTimestamp(),
        });
        await batch.commit();
        await sendStampNotifications(recipientIds, stampId, senderName);
      } catch (error) {
        await Promise.allSettled([
          stampReference.delete(),
          requestReference.delete(),
        ]);
        throw error;
      }

      return { stampId, duplicate: false };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
