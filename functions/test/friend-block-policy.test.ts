import { beforeEach, describe, expect, it, vi } from "vitest";
const state = vi.hoisted(() => ({ rows: new Map<string, Record<string, unknown>>() }));
vi.mock("../src/shared/auth/require-auth.js", () => ({
  requireAuth: (req: { auth: { uid: string } }): Promise<string> => Promise.resolve(req.auth.uid),
}));
vi.mock("../src/shared/rate-limit/rate-limit.js", () => ({ consumeDailyQuota: vi.fn() }));
vi.mock("../src/shared/firebase/admin.js", () => {
  interface Snapshot { exists: boolean; get(field: string): unknown }
  const snapshot = (path: string): Snapshot => ({ exists: state.rows.has(path), get: (field: string): unknown => state.rows.get(path)?.[field] });
  const doc = (path: string): { path: string; get(): Promise<Snapshot> } => ({ path, get: (): Promise<Snapshot> => Promise.resolve(snapshot(path)) });
  interface Query { where(): Query; limit(): Query; get(): Promise<{ empty: boolean }> }
  const query: Query = {
    where: (): typeof query => query, limit: (): typeof query => query,
    get: (): Promise<{ empty: boolean }> => Promise.resolve({ empty: true }),
  };
  return { firestore: { doc, collection: (): typeof query => query,
    runTransaction: async (work: (tx: unknown) => Promise<unknown>): Promise<unknown> => work({
      get: (ref: { path: string }): Promise<Snapshot> => Promise.resolve(snapshot(ref.path)),
      set: (ref: { path: string }, data: Record<string, unknown>): void => { state.rows.set(ref.path, { ...state.rows.get(ref.path), ...data }); },
      delete: (ref: { path: string }): void => { state.rows.delete(ref.path); },
    }),
  } };
});
const { blockUser, unblockUser } = await import("../src/modules/moderation/moderation-functions.js");
const { updateCloseFriends } = await import("../src/modules/friendships/friendship-functions.js");
function request(data: unknown, uid = "a"): Parameters<typeof blockUser.run>[0] {
  return { data, auth: { uid, token: {} }, rawRequest: {} } as Parameters<typeof blockUser.run>[0];
}
beforeEach(() => {
  state.rows = new Map([
    ["users/a", { username: "test_a", displayName: "A" }],
    ["users/b", { username: "test_b", displayName: "B" }],
    ["friendships/a__b", { members: ["a", "b"], status: "accepted" }],
  ]);
});
describe("transactional block and Close Friends policy", () => {
  it("clears both close-friend edges; repeat block stays owned by blocker", async () => {
    state.rows.set("users/a/closeFriends/b", { friendId: "b" });
    state.rows.set("users/b/closeFriends/a", { friendId: "a" });
    await blockUser.run(request({ userId: "b" }));
    await blockUser.run(request({ userId: "b" }));
    expect(state.rows.get("friendships/a__b")?.blockedBy).toBe("a");
    expect(state.rows.has("users/a/closeFriends/b") || state.rows.has("users/b/closeFriends/a")).toBe(false);
  });
  it("blocked peer cannot overwrite blocker then unblock to bypass policy", async () => {
    await blockUser.run(request({ userId: "b" }));
    await expect(blockUser.run(request({ userId: "a" }, "b"))).rejects.toMatchObject({ code: "permission-denied" });
    await unblockUser.run(request({ userId: "a" }, "b"));
    expect(state.rows.get("friendships/a__b")?.status).toBe("blocked");
    expect(state.rows.get("friendships/a__b")?.blockedBy).toBe("a");
  });
  it("only blocker unblocks and it does not restore friendship", async () => {
    await blockUser.run(request({ userId: "b" }));
    await unblockUser.run(request({ userId: "b" }));
    await unblockUser.run(request({ userId: "b" }));
    expect(state.rows.has("friendships/a__b")).toBe(false);
  });
  it("Close Friends is idempotent and only accepts current accepted relationships", async () => {
    await updateCloseFriends.run(request({ friendId: "b", enabled: true }));
    await updateCloseFriends.run(request({ friendId: "b", enabled: true }));
    expect([...state.rows.keys()].filter((key) => key.includes("/closeFriends/"))).toHaveLength(1);
    await blockUser.run(request({ userId: "b" }));
    await expect(updateCloseFriends.run(request({ friendId: "b", enabled: true }))).rejects.toMatchObject({ code: "failed-precondition" });
    expect(state.rows.has("users/a/closeFriends/b")).toBe(false);
  });
  it("rejects self-block", async () => {
    await expect(blockUser.run(request({ userId: "a" }))).rejects.toMatchObject({ code: "invalid-argument" });
  });
});
