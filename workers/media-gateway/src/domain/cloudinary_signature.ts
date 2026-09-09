const encoder = new TextEncoder();

export type CloudinarySignatureParameters = Readonly<Record<string, string>>;

export async function createCloudinarySignature({
  parameters,
  apiSecret,
}: {
  parameters: CloudinarySignatureParameters;
  apiSecret: string;
}): Promise<string> {
  const serialized = Object.entries(parameters)
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([name, value]) => `${name}=${value}`)
    .join("&");
  const digest = await crypto.subtle.digest(
    "SHA-256",
    encoder.encode(`${serialized}${apiSecret}`),
  );

  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}
