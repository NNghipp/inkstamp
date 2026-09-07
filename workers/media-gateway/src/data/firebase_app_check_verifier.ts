import { createRemoteJWKSet, jwtVerify } from "jose";

const appCheckKeys = createRemoteJWKSet(
  new URL("https://firebaseappcheck.googleapis.com/v1/jwks"),
);

export class FirebaseAppCheckVerifier {
  async verify({
    appCheckHeader,
    projectId,
  }: {
    appCheckHeader: string | null;
    projectId: string;
  }): Promise<void> {
    if (appCheckHeader === null || appCheckHeader.length === 0) {
      throw new InvalidAppCheckError("App Check token is missing.");
    }
    if (appCheckHeader.length > 4096) {
      throw new InvalidAppCheckError("App Check token is too long.");
    }

    try {
      const { payload } = await jwtVerify(appCheckHeader, appCheckKeys, {
        algorithms: ["RS256"],
        audience: [`projects/${projectId}`],
      });

      if (
        typeof payload.iss !== "string" ||
        !payload.iss.startsWith("https://firebaseappcheck.googleapis.com/")
      ) {
        throw new InvalidAppCheckError("Invalid App Check token issuer.");
      }
    } catch (error) {
      if (error instanceof InvalidAppCheckError) {
        throw error;
      }
      throw new InvalidAppCheckError(
        error instanceof Error ? error.message : "App Check validation failed.",
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
