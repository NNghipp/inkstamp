import { describe, expect, it } from "vitest";
import { CreateUploadSignature } from "../src/application/create_upload_signature";
import { createCloudinarySignature } from "../src/domain/cloudinary_signature";

describe("createCloudinarySignature", () => {
  it("creates the documented SHA-256 signature from sorted fields", async () => {
    const signature = await createCloudinarySignature({
      parameters: { timestamp: "1315060510" },
      apiSecret: "abcd",
    });

    expect(signature).toBe(
      "5652e549a70bdc03f73a633a23b7d3f3b067d72fff26dd15b25997f46fdf6439",
    );
  });
});

describe("CreateUploadSignature", () => {
  it("creates an authenticated, user-scoped Cloudinary upload", async () => {
    const result = await new CreateUploadSignature(
      {
        apiKey: "public-key",
        apiSecret: "secret",
        cloudName: "inkstamp",
        uploadPreset: "inkstamp_private_images",
      },
      () => 1_700_000_000,
      () => "media-id",
    ).execute({ userId: "user-1", mediaKind: "stamp" });

    expect(result.uploadUrl).toBe(
      "https://api.cloudinary.com/v1_1/inkstamp/image/authenticated",
    );
    expect(result.parameters).toMatchObject({
      folder: "inkstamp/user-1",
      public_id: "stamp/media-id",
      timestamp: "1700000000",
      upload_preset: "inkstamp_private_images",
    });
    expect(result.parameters.signature).toMatch(/^[a-f0-9]{64}$/);
  });
});
