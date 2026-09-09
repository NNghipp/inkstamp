import {
  CreateUploadSignature,
  type CloudinaryConfiguration,
  type MediaKind,
} from "../application/create_upload_signature";
import {
  FirebaseAppCheckVerifier,
  InvalidAppCheckError,
} from "../data/firebase_app_check_verifier";
import {
  CloudinaryAssetDeleter,
  type AssetDeleter,
} from "../data/cloudinary_asset_deleter";
import {
  FirestoreRestMediaAuthorizer,
  type MediaAuthorizer,
} from "../data/firestore_media_authorizer";
import {
  FirebaseIdTokenVerifier,
  InvalidAuthenticationError,
} from "../data/firebase_id_token_verifier";
import {
  InMemoryRateLimiter,
  type RateLimiter,
  type RateLimitScope,
} from "../data/rate_limiter";
import { generateDeliveryUrl } from "../domain/cloudinary_delivery";

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

export interface AppCheckVerifier {
  verify(input: {
    appCheckHeader: string | null;
    projectId: string;
  }): Promise<void>;
}

export interface WorkerDependencies {
  readonly tokenVerifier: TokenVerifier;
  readonly appCheckVerifier: AppCheckVerifier;
  readonly rateLimiter: RateLimiter;
  readonly mediaAuthorizer: MediaAuthorizer;
  readonly assetDeleter: AssetDeleter;
}

export function createWorker(
  dependencies: WorkerDependencies,
): ExportedHandler<MediaGatewayEnvironment> {
  return {
    async fetch(request, environment): Promise<Response> {
      return handleRequest(request, environment, dependencies);
    },
  };
}

export async function handleRequest(
  request: Request,
  environment: MediaGatewayEnvironment,
  dependencies: WorkerDependencies,
): Promise<Response> {
  const url = new URL(request.url);
  if (request.method === "GET" && url.pathname === "/health") {
    try {
      validateEnvironment(environment);
      return json({ status: "ok", service: "inkstamp-media-gateway" }, 200);
    } catch (error) {
      return json({
        status: "error",
        error: error instanceof Error ? error.message : "Invalid configuration.",
      }, 503);
    }
  }

  const isUpload =
    request.method === "POST" && url.pathname === "/v1/media/upload-signatures";
  const isDelivery =
    request.method === "POST" && url.pathname === "/v1/media/delivery-urls";
  const isDelete =
    request.method === "POST" && url.pathname === "/v1/media/delete";
  if (!isUpload && !isDelivery && !isDelete) {
    return json({ error: "Not found." }, 404);
  }

  try {
    validateEnvironment(environment);
    if (environment.APP_CHECK_ENFORCED === "true") {
      await dependencies.appCheckVerifier.verify({
        appCheckHeader: request.headers.get("X-Firebase-App-Check"),
        projectId: environment.FIREBASE_PROJECT_ID,
      });
    }

    const authorizationHeader = request.headers.get("Authorization");
    const userId = await dependencies.tokenVerifier.verify({
      authorizationHeader,
      projectId: environment.FIREBASE_PROJECT_ID,
    });
    const idToken = authorizationHeader?.match(/^Bearer\s+([^\s]+)$/i)?.[1];
    if (idToken === undefined) throw new InvalidAuthenticationError();

    const scope: RateLimitScope = isDelivery ? "delivery" : "upload";
    if (environment.RATE_LIMIT_ENFORCED === "true") {
      const decision = await dependencies.rateLimiter.checkLimit({
        ip: request.headers.get("CF-Connecting-IP") ?? "127.0.0.1",
        userId,
        scope,
      });
      if (!decision.allowed) {
        return json(
          { error: "Too many requests. Please try again later." },
          429,
          { "Retry-After": decision.retryAfterSeconds.toString() },
        );
      }
    }

    if (isUpload) {
      const mediaKind = await parseMediaKind(request);
      const signature = await new CreateUploadSignature(
        cloudinaryConfiguration(environment),
        () => Math.floor(Date.now() / 1000),
        () => crypto.randomUUID(),
      ).execute({ userId, mediaKind });
      return json(signature, 200);
    }

    if (isDelete) {
      const publicId = await parsePublicId(request);
      if (!publicId.startsWith(`inkstamp/${userId}/`)) {
        return json({ error: "Media access is forbidden." }, 403);
      }
      await dependencies.assetDeleter.delete({
        apiKey: environment.CLOUDINARY_API_KEY,
        apiSecret: environment.CLOUDINARY_API_SECRET,
        cloudName: environment.CLOUDINARY_CLOUD_NAME,
        publicId,
      });
      return json({ deleted: true }, 200);
    }

    const publicIds = await parsePublicIds(request);
    const authorized = await dependencies.mediaAuthorizer.canRead({
      idToken,
      projectId: environment.FIREBASE_PROJECT_ID,
      publicIds,
      userId,
    });
    if (!authorized) return json({ error: "Media access is forbidden." }, 403);

    const deliveryUrls: Record<string, string> = {};
    for (const publicId of publicIds) {
      deliveryUrls[publicId] = await generateDeliveryUrl({
        cloudName: environment.CLOUDINARY_CLOUD_NAME,
        publicId,
        apiKey: environment.CLOUDINARY_API_KEY,
        apiSecret: environment.CLOUDINARY_API_SECRET,
      });
    }
    return json({ deliveryUrls }, 200);
  } catch (error) {
    if (error instanceof InvalidAuthenticationError) {
      return json({ error: "Authentication is required." }, 401);
    }
    if (error instanceof InvalidAppCheckError) {
      return json({ error: error.message }, 403);
    }
    if (error instanceof InvalidRequestError || error instanceof InvalidConfigurationError) {
      return json({ error: error.message }, error instanceof InvalidConfigurationError ? 503 : 400);
    }
    console.error(JSON.stringify({
      message: "media gateway request failed",
      path: url.pathname,
      error: error instanceof Error ? error.name : "UnknownError",
    }));
    return json({ error: "Unable to process the request." }, 500);
  }
}

