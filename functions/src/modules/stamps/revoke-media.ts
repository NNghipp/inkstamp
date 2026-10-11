import type { CallableRequest } from "firebase-functions/v2/https";
import { localDevBackend } from "../../config/callable-security.js";

/** Reuse the existing owner-authenticated gateway, not duplicate Cloudinary secrets. */
export async function revokeMedia(
  request: CallableRequest<unknown>, publicIds: string[],
): Promise<boolean> {
  const base = process.env.MEDIA_GATEWAY_BASE_URL;
  if (!base || publicIds.length !== 2) return false;
  const authorization = request.rawRequest.header("Authorization");
  if (!authorization) return false;
  try {
    const url = new URL(base);
    if (url.protocol !== "https:" &&
        !(localDevBackend && url.origin === "http://127.0.0.1:8787")) return false;
    const results = await Promise.all(publicIds.map(async (publicId) => {
      const response = await fetch(new URL("/v1/media/delete", url), {
        method: "POST", signal: AbortSignal.timeout(15000),
        headers: { Authorization: authorization, "Content-Type": "application/json",
          ...(request.rawRequest.header("X-Firebase-AppCheck") ?
            { "X-Firebase-App-Check": request.rawRequest.header("X-Firebase-AppCheck")! } : {}) },
        body: JSON.stringify({ publicId }),
      });
      return response.ok;
    }));
    return results.every(Boolean);
  } catch {
    // Retained media IDs permit retrying cleanup on repeated revoke.
    return false;
  }
}
