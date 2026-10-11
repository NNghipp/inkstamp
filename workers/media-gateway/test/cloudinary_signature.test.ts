import { describe, expect, it } from "vitest";
import { CreateUploadSignature } from "../src/application/create_upload_signature";
import { createCloudinarySignature } from "../src/domain/cloudinary_signature";
import { generateDeliveryUrl } from "../src/domain/cloudinary_delivery";

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

describe("generateDeliveryUrl", () => {
  it("preserves PNG alpha for versioned stamps without changing legacy URLs", async () => {
    const input = { cloudName: "inkstamp", apiKey: "key", apiSecret: "secret" };
    const png = new URL(await generateDeliveryUrl({ ...input,
      publicId: "inkstamp/user-1/stamp/id_stamp_v1" }));
    const old = new URL(await generateDeliveryUrl({ ...input,
      publicId: "inkstamp/user-1/stamp/id" }));
    expect(png.searchParams.get("format")).toBe("png");
    expect(old.searchParams.has("format")).toBe(false);
  });
  it("creates a short-lived authenticated download URL", async () => {
    const value = await generateDeliveryUrl({
      cloudName: "inkstamp",
      publicId: "inkstamp/user-1/stamp/id-1",
      apiKey: "public-key",
      apiSecret: "secret",
      now: () => 1_700_000_000,
    });
    const url = new URL(value);
    expect(url.pathname).toBe("/v1_1/inkstamp/image/download");
    expect(url.searchParams.get("public_id")).toBe(
      "inkstamp/user-1/stamp/id-1",
    );
    expect(url.searchParams.get("type")).toBe("authenticated");
    expect(url.searchParams.get("expires_at")).toBe("1700000300");
    expect(url.searchParams.get("signature")).toMatch(/^[a-f0-9]{64}$/);
  });
});

describe("CreateUploadSignature", () => {
  it("signs PNG and a versioned ID for both stamp and thumbnail", async () => {
    for (const mediaKind of ["stamp", "thumbnail"] as const) {
      const result = await new CreateUploadSignature({ apiKey: "key",
        apiSecret: "secret", cloudName: "inkstamp", uploadPreset: "preset" },
        () => 1, () => "id").execute({ userId: "user", mediaKind,
          imageFormat: "stamp_png_v1" });
      expect(result.parameters.format).toBe("png");
      expect(result.parameters.public_id).toBe(`${mediaKind}/id_stamp_v1`);
      const { signature, ...parameters } = result.parameters;
      expect(signature).toBe(await createCloudinarySignature({ parameters, apiSecret: "secret" }));
    }
  });
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
      "https://api.cloudinary.com/v1_1/inkstamp/image/upload",
    );
    expect(result.parameters).toMatchObject({
      folder: "inkstamp/user-1",
      public_id: "stamp/media-id",
      timestamp: "1700000000",
      upload_preset: "inkstamp_private_images",
      type: "authenticated",
    });
    expect(result.parameters.signature).toMatch(/^[a-f0-9]{64}$/);
  });
});
