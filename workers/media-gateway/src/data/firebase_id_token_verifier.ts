import { createRemoteJWKSet, jwtVerify } from "jose";

const firebaseKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

export class FirebaseIdTokenVerifier {
  async verify({
    authorizationHeader,
    projectId,
  }: {
    authorizationHeader: string | null;
    projectId: string;
  }): Promise<string> {
    const token = authorizationHeader?.match(/^Bearer\s+([^\s]+)$/i)?.[1];
    if (token === undefined || token.length > 4096) {
      throw new InvalidAuthenticationError();
    }

    try {
      const { payload } = await jwtVerify(token, firebaseKeys, {
        algorithms: ["RS256"],
        audience: projectId,
        issuer: `https://securetoken.google.com/${projectId}`,
      });
      if (
        typeof payload.sub !== "string" ||
        payload.sub.length === 0 ||
        payload.sub.length > 128
      ) {
        throw new InvalidAuthenticationError();
      }
      return payload.sub;
    } catch (error) {
      if (error instanceof InvalidAuthenticationError) {
        throw error;
      }
      throw new InvalidAuthenticationError();
    }
  }
}

export class InvalidAuthenticationError extends Error {
  constructor() {
    super("The Firebase ID token is invalid.");
    this.name = "InvalidAuthenticationError";
  }
}
