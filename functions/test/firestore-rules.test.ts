import { readFileSync } from "node:fs";
import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, limit, orderBy, query, setDoc, Timestamp, updateDoc, where } from "firebase/firestore";
import { afterAll, beforeAll, describe, it } from "vitest";

const emulatorAvailable = process.env.FIRESTORE_EMULATOR_HOST !== undefined;
const describeEmulator = emulatorAvailable ? describe : describe.skip;

describeEmulator("Firestore security rules", () => {
  let environment: RulesTestEnvironment;

  beforeAll(async () => {
    environment = await initializeTestEnvironment({
      projectId: "inkstamp-rules-test",
      firestore: { rules: readFileSync("../firestore.rules", "utf8") },
    });
    await environment.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), "users/user-1/deliveries/stamp-1"), {
        stampId: "stamp-1", senderId: "user-2", status: "available", isSeen: false,
        createdAt: Timestamp.fromDate(new Date("2026-09-25T17:30:00Z")),
      });
      await setDoc(doc(context.firestore(), "users/user-1/deliveries/revoked"), {
        stampId: "revoked", status: "revoked", isSeen: false,
      });
      await setDoc(doc(context.firestore(), "stamps/own"), {
        senderId: "user-1", status: "active", createdAt: Timestamp.fromDate(new Date("2026-09-25T17:30:00Z")),
      });
      await setDoc(doc(context.firestore(), "friendships/user-1__user-2"), {
        members: ["user-1", "user-2"],
        status: "accepted",
      });
      await setDoc(doc(context.firestore(), "users/user-1/closeFriends/user-2"), {
        friendId: "user-2",
      });
    });
  });

  afterAll(async () => environment.cleanup());

  it("denies direct username reservation and profile writes", async () => {
    const database = environment.authenticatedContext("user-1").firestore();
    await assertFails(setDoc(doc(database, "usernames/name"), { userId: "user-1" }));
    await assertFails(setDoc(doc(database, "users/user-1"), { username: "name" }));
  });

  it("allows only the owner to read a delivery", async () => {
    const owner = environment.authenticatedContext("user-1").firestore();
    const other = environment.authenticatedContext("user-2").firestore();
    await assertSucceeds(getDoc(doc(owner, "users/user-1/deliveries/stamp-1")));
    await assertFails(getDoc(doc(other, "users/user-1/deliveries/stamp-1")));
  });

  it("allows only owner to mark available delivery seen without changing protected fields", async () => {
    const owner = environment.authenticatedContext("user-1").firestore();
    const other = environment.authenticatedContext("user-2").firestore();
    const delivery = doc(owner, "users/user-1/deliveries/stamp-1");
    await assertSucceeds(updateDoc(delivery, { isSeen: true }));
    await assertSucceeds(updateDoc(delivery, { isSeen: true }));
    await assertFails(updateDoc(delivery, { isSeen: false }));
    await assertFails(updateDoc(delivery, { isSeen: "true" }));
    await assertFails(updateDoc(delivery, { isSeen: true, senderId: "user-3" }));
    await assertFails(updateDoc(delivery, { status: "available", cloudinaryPublicId: "forged" }));
    await assertFails(updateDoc(doc(other, "users/user-1/deliveries/stamp-1"), { isSeen: true }));
    await assertFails(updateDoc(doc(owner, "users/user-1/deliveries/revoked"), { isSeen: true }));
  });

  it("allows scoped Inbox and Calendar month queries, never another user's archive", async () => {
    const owner = environment.authenticatedContext("user-1").firestore();
    const other = environment.authenticatedContext("user-2").firestore();
    const start = Timestamp.fromDate(new Date("2026-08-31T17:00:00Z"));
    const end = Timestamp.fromDate(new Date("2026-09-30T17:00:00Z"));
    await assertSucceeds(getDocs(query(collection(owner, "users/user-1/deliveries"),
      where("status", "==", "available"), orderBy("createdAt", "desc"), limit(26))));
    await assertSucceeds(getDocs(query(collection(owner, "users/user-1/deliveries"),
      where("status", "==", "available"), where("createdAt", ">=", start), where("createdAt", "<", end),
      orderBy("createdAt", "desc"))));
    await assertFails(getDocs(collection(other, "users/user-1/deliveries")));
    await assertSucceeds(getDocs(query(collection(owner, "stamps"),
      where("senderId", "==", "user-1"), where("status", "==", "active"),
      where("createdAt", ">=", start), where("createdAt", "<", end), orderBy("createdAt", "desc"))));
    await assertFails(getDocs(query(collection(other, "stamps"), where("senderId", "==", "user-1"))));
    await assertFails(getDocs(collection(owner, "stamps")));
  });

  it("allows friendship members to read but never write the relationship", async () => {
    const member = environment.authenticatedContext("user-1").firestore();
    const stranger = environment.authenticatedContext("user-3").firestore();
    const friendship = doc(member, "friendships/user-1__user-2");
    await assertSucceeds(getDoc(friendship));
    await assertFails(getDoc(doc(stranger, "friendships/user-1__user-2")));
    await assertFails(setDoc(friendship, { status: "blocked" }, { merge: true }));
  });

  it("allows a member-scoped friendship query", async () => {
    const member = environment.authenticatedContext("user-1").firestore();
    await assertSucceeds(
      getDocs(
        query(
          collection(member, "friendships"),
          where("members", "array-contains", "user-1"),
          where("status", "==", "accepted"),
        ),
      ),
    );
  });

  it("keeps close-friend membership private and server-owned", async () => {
    const owner = environment.authenticatedContext("user-1").firestore();
    const other = environment.authenticatedContext("user-2").firestore();
    const closeFriend = doc(owner, "users/user-1/closeFriends/user-2");
    await assertSucceeds(getDoc(closeFriend));
    await assertFails(getDoc(doc(other, "users/user-1/closeFriends/user-2")));
    await assertFails(setDoc(closeFriend, { friendId: "user-2" }));
  });
});
