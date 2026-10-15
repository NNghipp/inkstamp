import { describe, expect, it } from "vitest";
import {
  publishStampSchema,
  reserveUsernameSchema,
} from "../src/shared/validation/schemas.js";

describe("reserveUsernameSchema", () => {
  it("normalizes valid usernames", () => {
    const result = reserveUsernameSchema.parse({
      username: "  Minh.Stamps ",
      displayName: "Minh Anh",
    });
    expect(result.username).toBe("minh.stamps");
  });

  it("rejects invalid usernames", () => {
    expect(() =>
      reserveUsernameSchema.parse({
        username: "Minh Anh!",
        displayName: "Minh Anh",
      }),
    ).toThrow();
  });
});

describe("publishStampSchema", () => {
  const validPayload = {
    requestId: "a0f6bd84-a83b-4e1f-9aac-2e6b8f53ff00",
    cloudinaryPublicId: "inkstamp/sender-1/stamp/uuid-1",
    cloudinaryThumbnailPublicId: "inkstamp/sender-1/thumbnail/uuid-1",
    audience: "allFriends",
    selectedRecipientIds: [],
    frameStyle: "classic",
    paperTone: "cream",
    captureLocalDate: "2026-08-23",
    timezoneOffsetMinutes: 420,
  };

  it("accepts a valid all-friends publish request", () => {
    expect(publishStampSchema.parse(validPayload)).toMatchObject(validPayload);
  });

  it("requires recipients for selected audience", () => {
    expect(() =>
      publishStampSchema.parse({
        ...validPayload,
        audience: "selected",
      }),
    ).toThrow();
  });

  it("validates optional metadata and ignores client publish-time fields", () => {
    const metadata = { capturedAt: "2026-10-15T09:05:00+07:00", title: "Cổng đỏ Kyoto", locationLabel: "Kyoto" };
    expect(publishStampSchema.parse({ ...validPayload, ...metadata })).toMatchObject(metadata);
    expect(() => publishStampSchema.parse({ ...validPayload, capturedAt: "yesterday" })).toThrow();
    expect(() => publishStampSchema.parse({ ...validPayload, title: "x".repeat(81) })).toThrow();
    expect(() => publishStampSchema.parse({ ...validPayload, locationLabel: " " })).toThrow();
    const parsed = publishStampSchema.parse({ ...validPayload, createdAt: "fake", publishedAt: "fake" });
    expect(parsed).not.toHaveProperty("createdAt");
    expect(parsed).not.toHaveProperty("publishedAt");
  });

  it("allows a reply without selected recipients", () => {
    expect(
      publishStampSchema.parse({
        ...validPayload,
        audience: "selected",
        replyToStampId: "stamp-1",
      }),
    ).toBeDefined();
  });
});
