import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { normalizeUsername } from "../../shared/firestore/ids.js";
import { reserveUsernameSchema } from "../../shared/validation/schemas.js";

export const reserveUsername = onCall(
  {
    region,
    enforceAppCheck: true,
  },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = reserveUsernameSchema.parse(request.data);
      const username = normalizeUsername(input.username);
      const usernameReference = firestore.doc(`usernames/${username}`);
      const userReference = firestore.doc(`users/${userId}`);

      await firestore.runTransaction(async (transaction) => {
        const [usernameSnapshot, userSnapshot] = await Promise.all([
          transaction.get(usernameReference),
          transaction.get(userReference),
        ]);

        if (
          usernameSnapshot.exists &&
          usernameSnapshot.get("userId") !== userId
        ) {
          throw new HttpsError(
            "already-exists",
            "This username is already in use.",
          );
        }

        const previousUsername = userSnapshot.get("username") as
          | string
          | undefined;
        if (previousUsername !== undefined && previousUsername !== username) {
          transaction.delete(firestore.doc(`usernames/${previousUsername}`));
        }
        const previousCreatedAt = userSnapshot.get("createdAt") as unknown;

        transaction.set(usernameReference, {
          userId,
          createdAt: FieldValue.serverTimestamp(),
        });
        transaction.set(
          userReference,
          {
            username,
            displayName: input.displayName,
            usernameNormalized: username,
            onboardingComplete: false,
            updatedAt: FieldValue.serverTimestamp(),
            createdAt: previousCreatedAt ?? FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      return { username };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
