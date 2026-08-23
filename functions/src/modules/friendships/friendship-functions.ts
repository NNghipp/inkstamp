import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import {
  maxDailyFriendRequests,
  maxFriends,
  region,
} from "../../config/runtime.js";
import { requireAuth } from "../../shared/auth/require-auth.js";
import { toHttpsError } from "../../shared/errors/to-https-error.js";
import { firestore } from "../../shared/firebase/admin.js";
import {
  friendshipId,
  normalizeUsername,
} from "../../shared/firestore/ids.js";
import { consumeDailyQuota } from "../../shared/rate-limit/rate-limit.js";
import {
  closeFriendSchema,
  friendResponseSchema,
  userIdSchema,
  usernameLookupSchema,
} from "../../shared/validation/schemas.js";

export const findUserByUsername = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = usernameLookupSchema.parse(request.data);
      const username = normalizeUsername(input.username);
      const usernameSnapshot = await firestore.doc(`usernames/${username}`).get();
      if (!usernameSnapshot.exists) {
        return { user: null };
      }
      const targetUserId = usernameSnapshot.get("userId") as string;
      if (targetUserId === userId) {
        return { user: null };
      }
      const profile = await firestore.doc(`users/${targetUserId}`).get();
      if (!profile.exists || profile.get("status") === "suspended") {
        return { user: null };
      }
      const profileUsername = profile.get("username") as string;
      const profileDisplayName = profile.get("displayName") as string;
      return {
        user: {
          id: targetUserId,
          username: profileUsername,
          displayName: profileDisplayName,
        },
      };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const sendFriendRequest = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = usernameLookupSchema.parse(request.data);
      await consumeDailyQuota(
        userId,
        "friendRequests",
        maxDailyFriendRequests,
      );

      const usernameSnapshot = await firestore
        .doc(`usernames/${normalizeUsername(input.username)}`)
        .get();
      if (!usernameSnapshot.exists) {
        throw new HttpsError("not-found", "User not found.");
      }
      const targetUserId = usernameSnapshot.get("userId") as string;
      if (targetUserId === userId) {
        throw new HttpsError(
          "invalid-argument",
          "You cannot add yourself.",
        );
      }

      const acceptedCount = await firestore
        .collection("friendships")
        .where("members", "array-contains", userId)
        .where("status", "==", "accepted")
        .count()
        .get();
      if (acceptedCount.data().count >= maxFriends) {
        throw new HttpsError(
          "resource-exhausted",
          "Friend limit reached.",
        );
      }

      const pairId = friendshipId(userId, targetUserId);
      const reference = firestore.doc(`friendships/${pairId}`);
      const [senderProfile, targetProfile] = await Promise.all([
        firestore.doc(`users/${userId}`).get(),
        firestore.doc(`users/${targetUserId}`).get(),
      ]);
      const senderUsername = senderProfile.get("username") as string;
      const senderDisplayName = senderProfile.get("displayName") as string;
      const targetUsername = targetProfile.get("username") as string;
      const targetDisplayName = targetProfile.get("displayName") as string;
      await firestore.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        if (snapshot.get("status") === "blocked") {
          throw new HttpsError(
            "permission-denied",
            "This connection is unavailable.",
          );
        }
        if (snapshot.exists) {
          throw new HttpsError(
            "already-exists",
            "A connection already exists.",
          );
        }
        transaction.create(reference, {
          members: [userId, targetUserId].sort(),
          requestedBy: userId,
          requestedTo: targetUserId,
          status: "pending",
          memberProfiles: {
            [userId]: {
              username: senderUsername,
              displayName: senderDisplayName,
            },
            [targetUserId]: {
              username: targetUsername,
              displayName: targetDisplayName,
            },
          },
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      return { friendshipId: pairId };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const respondFriendRequest = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = friendResponseSchema.parse(request.data);
      const pairId = friendshipId(userId, input.userId);
      const reference = firestore.doc(`friendships/${pairId}`);
      await firestore.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(reference);
        if (
          !snapshot.exists ||
          snapshot.get("status") !== "pending" ||
          snapshot.get("requestedTo") !== userId
        ) {
          throw new HttpsError(
            "failed-precondition",
            "Friend request is not available.",
          );
        }
        if (input.accept) {
          transaction.update(reference, {
            status: "accepted",
            updatedAt: FieldValue.serverTimestamp(),
          });
        } else {
          transaction.delete(reference);
        }
      });
      return { accepted: input.accept };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const removeFriend = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = userIdSchema.parse(request.data);
      const pairId = friendshipId(userId, input.userId);
      await Promise.all([
        firestore.doc(`friendships/${pairId}`).delete(),
        firestore.doc(`users/${userId}/closeFriends/${input.userId}`).delete(),
        firestore.doc(`users/${input.userId}/closeFriends/${userId}`).delete(),
      ]);
      return { removed: true };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);

export const updateCloseFriends = onCall(
  { region, enforceAppCheck: true },
  async (request) => {
    try {
      const userId = requireAuth(request);
      const input = closeFriendSchema.parse(request.data);
      const friendship = await firestore
        .doc(`friendships/${friendshipId(userId, input.friendId)}`)
        .get();
      if (!friendship.exists || friendship.get("status") !== "accepted") {
        throw new HttpsError(
          "failed-precondition",
          "Only accepted friends can be added.",
        );
      }
      const reference = firestore.doc(
        `users/${userId}/closeFriends/${input.friendId}`,
      );
      if (input.enabled) {
        await reference.set({
          friendId: input.friendId,
          createdAt: FieldValue.serverTimestamp(),
        });
      } else {
        await reference.delete();
      }
      return { enabled: input.enabled };
    } catch (error) {
      throw toHttpsError(error);
    }
  },
);
