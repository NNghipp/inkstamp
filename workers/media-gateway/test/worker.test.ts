import { describe, expect, it } from "vitest";
import { InvalidAppCheckError } from "../src/data/firebase_app_check_verifier";
import { InvalidAuthenticationError } from "../src/data/firebase_id_token_verifier";
import { InMemoryRateLimiter } from "../src/data/rate_limiter";
import { handleRequest, type MediaGatewayEnvironment, type WorkerDependencies } from "../src/presentation/worker";

const environment: MediaGatewayEnvironment = {
  FIREBASE_PROJECT_ID: "inkstamp-dev", CLOUDINARY_API_KEY: "public-key",
  CLOUDINARY_API_SECRET: "private-secret", CLOUDINARY_CLOUD_NAME: "inkstamp",
  CLOUDINARY_UPLOAD_PRESET: "inkstamp_private_images",
};

function dependencies(overrides: Partial<WorkerDependencies> = {}): WorkerDependencies {
  return {
    tokenVerifier: { async verify() { return "user-1"; } },
    appCheckVerifier: { async verify({ appCheckHeader }) {
      if (!appCheckHeader) throw new InvalidAppCheckError("App Check token is missing.");
    } },
    rateLimiter: { async checkLimit() { return { allowed: true, retryAfterSeconds: 0 }; } },
    mediaAuthorizer: { async canRead() { return true; } },
    assetDeleter: { async delete() {} },
    ...overrides,
  };
}

describe("media gateway", () => {
  it("reports health only when configuration is complete", async () => {
    expect((await handleRequest(new Request("https://host/health"), environment, dependencies())).status).toBe(200);
    const invalid = await handleRequest(new Request("https://host/health"), { ...environment, CLOUDINARY_API_SECRET: "" }, dependencies());
    expect(invalid.status).toBe(503);
    expect(await invalid.text()).not.toContain("private-secret");
  });

  it("returns a user-scoped authenticated upload signature without its secret", async () => {
    const response = await handleRequest(uploadRequest(), environment, dependencies());
    const body = await response.json<Record<string, unknown>>();
    expect(response.status).toBe(200);
    expect(body.uploadUrl).toBe("https://api.cloudinary.com/v1_1/inkstamp/image/authenticated");
    expect(JSON.stringify(body)).not.toContain("private-secret");
  });

  it("rejects invalid media kinds and oversized bodies", async () => {
    expect((await handleRequest(uploadRequest("video"), environment, dependencies())).status).toBe(400);
    expect((await handleRequest(uploadRequest("stamp", "x".repeat(1100)), environment, dependencies())).status).toBe(400);
  });

  it("rejects auth before consuming quota", async () => {
    let calls = 0;
    const response = await handleRequest(uploadRequest(), environment, dependencies({
      tokenVerifier: { async verify() { throw new InvalidAuthenticationError(); } },
      rateLimiter: { async checkLimit() { calls += 1; return { allowed: true, retryAfterSeconds: 0 }; } },
    }));
    expect(response.status).toBe(401);
    expect(calls).toBe(0);
  });

  it("requires App Check when enforced", async () => {
    const response = await handleRequest(uploadRequest(), { ...environment, APP_CHECK_ENFORCED: "true" }, dependencies());
    expect(response.status).toBe(403);
  });

  it("returns Retry-After when rate limited", async () => {
    const response = await handleRequest(uploadRequest(), { ...environment, RATE_LIMIT_ENFORCED: "true" }, dependencies({
      rateLimiter: { async checkLimit() { return { allowed: false, retryAfterSeconds: 37 }; } },
    }));
    expect(response.status).toBe(429);
    expect(response.headers.get("Retry-After")).toBe("37");
  });

  it("uses separate endpoint scopes", async () => {
    const scopes: string[] = [];
    const deps = dependencies({ rateLimiter: { async checkLimit(input) {
      scopes.push(input.scope); return { allowed: true, retryAfterSeconds: 0 };
    } } });
    const env = { ...environment, RATE_LIMIT_ENFORCED: "true" };
    await handleRequest(uploadRequest(), env, deps);
    await handleRequest(deliveryRequest(), env, deps);
    expect(scopes).toEqual(["upload", "delivery"]);
  });

  it("signs delivery URLs only after authorization", async () => {
    expect((await handleRequest(deliveryRequest(), environment, dependencies())).status).toBe(200);
    expect((await handleRequest(deliveryRequest(), environment, dependencies({ mediaAuthorizer: {
      async canRead() { return false; },
    } }))).status).toBe(403);
  });

  it("rejects malformed public IDs and unknown routes", async () => {
    expect((await handleRequest(deliveryRequest(["other/stamp/id"]), environment, dependencies())).status).toBe(400);
    expect((await handleRequest(new Request("https://host/unknown"), environment, dependencies())).status).toBe(404);
  });

  it("deletes only media owned by the authenticated user", async () => {
    const deleted: string[] = [];
    const deps = dependencies({
      assetDeleter: { async delete(input) { deleted.push(input.publicId); } },
    });
    const owned = await handleRequest(
      deleteRequest("inkstamp/user-1/stamp/id-1"), environment, deps,
    );
    const foreign = await handleRequest(
      deleteRequest("inkstamp/user-2/stamp/id-1"), environment, deps,
    );
    expect(owned.status).toBe(200);
    expect(foreign.status).toBe(403);
    expect(deleted).toEqual(["inkstamp/user-1/stamp/id-1"]);
  });
});

describe("InMemoryRateLimiter", () => {
  it("isolates users/scopes and resets windows", async () => {
    let now = 1_000;
    const limiter = new InMemoryRateLimiter(() => now, { upload: 1, delivery: 1 }, 10, 1_000);
    const check = (userId: string, scope: "upload" | "delivery") => limiter.checkLimit({ ip: "ip", userId, scope });
    expect((await check("a", "upload")).allowed).toBe(true);
    expect((await check("a", "upload")).allowed).toBe(false);
    expect((await check("a", "delivery")).allowed).toBe(true);
    expect((await check("b", "upload")).allowed).toBe(true);
    now = 2_001;
    expect((await check("a", "upload")).allowed).toBe(true);
  });
});

function uploadRequest(mediaKind = "stamp", padding = ""): Request {
  return new Request("https://host/v1/media/upload-signatures", { method: "POST",
    headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
    body: JSON.stringify({ mediaKind, padding }) });
}

function deliveryRequest(publicIds = ["inkstamp/user-1/stamp/id-1"]): Request {
  return new Request("https://host/v1/media/delivery-urls", { method: "POST",
    headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
    body: JSON.stringify({ publicIds }) });
}

function deleteRequest(publicId: string): Request {
  return new Request("https://host/v1/media/delete", { method: "POST",
    headers: { Authorization: "Bearer token", "Content-Type": "application/json" },
    body: JSON.stringify({ publicId }) });
}
