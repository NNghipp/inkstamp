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
      new Request("https://media.inkstamp.app/health"),
      environment,
      authenticatedVerifier,
    );

    expect(response.status).toBe(404);
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
