import { createCloudinarySignature } from "./cloudinary_signature";

export async function generateDeliveryUrl({
  cloudName,
  publicId,
  apiKey,
  apiSecret,
  now = () => Math.floor(Date.now() / 1000),
  expiryDurationSeconds = 300,
}: {
  cloudName: string;
  publicId: string;
  apiKey: string;
  apiSecret: string;
  now?: () => number;
  expiryDurationSeconds?: number;
}): Promise<string> {
  const timestamp = now();
  const parameters = {
    attachment: "false",
    expires_at: (timestamp + expiryDurationSeconds).toString(),
    public_id: publicId,
    timestamp: timestamp.toString(),
    type: "authenticated",
  };
  const signature = await createCloudinarySignature({
    parameters,
    apiSecret,
  });
  const query = new URLSearchParams({
    ...parameters,
    api_key: apiKey,
    signature,
  });
  return `https://api.cloudinary.com/v1_1/${cloudName}/image/download?${query}`;
}
