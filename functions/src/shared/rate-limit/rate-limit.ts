import { FieldValue } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { firestore } from "../firebase/admin.js";
import { utcDayKey } from "../firestore/ids.js";

export async function consumeDailyQuota(
  userId: string,
  action: string,
  limit: number,
  idempotencyKey?: string,
): Promise<void> {
  const reference = firestore.doc(
    `users/${userId}/dailyQuotas/${utcDayKey()}_${action}`,
  );

  await firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const count = snapshot.exists
      ? (snapshot.get("count") as number | undefined) ?? 0
      : 0;
    const consumedKeys = snapshot.exists
      ? (snapshot.get("consumedKeys") as string[] | undefined) ?? []
      : [];
    if (
      idempotencyKey !== undefined &&
      consumedKeys.includes(idempotencyKey)
    ) {
      return;
    }
    if (count >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        `Daily ${action} limit reached.`,
      );
    }
    transaction.set(
      reference,
      {
        action,
        count: FieldValue.increment(1),
        consumedKeys:
          idempotencyKey === undefined
            ? consumedKeys
            : [...consumedKeys, idempotencyKey],
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}
