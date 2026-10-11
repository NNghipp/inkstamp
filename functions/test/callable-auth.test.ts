import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { CallableRequest } from "firebase-functions/v2/https";
import { request as expressRequest } from "express";
const verify = vi.hoisted(() => vi.fn());
vi.mock("../src/shared/firebase/admin.js", () => ({ auth: { verifyIdToken: verify } }));
const { requireAuth } = await import("../src/shared/auth/require-auth.js");
function request(uid = "a", header = "Bearer signed-id-token"): CallableRequest<unknown> {
  // Express request prototype supplies the transport shape; only header is used.
  const rawRequest = Object.create(expressRequest) as CallableRequest<unknown>["rawRequest"];
  vi.spyOn(rawRequest, "header").mockReturnValue(header);
  return { acceptsStreaming: false, auth: { uid, rawToken: header, token: {
    uid, sub: uid, aud: "inkstamp-dev", iss: "https://securetoken.google.com/inkstamp-dev",
    iat: 0, exp: 1, auth_time: 0, firebase: { identities: {}, sign_in_provider: "password" },
  } }, data: { uid: "impersonated" }, rawRequest };
}
beforeEach(() => {
  verify.mockReset();
  vi.stubEnv("FUNCTIONS_EMULATOR", "true");
  vi.stubEnv("GCLOUD_PROJECT", "inkstamp-dev");
  vi.stubEnv("FIREBASE_AUTH_EMULATOR_HOST", "");
});
afterEach(() => { vi.unstubAllEnvs(); vi.restoreAllMocks(); });
describe("real ID token verification in Functions emulator", () => {
  it("derives uid from verified token, never payload identity", async () => {
    verify.mockResolvedValue({ uid: "a" });
    expect(await requireAuth(request())).toBe("a");
    expect(verify).toHaveBeenCalledWith("signed-id-token", true);
  });
  it("rejects missing authentication", async () => {
    await expect(requireAuth({ data: {} } as CallableRequest<unknown>)).rejects.toMatchObject({ code: "unauthenticated" });
  });
  it("rejects missing bearer header", async () => {
    await expect(requireAuth(request("a", ""))).rejects.toMatchObject({ code: "unauthenticated" });
  });
  it("rejects bad signature even when emulator decoded auth claims", async () => {
    verify.mockRejectedValue(new Error("invalid signature"));
    await expect(requireAuth(request())).rejects.toMatchObject({ code: "unauthenticated" });
  });
  it("rejects mismatched decoded vs verified uid", async () => {
    verify.mockResolvedValue({ uid: "b" });
    await expect(requireAuth(request())).rejects.toMatchObject({ code: "unauthenticated" });
  });
  it.each(["wrong-project", "auth-emulator"])("fails closed for %s", async (mode) => {
    vi.stubEnv(mode === "wrong-project" ? "GCLOUD_PROJECT" : "FIREBASE_AUTH_EMULATOR_HOST", mode === "wrong-project" ? "other" : "localhost:9099");
    await expect(requireAuth(request())).rejects.toMatchObject({ code: "unauthenticated" });
    expect(verify).not.toHaveBeenCalled();
  });
});
