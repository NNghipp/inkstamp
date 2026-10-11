import { afterEach, describe, expect, it, vi } from "vitest";
import { FirestoreRestMediaAuthorizer } from "../src/data/firestore_media_authorizer";

const full = "inkstamp/sender/stamp/old";
const thumb = "inkstamp/sender/thumbnail/old";
const input = { idToken: "test-token", projectId: "inkstamp-dev", userId: "recipient", publicIds: [full, thumb] };
const document = (status: string, id = full, thumbnail = thumb) => ({ fields: {
  status: { stringValue: status }, cloudinaryPublicId: { stringValue: id },
  cloudinaryThumbnailPublicId: { stringValue: thumbnail },
} });
afterEach(() => vi.unstubAllGlobals());
describe("Firestore media authorization", () => {
  it.each([0, 1, 25, 26, 100, 101, 126])("finds the requested delivery beyond %i prior records", async (count) => {
    const docs = Array.from({ length: count }, (_, i) => document("available", `unrelated-${i}`, `thumb-${i}`));
    docs.push(document("available"));
    const fetcher = vi.fn(async (url: URL) => {
      const start = Number(url.searchParams.get("pageToken") ?? 0);
      return Response.json({ documents: docs.slice(start, start + 100),
        ...(start + 100 < docs.length ? { nextPageToken: String(start + 100) } : {}) });
    });
    vi.stubGlobal("fetch", fetcher);
    expect(await new FirestoreRestMediaAuthorizer().canRead(input)).toBe(true);
    expect(fetcher).toHaveBeenCalledTimes(Math.ceil(docs.length / 100));
  });
  it.each(["revoked", "deleted", "publishing", ""])("denies %s media", async (status) => {
    vi.stubGlobal("fetch", vi.fn(async () => Response.json({ documents: [document(status)] })));
    expect(await new FirestoreRestMediaAuthorizer().canRead(input)).toBe(false);
  });
  it("fails closed for empty inbox and unauthorized Firestore responses", async () => {
    vi.stubGlobal("fetch", vi.fn(async () => Response.json({ documents: [] })));
    expect(await new FirestoreRestMediaAuthorizer().canRead(input)).toBe(false);
    vi.stubGlobal("fetch", vi.fn(async () => new Response(null, { status: 403 })));
    expect(await new FirestoreRestMediaAuthorizer().canRead(input)).toBe(false);
  });
  it("fails closed on a repeating page token", async () => {
    const fetcher = vi.fn(async () => Response.json({ nextPageToken: "repeat" }));
    vi.stubGlobal("fetch", fetcher);
    expect(await new FirestoreRestMediaAuthorizer().canRead(input)).toBe(false);
    expect(fetcher).toHaveBeenCalledTimes(2);
  });
  it.each([true, false])("owner access requires an active stamp: %s", async (active) => {
    const fetcher = vi.fn(async (_url: string | URL, init?: RequestInit) => {
      if (init?.method === "POST") return Response.json(active ? [{ document: document("active") }] : []);
      return Response.json({ documents: [] });
    });
    vi.stubGlobal("fetch", fetcher);
    expect(await new FirestoreRestMediaAuthorizer().canRead({ ...input, userId: "sender" })).toBe(active);
    expect(JSON.parse(fetcher.mock.calls[0]![1]!.body as string).structuredQuery.where.compositeFilter.filters[0].fieldFilter.value.stringValue).toBe("sender");
  });
});
