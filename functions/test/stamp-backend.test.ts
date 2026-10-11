import { beforeEach, describe, expect, it, vi } from "vitest";

const state = vi.hoisted(() => ({
  rows: new Map<string, Record<string, unknown>>(), failCommit: false,
  notify: vi.fn(),
}));
vi.mock("../src/shared/auth/require-auth.js", () => ({
  requireAuth: (request: { auth?: { uid: string } }): Promise<string> => {
    if (!request.auth) throw new Error("unauthenticated");
    return Promise.resolve(request.auth.uid);
  },
}));
vi.mock("../src/shared/rate-limit/rate-limit.js", () => ({ consumeDailyQuota: vi.fn() }));
vi.mock("../src/modules/stamps/audience-resolver.js", () => ({ resolveAudience: (): Promise<string[]> => Promise.resolve(["b"]) }));
vi.mock("../src/modules/notifications/send-notifications.js", () => ({ sendStampNotifications: state.notify }));
vi.mock("../src/modules/stamps/revoke-media.js", () => ({ revokeMedia: (): Promise<boolean> => Promise.resolve(true) }));
vi.mock("../src/shared/firebase/admin.js", () => {
  interface Snapshot { exists: boolean; get(field: string): unknown; ref: { path: string } }
  interface Reference { path: string; get(): Promise<Snapshot>; delete(): Promise<boolean> }
  const snapshot = (path: string, rows = state.rows): Snapshot => ({
    exists: rows.has(path), get: (field: string): unknown => rows.get(path)?.[field],
    ref: { path },
  });
  const doc = (path: string): Reference => ({ path, get: (): Promise<Snapshot> => Promise.resolve(snapshot(path)), delete: (): Promise<boolean> => Promise.resolve(state.rows.delete(path)) });
  return { firestore: {
    doc,
    runTransaction: async (work: (tx: unknown) => Promise<unknown>): Promise<unknown> => {
      const staged = new Map(state.rows);
      const result = await work({
        get: (ref: { path: string }): Promise<Snapshot> => Promise.resolve(snapshot(ref.path, staged)),
        getAll: (...refs: { path: string }[]): Promise<Snapshot[]> => Promise.resolve(refs.map((ref) => snapshot(ref.path, staged))),
        create: (ref: { path: string }, data: Record<string, unknown>) => {
          if (staged.has(ref.path)) throw new Error("already exists");
          staged.set(ref.path, data);
        },
        update: (ref: { path: string }, data: Record<string, unknown>) => staged.set(ref.path, { ...staged.get(ref.path), ...data }),
      });
      if (state.failCommit) throw new Error("injected commit failure");
      state.rows = staged;
      return result;
    },
  } };
});
const { publishStamp } = await import("../src/modules/stamps/publish-stamp.js");
const { deleteStampForEveryone } = await import("../src/modules/stamps/manage-stamps.js");
const payload = {
  requestId: "f46c7c2a-ea68-4c34-b11d-017cc8c5a092",
  cloudinaryPublicId: "inkstamp/a/stamp/photo", cloudinaryThumbnailPublicId: "inkstamp/a/thumbnail/photo",
  audience: "selected", selectedRecipientIds: ["b"], frameStyle: "classic", paperTone: "cream",
  captureLocalDate: "2026-10-07", timezoneOffsetMinutes: 420,
};
function request(data: unknown, uid = "a"): Parameters<typeof publishStamp.run>[0] {
  return { data, auth: { uid, token: {} }, rawRequest: {} } as Parameters<typeof publishStamp.run>[0];
}
beforeEach(() => {
  state.rows = new Map([["friendships/a__b", { status: "accepted" }]]);
  state.failCommit = false;
  state.notify.mockReset();
});
describe("atomic stamp publish and revoke (unit adapter)", () => {
  it("creates exactly one stamp, request and recipient delivery on repeated publish", async () => {
    const first = await publishStamp.run(request(payload));
    const second = await publishStamp.run(request(payload));
    expect(second).toEqual({ stampId: first.stampId, duplicate: true });
    expect([...state.rows.keys()].filter((key) => key.startsWith("stamps/"))).toHaveLength(1);
    expect([...state.rows.keys()].filter((key) => key.includes("/deliveries/"))).toHaveLength(1);
    expect(state.notify).toHaveBeenCalledTimes(1);
  });
  it("does not delete committed data if notification/response-side work fails", async () => {
    state.notify.mockRejectedValueOnce(new Error("push unavailable"));
    const first = await publishStamp.run(request(payload));
    const retry = await publishStamp.run(request(payload));
    expect(retry.stampId).toBe(first.stampId);
    expect(state.rows.get(`users/b/deliveries/${first.stampId}`)?.status).toBe("available");
  });
  it("has no partial deliveries when commit fails; same request can retry", async () => {
    state.failCommit = true;
    await expect(publishStamp.run(request(payload))).rejects.toThrow();
    expect(state.rows.size).toBe(1);
    state.failCommit = false;
    const retry = await publishStamp.run(request(payload));
    expect(retry.duplicate).toBe(false);
    expect(state.rows.get(`users/b/deliveries/${retry.stampId}`)?.status).toBe("available");
  });
  it("rejects recipients no longer accepted in transaction", async () => {
    state.rows.set("friendships/a__b", { status: "blocked" });
    await expect(publishStamp.run(request(payload))).rejects.toMatchObject({ code: "permission-denied" });
    expect(state.rows.size).toBe(1);
  });
  it("rejects foreign media ownership", async () => {
    await expect(publishStamp.run(request({ ...payload, cloudinaryPublicId: "inkstamp/b/stamp/photo" }))).rejects.toMatchObject({ code: "invalid-argument" });
  });
  it("allows sender revoke, keeps identifiable unavailable rows, double revoke idempotent", async () => {
    const published = await publishStamp.run(request(payload));
    const data = { stampId: published.stampId };
    await deleteStampForEveryone.run(request(data));
    const firstRevokedAt = state.rows.get(`stamps/${published.stampId}`)?.revokedAt;
    await deleteStampForEveryone.run(request(data));
    expect(state.rows.get(`stamps/${published.stampId}`)?.revokedAt).toBe(firstRevokedAt);
    expect(state.rows.get(`users/b/deliveries/${published.stampId}`)?.status).toBe("revoked");
    expect((await publishStamp.run(request(payload))).stampId).toBe(published.stampId);
    expect(state.rows.get(`users/b/deliveries/${published.stampId}`)?.status).toBe("revoked");
  });
  it.each(["b", "unrelated"])("denies revoke by %s", async (uid) => {
    const published = await publishStamp.run(request(payload));
    await expect(deleteStampForEveryone.run(request({ stampId: published.stampId }, uid))).rejects.toMatchObject({ code: "permission-denied" });
    expect(state.rows.get(`stamps/${published.stampId}`)?.status).toBe("active");
  });
});
