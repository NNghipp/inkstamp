import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { region } from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import { reactToStampSchema } from "../../shared/validation/schemas.js";
import { sendReactionNotification } from "../notifications/send-notifications.js";

const reactionEmoji: Record<string, string> = {
  heart: "❤️",
  laugh: "😂",
  wow: "😮",
  emotional: "🥹",
  fire: "🔥",
  cry: "😭",
};

export const reactToStamp = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = reactToStampSchema.parse(request.data);
      const deliveryReference = firestore.doc(
        `users/${userId}/deliveries/${input.stampId}`,
      );
      const delivery = await deliveryReference.get();
      if (!delivery.exists || delivery.get("status") !== "available") {
        throw new HttpsError(
          "permission-denied",
          "You cannot react to this stamp.",
        );
      }
      await deliveryReference.update({
        reaction: input.reaction,
        reactedAt: FieldValue.serverTimestamp(),
      });
      const senderId = delivery.get("senderId") as string;
      await sendReactionNotification(
        senderId,
        input.stampId,
        reactionEmoji[input.reaction] ?? "❤️",
      );
      return { reaction: input.reaction };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
