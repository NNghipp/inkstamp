import { beforeAll, describe, expect, it } from "vitest";
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "jose";
import { FirebaseAppCheckVerifier, InvalidAppCheckError } from "../src/data/firebase_app_check_verifier";

describe("App Check project isolation", () => {
  let key: CryptoKey;
  let verifier: FirebaseAppCheckVerifier;
  beforeAll(async () => {
    const keys = await generateKeyPair("RS256");
    key = keys.privateKey;
    verifier = new FirebaseAppCheckVerifier(createLocalJWKSet({ keys: [await exportJWK(keys.publicKey)] }));
  });
  async function token({ number = "123", typ = "JWT", expiry = "5m", issuer }: {
    number?: string; typ?: string; expiry?: string; issuer?: string;
  } = {}) {
    return new SignJWT({}).setProtectedHeader({ alg: "RS256", typ })
      .setIssuer(issuer ?? `https://firebaseappcheck.googleapis.com/${number}`)
      .setAudience(`projects/${number}`).setSubject("unit-app")
      .setIssuedAt().setExpirationTime(expiry).sign(key);
  }
  it("accepts a signed token for the exact project number", async () => {
    await expect(verifier.verify({ appCheckHeader: await token(), projectNumber: "123" })).resolves.toBeUndefined();
  });
  it.each(["other project", "wrong issuer", "wrong header", "expired"])("denies %s", async (kind) => {
    const value = await token(kind === "other project" ? { number: "456" } :
      kind === "wrong issuer" ? { issuer: "https://firebaseappcheck.googleapis.com/456" } :
      kind === "wrong header" ? { typ: "NOT-JWT" } : { expiry: "-1m" });
    await expect(verifier.verify({ appCheckHeader: value, projectNumber: "123" }))
      .rejects.toBeInstanceOf(InvalidAppCheckError);
  });
});
