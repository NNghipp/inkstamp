import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "jose";

const appCheckKeys = createRemoteJWKSet(
  new URL("https://firebaseappcheck.googleapis.com/v1/jwks"),
);

export class FirebaseAppCheckVerifier {
  constructor(private readonly keys: JWTVerifyGetKey = appCheckKeys) {}
  async verify({
    appCheckHeader,
    projectNumber,
  }: {
    appCheckHeader: string | null;
    projectNumber: string;
  }): Promise<void> {
    if (appCheckHeader === null || appCheckHeader.length === 0) {
      throw new InvalidAppCheckError("App Check token is missing.");
    }
    if (appCheckHeader.length > 4096) {
      throw new InvalidAppCheckError("App Check token is too long.");
    }

    try {
      const { payload, protectedHeader } = await jwtVerify(appCheckHeader, this.keys, {
        algorithms: ["RS256"],
        audience: [`projects/${projectNumber}`],
        issuer: `https://firebaseappcheck.googleapis.com/${projectNumber}`,
      });

      if (
        protectedHeader.typ !== "JWT" || typeof payload.exp !== "number" ||
        typeof payload.sub !== "string" || payload.sub.length === 0
      ) {
        throw new InvalidAppCheckError("Invalid App Check token issuer.");
      }
    } catch (error) {
      if (error instanceof InvalidAppCheckError) {
        throw error;
      }
      throw new InvalidAppCheckError(
        "App Check validation failed.",
      );
    }
  }
}

export class InvalidAppCheckError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidAppCheckError";
  }
}