export default createWorker({
  tokenVerifier: new FirebaseIdTokenVerifier(),
  appCheckVerifier: new FirebaseAppCheckVerifier(),
  rateLimiter: new InMemoryRateLimiter(),
  mediaAuthorizer: new FirestoreRestMediaAuthorizer(),
  assetDeleter: new CloudinaryAssetDeleter(),
});

function validateEnvironment(environment: MediaGatewayEnvironment): void {
  const names: ReadonlyArray<keyof CloudinarySecrets | "FIREBASE_PROJECT_ID"> = [
    "FIREBASE_PROJECT_ID",
    "CLOUDINARY_CLOUD_NAME",
    "CLOUDINARY_API_KEY",
    "CLOUDINARY_API_SECRET",
    "CLOUDINARY_UPLOAD_PRESET",
  ];
  for (const name of names) {
    const value = environment[name];
    if (typeof value !== "string" || value.trim().length === 0) {
      throw new InvalidConfigurationError(`Missing required configuration: ${name}.`);
    }
  }
}

function cloudinaryConfiguration(environment: CloudinarySecrets): CloudinaryConfiguration {
  return {
    apiKey: environment.CLOUDINARY_API_KEY,
    apiSecret: environment.CLOUDINARY_API_SECRET,
    cloudName: environment.CLOUDINARY_CLOUD_NAME,
    uploadPreset: environment.CLOUDINARY_UPLOAD_PRESET,
  };
}

async function parseMediaKind(request: Request): Promise<MediaKind> {
  const body = await readJsonRequest(request, 1024);
  if (typeof body !== "object" || body === null || !("mediaKind" in body) ||
      (body.mediaKind !== "stamp" && body.mediaKind !== "thumbnail")) {
    throw new InvalidRequestError("mediaKind must be stamp or thumbnail.");
  }
  return body.mediaKind;
}

async function parsePublicIds(request: Request): Promise<string[]> {
  const body = await readJsonRequest(request, 4096);
  if (typeof body !== "object" || body === null || !("publicIds" in body) ||
      !Array.isArray(body.publicIds) || body.publicIds.length === 0 ||
      body.publicIds.length > 50) {
    throw new InvalidRequestError("publicIds must contain between 1 and 50 strings.");
  }
  const publicIds: string[] = [];
  for (const value of body.publicIds) {
    if (typeof value !== "string" || !/^inkstamp\/[A-Za-z0-9_-]+\/(stamp|thumbnail)\/[A-Za-z0-9_-]+$/.test(value)) {
      throw new InvalidRequestError("Invalid publicId format.");
    }
    publicIds.push(value);
  }
  return publicIds;
}

async function parsePublicId(request: Request): Promise<string> {
  const body = await readJsonRequest(request, 1024);
  if (typeof body !== "object" || body === null || !("publicId" in body) ||
      typeof body.publicId !== "string" || !isValidPublicId(body.publicId)) {
    throw new InvalidRequestError("Invalid publicId format.");
  }
  return body.publicId;
}

function isValidPublicId(value: string): boolean {
  return /^inkstamp\/[A-Za-z0-9_-]+\/(stamp|thumbnail)\/[A-Za-z0-9_-]+$/.test(value);
}

async function readJsonRequest(request: Request, maximumBytes: number): Promise<unknown> {
  const contentType = request.headers.get("Content-Type");
  if (contentType?.split(";", 1)[0]?.trim() !== "application/json") {
    throw new InvalidRequestError("Content-Type must be application/json.");
  }
  if (request.body === null) throw new InvalidRequestError("Request body must be valid JSON.");

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let byteLength = 0;
  while (true) {
    const result = await reader.read();
    if (result.done) break;
    byteLength += result.value.byteLength;
    if (byteLength > maximumBytes) {
      await reader.cancel();
      throw new InvalidRequestError("Request body is too large.");
    }
    chunks.push(result.value);
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

function json(value: unknown, status: number, headers: HeadersInit = {}): Response {
  return Response.json(value, {
    status,
    headers: { "Cache-Control": "no-store", ...headers },
  });
}

class InvalidRequestError extends Error {}
class InvalidConfigurationError extends Error {}
