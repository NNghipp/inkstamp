import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";
import { auth } from "../firebase/admin.js";

export async function requireAuth(request: CallableRequest<unknown>): Promise<string> {
  if (request.auth === undefined) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to use this operation.",
    );
  }
  if (process.env.FUNCTIONS_EMULATOR === "true") {
    if (process.env.GCLOUD_PROJECT !== "inkstamp-dev" ||
        process.env.FIREBASE_AUTH_EMULATOR_HOST) {
      throw new HttpsError("unauthenticated", "Real DEV authentication is required.");
    }
    const token = request.rawRequest.header("Authorization")?.match(/^Bearer\s+(\S+)$/i)?.[1];
    if (!token) throw new HttpsError("unauthenticated", "Authentication is required.");
    try {
      const verified = await auth.verifyIdToken(token, true);
      if (verified.uid !== request.auth.uid) throw new Error("Identity mismatch");
      return verified.uid;
    } catch {
      throw new HttpsError("unauthenticated", "Invalid authentication.");
    }
  }
  return request.auth.uid;
}
