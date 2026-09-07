import { describe, expect, it } from "vitest";
import { InvalidAuthenticationError } from "../src/data/firebase_id_token_verifier";
import {
  handleRequest,
  type MediaGatewayEnvironment,
  type TokenVerifier,
} from "../src/presentation/worker";

const environment: MediaGatewayEnvironment = {
  FIREBASE_PROJECT_ID: "inkstamp-dev",
  CLOUDINARY_API_KEY: "public-key",
  CLOUDINARY_API_SECRET: "private-secret",
  CLOUDINARY_CLOUD_NAME: "inkstamp",
  CLOUDINARY_UPLOAD_PRESET: "inkstamp_private_images",
};

const authenticatedVerifier: TokenVerifier = {
  async verify() {
    return "user-1";
  },
};

describe("media gateway", () => {
  it("reports health", async () => {
    const response = await handleRequest(
      new Request("https://media.inkstamp.app/health"),
      environment,
      authenticatedVerifier,
    );
    expect(response.status).toBe(200);
    await expect(response.json()).resolves.toEqual({
      status: "ok",
      service: "inkstamp-media-gateway",
    });
  });

  it("returns a user-scoped authenticated upload signature", async () => {
    const response = await handleRequest(
      request({ mediaKind: "thumbnail" }),
      environment,
      authenticatedVerifier,
    );
    const body = await response.json<Record<string, unknown>>();

    expect(response.status).toBe(200);
    expect(body.uploadUrl).toBe(
      "https://api.cloudinary.com/v1_1/inkstamp/image/authenticated",
    );
    expect(JSON.stringify(body)).not.toContain("private-secret");
  });

  it("rejects invalid media kinds", async () => {
    const response = await handleRequest(
      request({ mediaKind: "video" }),
      environment,
      authenticatedVerifier,
    );

    expect(response.status).toBe(400);
    await expect(response.json()).resolves.toEqual({
      error: "mediaKind must be stamp or thumbnail.",
    });
  });

  it("rejects bodies larger than the endpoint contract", async () => {
    const response = await handleRequest(
      request({ mediaKind: "stamp", padding: "x".repeat(1100) }),
      environment,
      authenticatedVerifier,
    );

    expect(response.status).toBe(400);
    await expect(response.json()).resolves.toEqual({
      error: "Request body is too large.",
    });
  });

  it("rejects unauthenticated requests", async () => {
    const verifier: TokenVerifier = {
      async verify() {
        throw new InvalidAuthenticationError();
      },
    };
    const response = await handleRequest(
      request({ mediaKind: "stamp" }),
      environment,
      verifier,
    );

    expect(response.status).toBe(401);
  });

  it("does not expose the endpoint through other routes", async () => {
    const response = await handleRequest(
      new Request("https://media.inkstamp.app/unknown"),
      environment,
      authenticatedVerifier,
    );

    expect(response.status).toBe(404);
  });

  describe("App Check verification", () => {
    it("allows request when App Check is not enforced", async () => {
      const response = await handleRequest(
        request({ mediaKind: "stamp" }),
        { ...environment, APP_CHECK_ENFORCED: "false" },
        authenticatedVerifier,
      );
      expect(response.status).toBe(200);
    });

    it("rejects request when App Check is enforced and header is missing", async () => {
      const response = await handleRequest(
        request({ mediaKind: "stamp" }),
        { ...environment, APP_CHECK_ENFORCED: "true" },
        authenticatedVerifier,
      );
      expect(response.status).toBe(403);
      await expect(response.json()).resolves.toEqual({
        error: "App Check token is missing.",
      });
    });
  });

  describe("Rate Limiting", () => {
    it("returns 429 when rate limit is exceeded and enforced", async () => {
      const rateLimitEnv = { ...environment, RATE_LIMIT_ENFORCED: "true" };
      // InMemoryRateLimiter limits to 50 requests per User per minute.
      // Let's send 50 requests (which should succeed).
      for (let i = 0; i < 50; i++) {
        const res = await handleRequest(
          request({ mediaKind: "stamp" }),
          rateLimitEnv,
          authenticatedVerifier,
        );
        expect(res.status).toBe(200);
      }
      // The 51st request should be rate limited
      const rateLimitedRes = await handleRequest(
        request({ mediaKind: "stamp" }),
        rateLimitEnv,
        authenticatedVerifier,
      );
      expect(rateLimitedRes.status).toBe(429);
      await expect(rateLimitedRes.json()).resolves.toEqual({
        error: "Too many requests. Please try again later.",
      });
    });
  });

  describe("Delivery URLs", () => {
    it("returns signed delivery URLs for valid public IDs", async () => {
      const req = new Request(
        "https://media.inkstamp.app/v1/media/delivery-urls",
        {
          method: "POST",
          headers: {
            Authorization: "Bearer test-token",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            publicIds: [
              "inkstamp/user-1/stamp/uuid-1",
              "inkstamp/user-1/thumbnail/uuid-1",
            ],
          }),
        },
      );
      const response = await handleRequest(req, environment, authenticatedVerifier);
      expect(response.status).toBe(200);
      const body = await response.json<any>();
      expect(body.deliveryUrls).toBeDefined();
      expect(body.deliveryUrls["inkstamp/user-1/stamp/uuid-1"]).toContain(
        "https://res.cloudinary.com/inkstamp/image/authenticated/s--",
      );
      expect(body.deliveryUrls["inkstamp/user-1/stamp/uuid-1"]).toContain(
        "/inkstamp/user-1/stamp/uuid-1",
      );
    });

    it("rejects invalid public ID namespace", async () => {
      const req = new Request(
        "https://media.inkstamp.app/v1/media/delivery-urls",
        {
          method: "POST",
          headers: {
            Authorization: "Bearer test-token",
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            publicIds: ["other_folder/stamp/uuid-1"],
          }),
        },
      );
      const response = await handleRequest(req, environment, authenticatedVerifier);
      expect(response.status).toBe(400);
      await expect(response.json()).resolves.toEqual({
        error: "Forbidden publicId namespace.",
      });
    });
  });
});

function request(body: Record<string, string>): Request {
  return new Request(
    "https://media.inkstamp.app/v1/media/upload-signatures",
    {
      method: "POST",
      headers: {
        Authorization: "Bearer test-token",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    },
  );
}
