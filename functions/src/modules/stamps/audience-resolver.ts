import { HttpsError } from "firebase-functions/v2/https";
import { maxFriends } from "../../config/runtime.js";
import { firestore } from "../../shared/firebase/admin.js";
import { friendshipId } from "../../shared/firestore/ids.js";

export type AudienceMode = "allFriends" | "closeFriends" | "selected";

export interface AudienceInput {
  audience: AudienceMode;
  selectedRecipientIds: string[];
  replyToStampId?: string;
}

export async function resolveAudience(
  senderId: string,
  input: AudienceInput,
): Promise<string[]> {
  if (input.replyToStampId !== undefined) {
    const original = await firestore.doc(`stamps/${input.replyToStampId}`).get();
    if (!original.exists) {
      throw new HttpsError("not-found", "The original stamp was not found.");
    }
    const originalSenderId = original.get("senderId") as string;
    if (originalSenderId === senderId) {
      throw new HttpsError(
        "invalid-argument",
        "You cannot reply to your own stamp.",
      );
    }
    await assertAcceptedFriendship(senderId, originalSenderId);
    return [originalSenderId];
  }

  let recipientIds: string[];
  if (input.audience === "allFriends") {
    const snapshots = await firestore
      .collection("friendships")
      .where("members", "array-contains", senderId)
      .where("status", "==", "accepted")
      .get();
    recipientIds = snapshots.docs.map((snapshot) => {
      const members = snapshot.get("members") as string[];
      const recipient = members.find((member) => member !== senderId);
      if (recipient === undefined) {
        throw new HttpsError("internal", "Malformed friendship.");
      }
      return recipient;
    });
  } else if (input.audience === "closeFriends") {
    const snapshots = await firestore
      .collection(`users/${senderId}/closeFriends`)
      .get();
    recipientIds = snapshots.docs.map((snapshot) => snapshot.id);
  } else {
    recipientIds = input.selectedRecipientIds;
  }

  const uniqueRecipients = [
    ...new Set(recipientIds.filter((recipient) => recipient !== senderId)),
  ];
  if (uniqueRecipients.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "Select at least one recipient.",
    );
  }
  if (uniqueRecipients.length > maxFriends) {
    throw new HttpsError(
      "resource-exhausted",
      "Recipient limit exceeded.",
    );
  }

  await Promise.all(
    uniqueRecipients.map((recipient) =>
      assertAcceptedFriendship(senderId, recipient),
    ),
  );
  return uniqueRecipients;
}

async function assertAcceptedFriendship(
  firstUserId: string,
  secondUserId: string,
): Promise<void> {
  const snapshot = await firestore
    .doc(`friendships/${friendshipId(firstUserId, secondUserId)}`)
    .get();
  if (!snapshot.exists || snapshot.get("status") !== "accepted") {
    throw new HttpsError(
      "permission-denied",
      "Every recipient must be an accepted friend.",
    );
  }
}
