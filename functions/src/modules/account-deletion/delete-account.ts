import { FieldValue } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { auth, firestore, storage } from "../../shared/firebase/admin.js";

export const deleteAccount = onCall(
  {
    region,
    enforceAppCheck: true,
    timeoutSeconds: 540,
    memory: "1GiB",
  },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const userReference = firestore.doc(`users/${userId}`);
      const user = await userReference.get();
      const username = user.get("username") as string | undefined;

      await userReference.set(
        {
          status: "deleting",
          deletionRequestedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      const sentStamps = await firestore
        .collection("stamps")
        .where("senderId", "==", userId)
        .get();
      for (const stamp of sentStamps.docs) {
        const recipientIds =
          (stamp.get("recipientIds") as string[] | undefined) ?? [];
        const batch = firestore.batch();
        for (const recipientId of recipientIds) {
          batch.delete(
            firestore.doc(`users/${recipientId}/deliveries/${stamp.id}`),
          );
        }
        batch.delete(stamp.ref);
        await batch.commit();
      }

      const friendships = await firestore
        .collection("friendships")
        .where("members", "array-contains", userId)
        .get();
      const friendshipBatch = firestore.batch();
      for (const friendship of friendships.docs) {
        friendshipBatch.delete(friendship.ref);
      }
      await friendshipBatch.commit();

      await Promise.all([
        firestore.recursiveDelete(userReference),
        username === undefined
          ? Promise.resolve()
          : firestore.doc(`usernames/${username}`).delete(),
        storage.bucket().deleteFiles({ prefix: `stamps/${userId}/` }),
        storage.bucket().deleteFiles({ prefix: `drafts/${userId}/` }),
      ]);
      await auth.deleteUser(userId);

      return { deleted: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
