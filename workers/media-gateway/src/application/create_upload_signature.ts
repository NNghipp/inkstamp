import {
  createCloudinarySignature,
  type CloudinarySignatureParameters,
} from "../domain/cloudinary_signature";

export type MediaKind = "stamp" | "thumbnail";

export interface CloudinaryConfiguration {
  readonly apiKey: string;
  readonly apiSecret: string;
  readonly cloudName: string;
  readonly uploadPreset: string;
}

export interface UploadSignature {
  readonly apiKey: string;
  readonly cloudName: string;
  readonly parameters: CloudinarySignatureParameters & {
    readonly signature: string;
  };
  readonly uploadUrl: string;
}

export class CreateUploadSignature {
  constructor(
    private readonly configuration: CloudinaryConfiguration,
    private readonly now: () => number,
    private readonly newId: () => string,
  ) {}

  async execute({
    userId,
    mediaKind,
    imageFormat,
  }: {
    userId: string;
    mediaKind: MediaKind;
    imageFormat?: "stamp_png_v1";
  }): Promise<UploadSignature> {
    const timestamp = this.now();
    const parameters: CloudinarySignatureParameters = {
      folder: `inkstamp/${userId}`,
      public_id: `${mediaKind}/${this.newId()}${imageFormat ? "_stamp_v1" : ""}`,
      ...(imageFormat ? { format: "png" } : {}),
      timestamp: timestamp.toString(),
      upload_preset: this.configuration.uploadPreset,
      type: "authenticated",
    };

    const signature = await createCloudinarySignature({
      parameters: parameters,
      apiSecret: this.configuration.apiSecret,
    });

    return {
      apiKey: this.configuration.apiKey,
      cloudName: this.configuration.cloudName,
      parameters: { ...parameters, signature },
      uploadUrl:
        `https://api.cloudinary.com/v1_1/${this.configuration.cloudName}` +
        "/image/upload",
    };
  }
}
