import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore, storage } from "../../shared/firebase/admin.js";
import { stampIdSchema } from "../../shared/validation/schemas.js";

export const deleteStampForEveryone = onCall(
  { region, enforceAppCheck: true, timeoutSeconds: 120 },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = stampIdSchema.parse(request.data);
      const stampReference = firestore.doc(`stamps/${input.stampId}`);
      const stamp = await stampReference.get();
      if (!stamp.exists) {
        return { deleted: true };
      }
      if (stamp.get("senderId") !== userId) {
        throw new HttpsError(
          "permission-denied",
          "Only the sender can delete this stamp.",
        );
      }

      const recipientIds =
        (stamp.get("recipientIds") as string[] | undefined) ?? [];
      const batch = firestore.batch();
      for (const recipientId of recipientIds) {
        batch.delete(
          firestore.doc(`users/${recipientId}/deliveries/${input.stampId}`),
        );
      }
      batch.update(stampReference, {
        status: "deleted",
        recipientIds: [],
        recipientCount: 0,
        deletedAt: FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await storage
        .bucket()
        .deleteFiles({ prefix: `stamps/${userId}/${input.stampId}/` });

      return { deleted: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const removeDelivery = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
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
