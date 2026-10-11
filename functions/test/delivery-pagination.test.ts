import { readFileSync } from "node:fs";
import { initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDocs, limit, orderBy, query, startAfter, Timestamp, updateDoc, where, writeBatch, documentId } from "firebase/firestore";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

const suite = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;
suite("delivery cursor pagination against Firestore + unchanged Rules", () => {
  let environment: RulesTestEnvironment;
  const time = Timestamp.fromDate(new Date("2026-10-07T01:00:00Z"));
  beforeAll(async () => {
    environment = await initializeTestEnvironment({ projectId: "inkstamp-pagination-test",
      firestore: { rules: readFileSync("../firestore.rules", "utf8") } });
  });
  afterAll(async () => environment.cleanup());
  async function seed(uid: string, count: number): Promise<void> {
    await environment.withSecurityRulesDisabled(async (context) => {
      const batch = writeBatch(context.firestore());
      for (let i = 0; i < count; i++) batch.set(doc(context.firestore(), `users/${uid}/deliveries/${String(i).padStart(4, "0")}`), {
        createdAt: time, status: "available", isSeen: false,
      });
      await batch.commit();
    });
  }
  it.each([0, 1, 25, 26, 100, 101, 126])("pages %i equal-timestamp rows without duplication/skips", async (count) => {
    const uid = `page-${count}`;
    await seed(uid, count);
    const db = environment.authenticatedContext(uid).firestore();
    const base = query(collection(db, `users/${uid}/deliveries`), where("status", "==", "available"), orderBy("createdAt", "desc"), orderBy(documentId(), "desc"));
    const ids: string[] = [];
    let cursor: [Timestamp, string] | undefined;
    while (true) {
      const result = await getDocs(cursor ? query(base, startAfter(...cursor), limit(26)) : query(base, limit(26)));
      const page = result.docs.slice(0, 25);
      ids.push(...page.map((row) => row.id));
      if (result.docs.length <= 25) break;
      cursor = [time, page.at(-1)!.id];
    }
    expect(ids).toEqual(Array.from({ length: count }, (_, i) => String(count - i - 1).padStart(4, "0")));
    expect(new Set(ids).size).toBe(count);
  });
  it("continues correctly after cursor doc deleted and next doc revoked", async () => {
    const uid = "page-mutation";
    await seed(uid, 51);
    const db = environment.authenticatedContext(uid).firestore();
    const base = query(collection(db, `users/${uid}/deliveries`), where("status", "==", "available"), orderBy("createdAt", "desc"), orderBy(documentId(), "desc"));
    const first = (await getDocs(query(base, limit(25)))).docs;
    const last = first.at(-1)!.id;
    await environment.withSecurityRulesDisabled(async (context) => {
      await deleteDoc(doc(context.firestore(), `users/${uid}/deliveries/${last}`));
      await updateDoc(doc(context.firestore(), `users/${uid}/deliveries/0025`), { status: "revoked" });
    });
    const next = (await getDocs(query(base, startAfter(time, last), limit(26)))).docs.map((row) => row.id);
    expect(next).toEqual(Array.from({ length: 25 }, (_, i) => String(24 - i).padStart(4, "0")));
    expect(next.some((id) => first.some((row) => row.id === id))).toBe(false);
  });
});
