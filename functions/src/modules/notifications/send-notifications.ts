import { logger } from "firebase-functions";
import { firestore, messaging } from "../../shared/firebase/admin.js";

export async function sendStampNotifications(
  recipientIds: string[],
  stampId: string,
  senderName: string,
): Promise<void> {
  const tokenSnapshots = await Promise.all(
    recipientIds.map((recipientId) =>
      firestore.collection(`users/${recipientId}/devices`).get(),
    ),
  );
  const tokens = tokenSnapshots.flatMap((snapshot) =>
    snapshot.docs
      .map((document) => document.get("token") as string | undefined)
      .filter((token): token is string => token !== undefined),
  );
  if (tokens.length === 0) {
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: "Inkstamp",
      body: `${senderName} sent a new stamp`,
    },
    data: {
      type: "new_stamp",
      stampId,
      deepLink: `inkstamp://stamp/${stampId}`,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "new_stamps",
      },
    },
    apns: {
      payload: {
        aps: {
          category: "NEW_STAMP",
          mutableContent: true,
        },
      },
    },
  });

  if (response.failureCount > 0) {
    logger.warn("Some stamp notifications failed", {
      stampId,
      failureCount: response.failureCount,
    });
  }
}

export async function sendReactionNotification(
  recipientId: string,
  stampId: string,
  emoji: string,
): Promise<void> {
  const devices = await firestore
    .collection(`users/${recipientId}/devices`)
    .get();
  const tokens = devices.docs
    .map((document) => document.get("token") as string | undefined)
    .filter((token): token is string => token !== undefined);
  if (tokens.length === 0) {
    return;
  }
  await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: "Inkstamp",
      body: `Your stamp received ${emoji}`,
    },
    data: {
      type: "stamp_reaction",
      stampId,
      deepLink: `inkstamp://calendar/stamp/${stampId}`,
    },
  });
}
