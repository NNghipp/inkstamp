import { onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { normalizeUsername } from "../../shared/firestore/ids.js";
import { usernameLookupSchema } from "../../shared/validation/schemas.js";

export const checkUsernameAvailability = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = usernameLookupSchema.parse(request.data);
      const username = normalizeUsername(input.username);
      const snapshot = await firestore.doc(`usernames/${username}`).get();
      return {
        available: !snapshot.exists || snapshot.get("userId") === userId,
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
