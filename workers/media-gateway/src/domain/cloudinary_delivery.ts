const encoder = new TextEncoder();
export async function createCloudinaryDeliverySignature({
  publicId,
  apiSecret,
  expiry,
}: {
  publicId: string;
  apiSecret: string;
  expiry: number;
}): Promise<string> {
  // Cloudinary private delivery signature is typically a SHA-1 hash of the path/parameters + API secret
  // For this spike, we construct a URL-safe signature using SHA-1 (base64 encoded, first 8 characters)
  const toSign = `expiry=${expiry}&public_id=${publicId}${apiSecret}`;
  const digest = await crypto.subtle.digest("SHA-1", encoder.encode(toSign));
  // Base64 encode and make URL safe
  const base64 = btoa(String.fromCharCode(...new Uint8Array(digest)));
  const urlSafe = base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  return urlSafe.substring(0, 8);
}
export async function generateDeliveryUrl({
  cloudName,
  publicId,
  apiSecret,
  expiryDurationSeconds = 3600, // 1 hour by default
}: {
  cloudName: string;
  publicId: string;
  apiSecret: string;
  expiryDurationSeconds?: number;
}): Promise<string> {
  const expiry = Math.floor(Date.now() / 1000) + expiryDurationSeconds;
  const signature = await createCloudinaryDeliverySignature({
    publicId,
    apiSecret,
    expiry,
  });
  // Example Cloudinary authenticated URL format with expiration and signature
  return `https://res.cloudinary.com/${cloudName}/image/authenticated/s--${signature}--/expiry=${expiry}/${publicId}`;
}
