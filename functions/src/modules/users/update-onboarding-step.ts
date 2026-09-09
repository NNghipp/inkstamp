import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { onboardingStepSchema } from "../../shared/validation/schemas.js";

export const updateOnboardingStep = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const { step } = onboardingStepSchema.parse(request.data);
      const userReference = firestore.doc(`users/${userId}`);
      const snapshot = await userReference.get();
      if (!snapshot.exists || !snapshot.get("username")) {
        throw new HttpsError("failed-precondition", "Complete your profile first.");
      }
      await userReference.set({
        onboardingStep: step,
        onboardingComplete: step === "complete",
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return { step };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
