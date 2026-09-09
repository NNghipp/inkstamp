import { readFileSync } from "node:fs";
import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc } from "firebase/firestore";
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
      await setDoc(doc(context.firestore(), "users/user-1/deliveries/stamp-1"), { stampId: "stamp-1" });
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
});
