import { createCloudinarySignature } from "../domain/cloudinary_signature";

export interface AssetDeleter {
  delete(input: {
    apiKey: string;
    apiSecret: string;
    cloudName: string;
    publicId: string;
  }): Promise<void>;
}

export class CloudinaryAssetDeleter implements AssetDeleter {
  async delete(input: {
    apiKey: string;
    apiSecret: string;
    cloudName: string;
    publicId: string;
  }): Promise<void> {
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const parameters = {
      invalidate: "true",
      public_id: input.publicId,
      timestamp,
      type: "authenticated",
    };
    const signature = await createCloudinarySignature({
      parameters,
      apiSecret: input.apiSecret,
    });
    const body = new URLSearchParams({
      ...parameters,
      api_key: input.apiKey,
      signature,
    });
    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${input.cloudName}/image/destroy`,
      { method: "POST", body },
    );
    if (!response.ok) throw new Error("Cloudinary asset deletion failed.");
    const result = await response.json<{ result?: string }>();
    if (result.result !== "ok" && result.result !== "not found") {
      throw new Error("Cloudinary asset deletion failed.");
    }
  }
}
