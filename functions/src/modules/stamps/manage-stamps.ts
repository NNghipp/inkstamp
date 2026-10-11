import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { stampIdSchema } from "../../shared/validation/schemas.js";
import { revokeMedia } from "./revoke-media.js";

export const deleteStampForEveryone = onCall(
  { region, enforceAppCheck, timeoutSeconds: 120 },
  async (request) => {
    try {
      const userId = await requireAuth(request);
      const input = stampIdSchema.parse(request.data);
      const stampReference = firestore.doc(`stamps/${input.stampId}`);
      const mediaIds = await firestore.runTransaction(async (transaction) => {
        const stamp = await transaction.get(stampReference);
        if (!stamp.exists) throw new HttpsError("not-found", "Stamp not found.");
        if (stamp.get("senderId") !== userId) {
          throw new HttpsError("permission-denied", "Only the sender can revoke this stamp.");
        }
        const media = [stamp.get("cloudinaryPublicId"), stamp.get("cloudinaryThumbnailPublicId")]
          .filter((id): id is string => typeof id === "string");
        if (stamp.get("status") === "revoked" || stamp.get("status") === "deleted") return media;
        const ids = (stamp.get("recipientIds") as string[] | undefined) ?? [];
        const references = ids.map((id) => firestore.doc(`users/${id}/deliveries/${input.stampId}`));
        const deliveries = references.length ? await transaction.getAll(...references) : [];
        for (const delivery of deliveries) {
          if (delivery.exists) transaction.update(delivery.ref, {
            status: "revoked", revokedAt: FieldValue.serverTimestamp(),
          });
        }
        transaction.update(stampReference, {
          status: "revoked", revokedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
        return media;
      });

      const mediaDeleted = await revokeMedia(request, mediaIds);
      return { deleted: true, revoked: true, mediaDeleted };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const removeDelivery = onCall(
  { region, enforceAppCheck },
  async (request) => {
    try {
      const userId = await requireAuth(request);
      const input = stampIdSchema.parse(request.data);
      await firestore
        .doc(`users/${userId}/deliveries/${input.stampId}`)
        .delete();
      return { removed: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
import { enforceAppCheck } from "../../config/callable-security.js";
