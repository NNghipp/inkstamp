import { HttpsError } from "firebase-functions/v2/https";
import { ZodError } from "zod";

export function toHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) {
    return error;
  }
  if (error instanceof ZodError) {
    return new HttpsError(
      "invalid-argument",
      "The request payload is invalid.",
      error.flatten(),
    );
  }
  if (error instanceof Error) {
    return new HttpsError("internal", error.message);
  }
  return new HttpsError("internal", "An unexpected error occurred.");
}
