import {
  CreateUploadSignature,
  type CloudinaryConfiguration,
  type MediaKind,
} from "../application/create_upload_signature";
import {
  FirebaseIdTokenVerifier,
  InvalidAuthenticationError,
} from "../data/firebase_id_token_verifier";
import {
  FirebaseAppCheckVerifier,
  InvalidAppCheckError,
} from "../data/firebase_app_check_verifier";
import {
  InMemoryRateLimiter,
} from "../data/rate_limiter";
import {
  generateDeliveryUrl,
} from "../domain/cloudinary_delivery";

export interface CloudinarySecrets {
  readonly CLOUDINARY_API_KEY: string;
  readonly CLOUDINARY_API_SECRET: string;
  readonly CLOUDINARY_CLOUD_NAME: string;
  readonly CLOUDINARY_UPLOAD_PRESET: string;
}

export type MediaGatewayEnvironment = Env & CloudinarySecrets & {
  readonly APP_CHECK_ENFORCED?: string;
  readonly RATE_LIMIT_ENFORCED?: string;
};

export interface TokenVerifier {
  verify(input: {
    authorizationHeader: string | null;
    projectId: string;
  }): Promise<string>;
}

const appCheckVerifier = new FirebaseAppCheckVerifier();
const rateLimiter = new InMemoryRateLimiter();

export function createWorker(
  tokenVerifier: TokenVerifier,
): ExportedHandler<MediaGatewayEnvironment> {
  return {
    async fetch(
      request: Request,
      environment: MediaGatewayEnvironment,
    ): Promise<Response> {
      return handleRequest(request, environment, tokenVerifier);
    },
  };
}

export async function handleRequest(
  request: Request,
  environment: MediaGatewayEnvironment,
  tokenVerifier: TokenVerifier,
): Promise<Response> {
  const url = new URL(request.url);
  if (request.method === "GET" && url.pathname === "/health") {
    return json({ status: "ok", service: "inkstamp-media-gateway" }, 200);
  }

  const isUploadSignature =
    request.method === "POST" && url.pathname === "/v1/media/upload-signatures";
  const isDeliveryUrls =
    request.method === "POST" && url.pathname === "/v1/media/delivery-urls";

  if (!isUploadSignature && !isDeliveryUrls) {
    return json({ error: "Not found." }, 404);
  }

  try {
    // 1. App Check Verification (if enabled)
    if (environment.APP_CHECK_ENFORCED === "true") {
      try {
        await appCheckVerifier.verify({
          appCheckHeader: request.headers.get("X-Firebase-App-Check"),
          projectId: environment.FIREBASE_PROJECT_ID,
        });
      } catch (error) {
        if (error instanceof InvalidAppCheckError) {
          return json({ error: error.message }, 403);
        }
        throw error;
      }
    }

    // 2. Auth token Verification
    const userId = await tokenVerifier.verify({
      authorizationHeader: request.headers.get("Authorization"),
      projectId: environment.FIREBASE_PROJECT_ID,
    });

    // 3. Rate Limiting (if enabled)
    if (environment.RATE_LIMIT_ENFORCED === "true") {
      const ip = request.headers.get("CF-Connecting-IP") || "127.0.0.1";
      const allowed = await rateLimiter.checkLimit({ ip, userId });
      if (!allowed) {
        return json({ error: "Too many requests. Please try again later." }, 429);
      }
    }

    // 4. Handle endpoints
    if (isUploadSignature) {
      const mediaKind = await parseMediaKind(request);
      const signature = await new CreateUploadSignature(
        cloudinaryConfiguration(environment),
        () => Math.floor(Date.now() / 1000),
        () => crypto.randomUUID(),
      ).execute({ userId, mediaKind });

      return json(signature, 200);
    } else {
      // isDeliveryUrls
      const body = await readBoundedJson(request, 2048);
      if (
        typeof body !== "object" ||
        body === null ||
        !("publicIds" in body) ||
        !Array.isArray(body.publicIds)
      ) {
        throw new InvalidRequestError("publicIds must be an array of strings.");
      }

      const publicIds = body.publicIds as string[];
      if (publicIds.length > 50) {
        throw new InvalidRequestError("Cannot sign more than 50 public IDs at once.");
      }

      const deliveryUrls: Record<string, string> = {};
      const cloudName = environment.CLOUDINARY_CLOUD_NAME;
      const apiSecret = environment.CLOUDINARY_API_SECRET;

      for (const publicId of publicIds) {
        if (typeof publicId !== "string" || publicId.trim().length === 0) {
          throw new InvalidRequestError("Invalid publicId format.");
        }
        if (!publicId.startsWith("inkstamp/")) {
          throw new InvalidRequestError("Forbidden publicId namespace.");
        }

        deliveryUrls[publicId] = await generateDeliveryUrl({
          cloudName,
          publicId,
          apiSecret,
        });
      }

      return json({ deliveryUrls }, 200);
    }
  } catch (error) {
    if (error instanceof InvalidAuthenticationError) {
      return json({ error: "Authentication is required." }, 401);
    }
    if (error instanceof InvalidRequestError) {
      return json({ error: error.message }, 400);
    }
    console.error(
      JSON.stringify({
        message: "media signature request failed",
        path: url.pathname,
        error: error instanceof Error ? error.message : "Unknown error",
      }),
    );
    return json({ error: "Unable to process the request." }, 500);
  }
}

export default createWorker(new FirebaseIdTokenVerifier());

function cloudinaryConfiguration(environment: CloudinarySecrets): CloudinaryConfiguration {
  return {
    apiKey: environment.CLOUDINARY_API_KEY,
    apiSecret: environment.CLOUDINARY_API_SECRET,
    cloudName: environment.CLOUDINARY_CLOUD_NAME,
    uploadPreset: environment.CLOUDINARY_UPLOAD_PRESET,
  };
}

async function parseMediaKind(request: Request): Promise<MediaKind> {
  const contentType = request.headers.get("Content-Type");
  if (contentType?.split(";", 1)[0]?.trim() !== "application/json") {
    throw new InvalidRequestError("Content-Type must be application/json.");
  }

  const body = await readBoundedJson(request, 1024);
  if (
    typeof body !== "object" ||
    body === null ||
    !("mediaKind" in body) ||
    (body.mediaKind !== "stamp" && body.mediaKind !== "thumbnail")
  ) {
    throw new InvalidRequestError(
      "mediaKind must be stamp or thumbnail.",
    );
  }
  return body.mediaKind;
}

async function readBoundedJson(
  request: Request,
  maximumBytes: number,
): Promise<unknown> {
  if (request.body === null) {
    throw new InvalidRequestError("Request body must be valid JSON.");
  }

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let byteLength = 0;

  try {
    while (true) {
      const result = await reader.read();
      if (result.done) {
        break;
      }
      byteLength += result.value.byteLength;
      if (byteLength > maximumBytes) {
        await reader.cancel();
        throw new InvalidRequestError("Request body is too large.");
      }
      chunks.push(result.value);
    }
  } catch (error) {
    if (error instanceof InvalidRequestError) {
      throw error;
    }
    throw new InvalidRequestError("Request body must be valid JSON.");
  }

  const bytes = new Uint8Array(byteLength);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }

  try {
    return JSON.parse(new TextDecoder().decode(bytes)) as unknown;
  } catch {
    throw new InvalidRequestError("Request body must be valid JSON.");
  }
}

function json(value: unknown, status: number): Response {
  return Response.json(value, {
    status,
    headers: { "Cache-Control": "no-store" },
  });
}

class InvalidRequestError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "InvalidRequestError";
  }
}
