import { z } from "zod";

export const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .regex(/^[a-z0-9._]{3,20}$/);

export const reserveUsernameSchema = z.object({
  username: usernameSchema,
  displayName: z.string().trim().min(1).max(30),
});

export const usernameLookupSchema = z.object({
  username: usernameSchema,
});

export const userIdSchema = z.object({
  userId: z.string().trim().min(1).max(128),
});

export const friendResponseSchema = z.object({
  userId: z.string().trim().min(1).max(128),
  accept: z.boolean(),
});

export const closeFriendSchema = z.object({
  friendId: z.string().trim().min(1).max(128),
  enabled: z.boolean(),
});

export const audienceModeSchema = z.enum([
  "allFriends",
  "closeFriends",
  "selected",
]);

export const frameStyleSchema = z.enum(["classic", "soft", "mini", "bold"]);
export const paperToneSchema = z.enum([
  "cream",
  "sky",
  "blush",
  "mint",
  "lilac",
  "butter",
]);

export const publishStampSchema = z
  .object({
    requestId: z.uuid(),
    draftId: z.string().trim().min(1).max(128),
    audience: audienceModeSchema,
    selectedRecipientIds: z
      .array(z.string().trim().min(1).max(128))
      .max(50)
      .default([]),
    replyToStampId: z.string().trim().min(1).max(128).optional(),
    frameStyle: frameStyleSchema,
    paperTone: paperToneSchema,
    captureLocalDate: z.iso.date(),
    timezoneOffsetMinutes: z.number().int().min(-840).max(840),
  })
  .superRefine((value, context) => {
    if (
      value.audience === "selected" &&
      value.replyToStampId === undefined &&
      value.selectedRecipientIds.length === 0
    ) {
      context.addIssue({
        code: "custom",
        path: ["selectedRecipientIds"],
        message: "Select at least one recipient.",
      });
    }
  });

export const reactToStampSchema = z.object({
  stampId: z.string().trim().min(1).max(128),
  reaction: z.enum(["heart", "laugh", "wow", "emotional", "fire", "cry"]),
});

export const stampIdSchema = z.object({
  stampId: z.string().trim().min(1).max(128),
});

export const reportContentSchema = z.object({
  stampId: z.string().trim().min(1).max(128),
  reason: z.enum([
    "inappropriate",
    "harassment",
    "sensitive",
    "spam",
    "other",
  ]),
  details: z.string().trim().max(500).optional(),
});
