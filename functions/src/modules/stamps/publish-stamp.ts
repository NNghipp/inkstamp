import { randomUUID } from "node:crypto";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  maxDailyStamps,
  maxStampBytes,
  region,
} from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore, storage } from "../../shared/firebase/admin.js";
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

      const bucket = storage.bucket();
      const draftImagePath = `drafts/${senderId}/${input.draftId}/stamp.jpg`;
      const draftThumbnailPath =
        `drafts/${senderId}/${input.draftId}/thumbnail.jpg`;
      const draftImage = bucket.file(draftImagePath);
      const draftThumbnail = bucket.file(draftThumbnailPath);
      const [[imageExists], [thumbnailExists]] = await Promise.all([
        draftImage.exists(),
        draftThumbnail.exists(),
      ]);
      if (!imageExists || !thumbnailExists) {
        throw new HttpsError("not-found", "Stamp draft media was not found.");
      }

      const [metadata] = await draftImage.getMetadata();
      const size = Number(metadata.size ?? 0);
      if (metadata.contentType !== "image/jpeg" || size > maxStampBytes) {
        throw new HttpsError(
          "invalid-argument",
          "Stamp media must be a JPEG smaller than 5 MB.",
        );
      }

      const stampId = randomUUID();
      const stampReference = firestore.doc(`stamps/${stampId}`);
      const senderProfile = await firestore.doc(`users/${senderId}`).get();
      const senderName =
        (senderProfile.get("displayName") as string | undefined) ?? "Bạn bè";
      const finalImagePath = `stamps/${senderId}/${stampId}/stamp.jpg`;
      const finalThumbnailPath =
        `stamps/${senderId}/${stampId}/thumbnail.jpg`;

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
          imagePath: finalImagePath,
          thumbnailPath: finalThumbnailPath,
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
        await Promise.all([
          draftImage.copy(bucket.file(finalImagePath)),
          draftThumbnail.copy(bucket.file(finalThumbnailPath)),
        ]);

        const batch = firestore.batch();
        for (const recipientId of recipientIds) {
          batch.create(
            firestore.doc(`users/${recipientId}/deliveries/${stampId}`),
            {
              stampId,
              senderId,
              senderName,
              imagePath: finalImagePath,
              thumbnailPath: finalThumbnailPath,
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
        await Promise.allSettled([
          draftImage.delete({ ignoreNotFound: true }),
          draftThumbnail.delete({ ignoreNotFound: true }),
          sendStampNotifications(recipientIds, stampId, senderName),
        ]);
      } catch (error) {
        await Promise.allSettled([
          stampReference.delete(),
          requestReference.delete(),
          bucket.deleteFiles({ prefix: `stamps/${senderId}/${stampId}/` }),
        ]);
        throw error;
      }

      return { stampId, duplicate: false };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
