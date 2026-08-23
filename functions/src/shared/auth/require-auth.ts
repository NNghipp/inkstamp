import type { CallableRequest } from "firebase-functions/v2/https";
import { HttpsError } from "firebase-functions/v2/https";

export function requireAuth(request: CallableRequest<unknown>): string {
  if (request.auth === undefined) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to use this operation.",
    );
  }
  return request.auth.uid;
}
