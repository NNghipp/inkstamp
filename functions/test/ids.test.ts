import { describe, expect, it } from "vitest";
import {
  friendshipId,
  normalizeUsername,
  utcDayKey,
} from "../src/shared/firestore/ids.js";

describe("friendshipId", () => {
  it("is stable regardless of member order", () => {
    expect(friendshipId("user-b", "user-a")).toBe("user-a__user-b");
    expect(friendshipId("user-a", "user-b")).toBe("user-a__user-b");
  });
});

describe("normalizeUsername", () => {
  it("normalizes case and whitespace", () => {
    expect(normalizeUsername("  Mai.Paper  ")).toBe("mai.paper");
  });

  it("preserves the username characters accepted by validation", () => {
    expect(normalizeUsername("  NEW_user.26 ")).toBe("new_user.26");
  });
});

describe("utcDayKey", () => {
  it("returns a UTC date key", () => {
    expect(utcDayKey(new Date("2026-08-23T23:45:00.000Z"))).toBe(
      "2026-08-23",
    );
  });
});
